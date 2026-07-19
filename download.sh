#!/usr/bin/env bash
#
# Brno Urban Dataset downloader
# ------------------------------
# Downloads recordings of the Brno Urban Dataset from the CESNET S3 storage.
# Each recording is a single .zip archive named after its recording id
# (e.g. 1_1_1_1.zip). See recordings_table.md for the full list of recordings
# and their tags.
#
# Usage:
#   ./download.sh [options] [ID ...]
#
# Examples:
#   ./download.sh                    # download the whole dataset
#   ./download.sh 1_1_1_1 2_2_4_1    # download only these two recordings
#   ./download.sh -s 3               # download all of session 3
#   ./download.sh -o /data/bud       # download everything into /data/bud
#   ./download.sh -l                 # just list the available recordings
#
# Options:
#   -o DIR   output directory (default: ./download)
#   -s N     restrict to a session (1, 2 or 3); repeatable
#   -l       list available recordings and exit
#   -n       dry run: print the URLs that would be downloaded, then exit
#   -y       assume "yes": skip the confirmation prompt (for scripts/CI)
#   -h       show this help
#
# Downloads resume automatically if interrupted (re-run the same command).
# The full dataset is roughly 3.6 TB - make sure you have enough free space
# before downloading everything.

set -euo pipefail

BASE_URL="https://s3.cl4.du.cesnet.cz/75d8ed98494bf3405dfc176c904123fa2c7dd102:bud"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SCRIPT_DIR/data/recordings.txt"

OUT_DIR="./download"
SESSIONS=()
DO_LIST=0
DRY_RUN=0
ASSUME_YES=0

usage() { sed -n '2,41p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while getopts ":o:s:lnyh" opt; do
  case "$opt" in
    o) OUT_DIR="$OPTARG" ;;
    s) SESSIONS+=("$OPTARG") ;;
    l) DO_LIST=1 ;;
    n) DRY_RUN=1 ;;
    y) ASSUME_YES=1 ;;
    h) usage; exit 0 ;;
    :) echo "Error: -$OPTARG requires an argument" >&2; exit 2 ;;
    \?) echo "Error: unknown option -$OPTARG" >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

if [[ ! -f "$MANIFEST" ]]; then
  echo "Error: recording manifest not found at $MANIFEST" >&2
  exit 1
fi

# Build the list of recordings to download.
ids=()
full_set=0
if [[ $# -gt 0 ]]; then
  ids=("$@")
else
  [[ ${#SESSIONS[@]} -eq 0 ]] && full_set=1
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    ids+=("$line")
  done < "$MANIFEST"
fi

# Optional session filter.
if [[ ${#SESSIONS[@]} -gt 0 ]]; then
  filtered=()
  for id in "${ids[@]}"; do
    for s in "${SESSIONS[@]}"; do
      [[ "$id" == "${s}_"* ]] && { filtered+=("$id"); break; }
    done
  done
  ids=("${filtered[@]}")
fi

if [[ ${#ids[@]} -eq 0 ]]; then
  echo "No recordings selected." >&2
  exit 1
fi

if [[ $DO_LIST -eq 1 ]]; then
  printf '%s\n' "${ids[@]}"
  echo "(${#ids[@]} recordings)" >&2
  exit 0
fi

if [[ $DRY_RUN -eq 1 ]]; then
  for id in "${ids[@]}"; do echo "$BASE_URL/$id.zip"; done
  exit 0
fi

# Confirm before pulling the entire ~3.6 TB dataset.
if [[ $full_set -eq 1 && $ASSUME_YES -eq 0 ]]; then
  echo "You are about to download the WHOLE dataset (${#ids[@]} recordings, ~3.6 TB)."
  read -r -p "Continue? [y/N] " reply
  case "$reply" in
    y|Y|yes|YES) ;;
    *) echo "Aborted. Pass recording ids or -s N to download a subset, or -y to skip this prompt."; exit 0 ;;
  esac
fi

# Pick a downloader, plus a matching "remote size" probe used to detect
# already-complete downloads.
if command -v curl >/dev/null 2>&1; then
  DL() { curl -fL --retry 3 --retry-delay 5 -C - -o "$2" "$1"; }
  remote_size() {
    curl -fsIL "$1" \
      | awk 'BEGIN{IGNORECASE=1} /^content-length:/{v=$2} END{gsub(/\r/,"",v); print v}'
  }
elif command -v wget >/dev/null 2>&1; then
  DL() { wget -c -O "$2" "$1"; }
  remote_size() {
    wget --spider -S "$1" 2>&1 \
      | awk 'BEGIN{IGNORECASE=1} /content-length:/{v=$2} END{gsub(/\r/,"",v); print v}'
  }
else
  echo "Error: neither curl nor wget is installed." >&2
  exit 1
fi

# Local file size in bytes (portable; empty if the file is missing).
local_size() { [[ -f "$1" ]] && wc -c < "$1" | tr -d ' '; }

mkdir -p "$OUT_DIR"
echo "Downloading ${#ids[@]} recording(s) into $OUT_DIR"

failed=()
skipped=0
i=0
for id in "${ids[@]}"; do
  i=$((i + 1))
  url="$BASE_URL/$id.zip"
  dest="$OUT_DIR/$id.zip"
  echo "[$i/${#ids[@]}] $id.zip"

  # Skip parts that are already fully downloaded: compare the local file size
  # to the server's Content-Length. A partial file (sizes differ) falls through
  # to DL, which resumes it.
  lsize="$(local_size "$dest")" || true
  if [[ -n "$lsize" ]]; then
    rsize="$(remote_size "$url")" || true
    if [[ -n "$rsize" && "$lsize" == "$rsize" ]]; then
      echo "  already complete ($lsize bytes) - skipping"
      skipped=$((skipped + 1))
      continue
    elif [[ -n "$rsize" ]]; then
      echo "  partial ($lsize/$rsize bytes) - resuming"
    fi
  fi

  if DL "$url" "$dest"; then
    :
  else
    echo "  ! failed: $url" >&2
    failed+=("$id")
  fi
done

[[ $skipped -gt 0 ]] && echo "Skipped $skipped already-complete recording(s)."

if [[ ${#failed[@]} -gt 0 ]]; then
  echo "Done with ${#failed[@]} failure(s): ${failed[*]}" >&2
  echo "Re-run the same command to resume/retry." >&2
  exit 1
fi

echo "All downloads finished successfully."
