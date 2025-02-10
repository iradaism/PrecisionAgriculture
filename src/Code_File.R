library("sp")
library("raster")
library("gstat")


OI <- shapefile("samplingField.shp")

samples <- read.csv("samplingData.csv")

samples.shp <- SpatialPointsDataFrame(samples[,3:2],  samples)

crs(samples.shp) <- '+proj=utm +zone=32 +datum=WGS84 +units=m +no_defs'

field.grid <- as.data.frame(spsample(OI, "regular", n=50000))
names(field.grid)       <- c("X", "Y")
coordinates(field.grid) <- c("X", "Y")
gridded(field.grid)     <- TRUE  # Create SpatialPixel object
fullgrid(field.grid)    <- TRUE  # Create SpatialGrid object


proj4string(field.grid) <- proj4string(samples.shp)

K.idw <- gstat::idw(K_ppm ~ 1, samples.shp, newdata=field.grid, idp=2.0)
r <- raster(K.idw)
writeRaster(r, "K_ppm.tif")

plot(r)


P.idw <- gstat::idw(P_AI_ratio ~ 1, samples.shp, newdata=grid.field, idp=2.0)
r2 <- raster(P.idw)
plot(r2)
writeRaster(r2, "P_AL.tif")

reclass.matrix <- c(0, 45, 100,
                    45, 90, 200,
                    90, 135, 300,
                    135, 180, 400,
                    180, 225, 500,
                    225, 292, 600)

reclass.matrix.reshape <- matrix(reclass.matrix,
                                 ncol = 3,
                                 byrow = TRUE)


reclass.matrix.reshape

K.reclassified <- reclassify(r, reclass.matrix.reshape)
plot(K.reclassified)
writeRaster(K.reclassified, "k.reclass.tif")

reclass.matrix2 <- c(0, 100, 80,
                     101, 200, 60,
                     201, 300, 40,
                     301, 400, 40,
                     401, 500, 40,
                     500, Inf, 0)

reclass.matrix.reshape2 <- matrix(reclass.matrix2,
                                  ncol = 3,
                                  byrow = TRUE)


K.application <- reclassify(K.reclassified, reclass.matrix.reshape2)
plot(K.application)

p2.application <- (20-r2)*4*(r2 <20)
plot(p2.application)


B4 <- raster("T32UPU_20210814T102031_B04_10m_extent.grd")
B8 <- raster("T32UPU_20210814T102031_B08_10m_extent.grd")

B4.clip <- raster::crop(B4, OI)  
B8.clip <- raster::crop(B8, OI)


NDVI <- (B8.clip - B4.clip) / (B8.clip + B4.clip)

plot(NDVI)

summary(NDVI)

SI <- NDVI/0.9062770

image<- SI

image1<- as.data.frame(image, row.names=NULL, optional=FALSE, xy=TRUE, 
                       na.rm=FALSE, long=FALSE)


image1$SI <- ifelse(image1$layer < 0.4, 0, ifelse(image1$layer < 0.6, 180*(image1$layer-0.4)/0.2, 
                                                  ifelse(image1$layer< 1.0, 20+160* sqrt((1-image1$layer)/0.4),20 )))


dfr <- rasterFromXYZ(image1) 
plot(dfr)


rst <- writeRaster(dfr, "N_application.tif", format="GTiff", overwrite=TRUE)


