# Brno Urban Dataset

Navigation and localisation dataset for self driving cars and autonomous robots

Autonomous driving is a dynamically growing field of research, where quality and amount of experimental data is critical. Although several rich datasets are available these days, the demands of researchers and technical possibilities are evolving. Through this paper, we bring a new dataset recorded in Brno - Czech Republic. It offers data from four Full HD cameras, two 3D LiDARs, inertial measurement unit, infrared camera and especially differential RTK GNSS receiver with centimetre accuracy which, to the best knowledge of the authors, is not available from any other public dataset so far. In addition, all the data are precisely timestamped with sub-millisecond precision to allow wider range of applications. At the time of publishing of this paper, recordings of more than X~km of rides in varying environment

[Adam Ligocki](https://www.vutbr.cz/en/people/adam-ligocki-154791#navigace-vizitka) · [Aleš Jelínek](https://www.ceitec.cz/ing-ales-jelinek-ph-d/u91705) · [Luděk Žalud](https://scholar.google.com/citations?user=kWXqPAIAAAAJ&hl=en&oi=ao)

## Example Visualization

Comming soon ... 

## Data Description

Comming soon ... 

```
<session_day_rec_part>/
└───camera_<name>/
│     video.mp4
│     timestamps.txt
│     (frameXXXXXX.jpeg)
└───lidar_<name>/
│     scans.zip
│     timestamps.txt
│     (scanXXXXXX.pcd)
└───imu/
│     imu.csv
│     mag.csv
│     gnss.csv
│     d_quat.csv
│     pressure.csv
│     time.csv
│     temp.csv
└───gnss/
│     pose.csv
│     time.csv
└───calibrations/
│     frames.yaml
│     camera_<name>.yaml
└───tags.yaml
```
  
Lorem Ipsum

|ID|Environment|Wather|Daytime|Distance [km]|
|:---------:|:---------:|:---------:|:---------:|:---------:|
|1_1_1_x  | City  | Sunny  | Noon  | 1 |
|1_1_2_x  | Suburb  | Partial-sunny  | Morning  | 2.7 |

## Data Download

To get the data on your computer please clone the repository and use any torrent client app to open the .torrent file that you are interested in. After loading the .torrent file check the data folders that you are interested in and start the content downloading.

For better search through the data please use the tag_<domain> folders in the root directory.
  
## Known Bugs

  - some IR frames in recording session no. 1 are misordered

## Attribution

If you have used our data, please cite our original paper

Comming soon ... 


