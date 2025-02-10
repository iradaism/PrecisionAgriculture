Creation of cite specific fertilizer prescription maps using spatial and
Remote Sensing methods
================
Irada Ismayilova

*In this tutorial you will explore two different ways of providing
solutions for precision agriculture: on one hand combining spatial
interpolation and soil sampling data, on the other hand utilizing remote
sensing technique.*

## Data

For this task you are given the following data sets:

- Soil sampling data in csv format
- Sampling area boundary
- Sentinel-2 data (from the previous exercise)

You can download sampling data and boundary from here:
<https://mediastore.rz.uni-augsburg.de/get/wS0CQdIwxC/>

## Getting started

Import required libraries. Install the ones that you haven’t installed
before.

``` r
library("sp")
library("raster")
library("gstat")
```

Set the working directory and import the given data. Sentinel-2 bands
you have already preprocesed in the previous exercise.

``` r
setwd("C:/GIS_for_env_applications/PrecisionAgriculture")

AOI <- shapefile("samplingField.shp")

samples <- read.csv("samplingData.csv")

B4 <- raster("T32UPU_20210814T102031_B04_10m_extent.grd")
B8 <- raster("CT32UPU_20210814T102031_B08_10m_extent.grd")
```

Soil sampling data contains several columns that store amount of various
nutrients sampled at certain locations. Some of these we will use to
create fertilizer application maps. Therefore, we should convert the csv
data into spatial points dataframe using latitude and longitude values
and **SpatialPointsDataFrame()** function.

Open the csv data and check which columns store location information.

``` r
samples.shp <- SpatialPointsDataFrame(samples[,3:2],  samples)

# Set the crs for samples.shp using AOI shapefile.

crs(samples.shp) <- 
```

## Analysis

In order to create cite specific fertilizer prescription maps, we will
follow the steps shown in the flowchart below.

<img
src="C:/Users/ismayiir/Desktop/R_Github/PrecisionAgriculture/Workflow.png"
style="width:75.0%" />

We are given only information at certain points. However, for
prescribing fertilizer amount we need to extend the sampling information
to the whole field. We can achieve this by interpolating sampling
points. In this tutorial we will use Inverse Distance Weighted (IDW)
method.

**IDW** method is based on weighting the points where the influence of
one point relative to another one declines as the distance to unknown
point increases.

In R we can use \*\*gstat\* package to perform IDW. Yet, we first have
to create an empty meshgrid into which interpolated values will be
saved.

``` r
#create a dataframe that takes the extent of AOI and creates 50000 sampes

field.grid <- as.data.frame(spsample(AOI, "regular", n=50000))

#give the column names and populate them with x & y values

names(field.grid) <- c("X", "Y")

coordinates(field.grid) <- c("X", "Y")

#convert the spatial points into spatial pixels and then into spatial Grid

gridded(field.grid) <- TRUE  

fullgrid(field.grid) <- TRUE  

# Add the projection information to the empty grid

proj4string(field.grid) <- proj4string(samples.shp)
```

**KDW Interpolation**

For the next steps we need to have potassium and phosporus information
from the soil sampling data. Therefore, we will interpolate this
columns.

Interpolate potassium content (K_ppm). This column contains potassium
amount i measured in parts per million (ppm).

``` r
K.idw <- gstat::idw(K_ppm ~ 1, samples.shp, newdata=field.grid, idp=2.0)

#convert the results into raster

K.idw.raster <- raster(K.idw)

#plot the results
```

In order to calculate amount of the needed K20 fertilizer, will first
have to convert potassium values from ppm to kg/ ha.

The conversion ppm to kg/ is not straightforward and requires
information on many different parameters (e.g. bulk density of the
soil). Therefore, you can refer to the values below in order to
reclassify the interpolated potassium raster. Note that you have already
done reclassification before.

- 0 - 45 -\> 100
- 45 - 90 -\> 200
- 90 - 135 -\> 300
- 135 - 180 -\> 400
- 180 - 225 -\> 500
- 225 - 292 -\> 600

``` r
reclass.matrix <-

reclass.matrix.reshape <-

K.reclassified <- reclassify()

plot(K.reclassified)
```

Now your reclassified raster contains potassium amount in kg. Based on
this value we can create a K2O fertilizer prescription map that shows
how much of potash should be given to the certain areas of the field.

This is another reclassification task that follows the following values:

- 0 - 100 -\> 80
- 101 - 200 -\> 60
- 201 - 300 -\> 40
- 301 - 400 -\> 40
- 401 - 500 -\> 40
- 500 - Inf -\> 0

``` r
#define the amount of the potash fertilize by reclassifying K.reclassified
```

Phosphate fertilizer application procedure is similar to the potassium.
Meaning, plant available phosphorus must be interpolated and based on
the existing formula fertilizer application map can be created.

In Agriculture, usually, only plant available phosphorus matters as the
other forms of it cannot be utilized by plants. Plant available
phosphorus is stored in the P_AI_ratio column.

``` r
#interpolate plant available phosphorus

P.idw <- gstat::idw()
P.idw.raster <- raster(P.idw)

#P2o5 fertilizer amount for prescription can be calculated using the following formula

P2O5 <- (20-P.idw.raster)*4*(P.idw.raster <20) 

plot(P2O5)
```

We will now calculate NDVI based nitrogen amount to prescribe. Using the
previously learned techniques calculate NDVI from the Sentinel-2 images,
clip it to the extent of the AOI.

``` r
NDVI <- 

NDVI.clip <- raster::crop()
```

Before we can calculate the needed amount of nitrogen we require have to
calculate Sufficiency Index (SI) first. SI is calculated based on the
following formula: **NDVI/NDVImax**, where NDVImax is the maximum value
of the NDVI.

``` r
#check for the maximum value of NDVI

summary(NDVI)

#calculate SI

SI <- 
```

Calculate the needed NDVI based nitrogen amount following the given
formula.

``` r
#convert the raster data into dataframe

image1<- as.data.frame(SI, row.names=NULL, optional=FALSE, xy=TRUE, 
                       na.rm=FALSE, long=FALSE)

#using if else statement calculate N application amount
image1$SI <- ifelse(SI$layer < 0.4, 0, ifelse(SI$layer < 0.6, 180*(SI$layer-0.4)/0.2, 
                                              ifelse(SI$layer< 1.0, 20+160* sqrt((1-SI$layer)/0.4),20 )))


#convert the dataframe back to raster using x and y values

dfr <- rasterFromXYZ(image1) 

plot(dfr)
```

Now you should have three different fertilizer application maps.
