library(rgdal)
library(sp)
library(rgeos)
library(tmap)
library(utils)
library(data.table)
library(maptools)
library(tools)

settings <- list()
settings$hierarchy <- list()
settings$hierarchy$municipalities <- file.path(getwd(), "inst", "extdata", "TF_PSNL_INC_TAX_MUNTY_tcm325-272513.zip")
settings$hierarchy$nis.sectors <- file.path(getwd(), "inst", "extdata", "TF_PSNL_INC_TAX_SECTOR_tcm325-278417.zip")
settings$nis.sectors <- file.path(getwd(), "inst", "extdata", "scbel01012011_gen13_tcm325-275679.zip")
settings$agglomeraties <- file.path(getwd(), "inst", "extdata", "SH_CENSUS_2011_AGGLOMERATIONS_200M.shp_tcm325-276234.zip")
unzip(settings$nis.sectors, list = FALSE, exdir = file_path_sans_ext(settings$nis.sectors))
unzip(settings$agglomeraties, list = FALSE, exdir = file_path_sans_ext(settings$agglomeraties))
settings$nis.sectors <- file.path(getwd(), "inst", "extdata", "scbel01012011_gen13_tcm325-275679", "scbel01012011_gen13.shp")
settings$agglomeraties <- file.path(getwd(), "inst", "extdata", "SH_CENSUS_2011_AGGLOMERATIONS_200M.shp_tcm325-276234", "SH_CENSUS_2011_AGGLOMERATIONS_200M.shp")

##
## Import NIS hierarchy
##
unzip(settings$hierarchy$municipalities, list = TRUE)
unzip(settings$hierarchy$nis.sectors, list = TRUE)
hierarchy <- list()
hierarchy$municipalities <- read.table(unz(settings$hierarchy$municipalities, filename = "TF_PSNL_INC_TAX_MUNTY.txt"), sep="|", header = TRUE, 
                                       encoding = "UTF-8", stringsAsFactors = FALSE, quote = "")
hierarchy$nis.sectors <- read.table(unz(settings$hierarchy$nis.sectors, filename = "TF_PSNL_INC_TAX_SECTOR.txt"), sep="|", header = TRUE, 
                                       encoding = "UTF-8", stringsAsFactors = FALSE, quote = "")
hierarchy$municipalities <- unique(hierarchy$municipalities[, c("CD_MUNTY_REFNIS", "TX_MUNTY_DESCR_NL", "TX_MUNTY_DESCR_FR", 
                                                         "CD_DSTR_REFNIS", "TX_ADM_DSTR_DESCR_NL", "TX_ADM_DSTR_DESCR_FR", 
                                                         "CD_PROV_REFNIS", "TX_PROV_DESCR_NL", "TX_PROV_DESCR_FR", 
                                                         "CD_RGN_REFNIS", "TX_RGN_DESCR_NL", "TX_RGN_DESCR_FR")])
hierarchy$nis.sectors <- unique(hierarchy$nis.sectors[, c("CD_MUNTY_REFNIS", "CD_SECTOR", "CD_REFNIS_SECTOR", "TX_SECTOR_DESCR_NL", "TX_SECTOR_DESCR_FR")])
sum(duplicated(hierarchy$municipalities$CD_MUNTY_REFNIS)) ## doublecheck to make sure names did not change over the years
sum(duplicated(hierarchy$nis.sectors$CD_REFNIS_SECTOR)) ## doublecheck to make sure names did not change over the years
hierarchy <- merge(hierarchy$nis.sectors, hierarchy$municipalities, by = "CD_MUNTY_REFNIS")
BE_ADMIN_HIERARCHY <- hierarchy[, c("CD_REFNIS_SECTOR", "CD_SECTOR", "TX_SECTOR_DESCR_NL", "TX_SECTOR_DESCR_FR", 
                                    "CD_MUNTY_REFNIS", "TX_MUNTY_DESCR_NL", "TX_MUNTY_DESCR_FR", 
                                    "CD_DSTR_REFNIS", "TX_ADM_DSTR_DESCR_NL", "TX_ADM_DSTR_DESCR_FR", 
                                    "CD_PROV_REFNIS", "TX_PROV_DESCR_NL", "TX_PROV_DESCR_FR", 
                                    "CD_RGN_REFNIS", "TX_RGN_DESCR_NL", "TX_RGN_DESCR_FR")]

##
## Import shape of agglomerations
##
ogrListLayers(settings$agglomeraties)
ogrInfo(settings$agglomeraties, layer = "SH_CENSUS_2011_AGGLOMERATIONS_200M")

BE_ADMIN_AGGLOMERATIONS <- readShapeSpatial(fn = settings$agglomeraties, proj4string = CRS("+init=EPSG:31370"))
#BE_ADMIN_AGGLOMERATIONS <- readOGR(settings$agglomeraties, layer = "SH_CENSUS_2011_AGGLOMERATIONS_200M", stringsAsFactors = FALSE) ## will need to ask statbel why this is different
colnames(BE_ADMIN_AGGLOMERATIONS@data) <- tolower(make.names(colnames(BE_ADMIN_AGGLOMERATIONS@data), allow_=FALSE))
BE_ADMIN_AGGLOMERATIONS <- spTransform(x=BE_ADMIN_AGGLOMERATIONS, CRSobj = CRS("+proj=longlat +datum=WGS84"))

##
## Import shape of NIS sectors
##
ogrListLayers(settings$nis.sectors)
ogrInfo(settings$nis.sectors, layer = "scbel01012011_gen13")

BE_ADMIN_SECTORS <- readShapeSpatial(fn = settings$nis.sectors, proj4string = CRS("+init=EPSG:31370"))
#BE_ADMIN_SECTORS <- readOGR(settings$nis.sectors, layer = "scbel01012011_gen13", stringsAsFactors = FALSE) ## gives a shift when putting in WGS84
colnames(BE_ADMIN_SECTORS@data) <- tolower(make.names(colnames(BE_ADMIN_SECTORS@data), allow_=FALSE))

isutf8 <- function(x){
  for(column in colnames(x)){
    if(is.character(x[[column]]) | is.factor(x[[column]])){
      x[[column]] <- as.character(x[[column]])
      Encoding(x[[column]]) <- "UTF-8"
    }
  }
  x
}
BE_ADMIN_SECTORS@data <- isutf8(BE_ADMIN_SECTORS@data)
BE_ADMIN_SECTORS$nuts0 <- "BE"
BE_ADMIN_SECTORS@data <- setnames(BE_ADMIN_SECTORS@data, old = "nuts3.new", new = "nuts3")
BE_ADMIN_SECTORS@data <- BE_ADMIN_SECTORS@data[, c(setdiff(names(BE_ADMIN_SECTORS), c("nuts0", "nuts1", "nuts2", "nuts3")), c("nuts0", "nuts1", "nuts2", "nuts3"))]
## make brussels into a province
BE_ADMIN_SECTORS$prov.nl <- ifelse(is.na(BE_ADMIN_SECTORS$prov.nl), BE_ADMIN_SECTORS$reg.nl, BE_ADMIN_SECTORS$prov.nl)
BE_ADMIN_SECTORS$prov.fr <- ifelse(is.na(BE_ADMIN_SECTORS$prov.fr), BE_ADMIN_SECTORS$reg.fr, BE_ADMIN_SECTORS$prov.fr)
## add area in km2
BE_ADMIN_SECTORS$gis.area.km2 <- BE_ADMIN_SECTORS$gis.area.h / 100
BE_ADMIN_SECTORS$cad.area.km2 <- BE_ADMIN_SECTORS$cad.area.h / 100
## convert to WGS84 coordinates instead of Lambert
BE_ADMIN_SECTORS <- spTransform(x=BE_ADMIN_SECTORS, CRSobj = CRS("+proj=longlat +datum=WGS84"))

## remove redundant data (not needed as in sector)
BE_ADMIN_SECTORS$nis.012011 <- NULL
BE_ADMIN_SECTORS$sec012011 <- NULL

## add information of hierarchy based on NIS definition in 20/01/2011
## mark that BE_ADMIN_HIERARCHY contains sectors not in BE_ADMIN_SECTORS$cs012011 (TAXES not linked to sector or to sector in other period namely cs102001)
##   this can be checked with x <- subset(BE_ADMIN_HIERARCHY, !CD_REFNIS_SECTOR %in%  BE_ADMIN_SECTORS$cs012011)
## also sectors seem to exist in the BE_ADMIN_SECTORS which are not in the taxes data first fix these
x <- subset(BE_ADMIN_SECTORS@data, !cs012011 %in% BE_ADMIN_HIERARCHY$CD_REFNIS_SECTOR)
x$CD_REFNIS_SECTOR <- x$cs012011
x$CD_MUNTY_REFNIS <- substr(x$CD_REFNIS_SECTOR, 1, 5)
x$CD_SECTOR <- substr(x$CD_REFNIS_SECTOR, 6, nchar(x$CD_REFNIS_SECTOR))
x <- setnames(x, old = c("sector.nl", "sector.fr"), new = c("TX_SECTOR_DESCR_NL", "TX_SECTOR_DESCR_FR"))
x <- x[, c("CD_REFNIS_SECTOR", "CD_SECTOR", "TX_SECTOR_DESCR_NL", "TX_SECTOR_DESCR_FR", "CD_MUNTY_REFNIS")]
x <- merge(x, unique(BE_ADMIN_HIERARCHY[, c(#"CD_REFNIS_SECTOR", "CD_SECTOR", "TX_SECTOR_DESCR_NL", "TX_SECTOR_DESCR_FR", 
  "CD_MUNTY_REFNIS", "TX_MUNTY_DESCR_NL", "TX_MUNTY_DESCR_FR", 
  "CD_DSTR_REFNIS", "TX_ADM_DSTR_DESCR_NL", "TX_ADM_DSTR_DESCR_FR", 
  "CD_PROV_REFNIS", "TX_PROV_DESCR_NL", "TX_PROV_DESCR_FR", 
  "CD_RGN_REFNIS", "TX_RGN_DESCR_NL", "TX_RGN_DESCR_FR")]), by = "CD_MUNTY_REFNIS")
x <- x[, names(BE_ADMIN_HIERARCHY)]
BE_ADMIN_HIERARCHY <- rbind(BE_ADMIN_HIERARCHY, x) 
## mark that sectors can be split or aggregated from year to year (see subset(BE_ADMIN_SECTORS, cs102001 == "52063A372")@data) and Hmisc::describe(BE_ADMIN_SECTORS@data) (look at uniques in sector ids)
## there seems to be one element per cs012011 but doubles in older NIS versions. will use version cs012011
BE_ADMIN_SECTORS$CD_REFNIS_SECTOR <- BE_ADMIN_SECTORS$cs012011
BE_ADMIN_SECTORS <- merge(BE_ADMIN_SECTORS, BE_ADMIN_HIERARCHY, by.x = "CD_REFNIS_SECTOR", by.y = "CD_REFNIS_SECTOR", all.x=FALSE, all.y=FALSE)
BE_ADMIN_SECTORS@data <- BE_ADMIN_SECTORS@data[, c(setdiff(names(BE_ADMIN_SECTORS), colnames(BE_ADMIN_HIERARCHY)), colnames(BE_ADMIN_HIERARCHY))]

## add nuts information to hierarchy
BE_ADMIN_HIERARCHY <- merge(BE_ADMIN_HIERARCHY, 
                            unique(na.exclude(BE_ADMIN_SECTORS@data[, c("CD_MUNTY_REFNIS", "nuts0", "nuts1", "nuts2", "nuts3")])), 
                            by = "CD_MUNTY_REFNIS", all.x=TRUE, all.y=FALSE)
BE_ADMIN_HIERARCHY <- BE_ADMIN_HIERARCHY[, c("CD_REFNIS_SECTOR", "CD_SECTOR", "TX_SECTOR_DESCR_NL", "TX_SECTOR_DESCR_FR", 
                                             "CD_MUNTY_REFNIS", "TX_MUNTY_DESCR_NL", "TX_MUNTY_DESCR_FR", 
                                             "CD_DSTR_REFNIS", "TX_ADM_DSTR_DESCR_NL", "TX_ADM_DSTR_DESCR_FR", 
                                             "CD_PROV_REFNIS", "TX_PROV_DESCR_NL", "TX_PROV_DESCR_FR", 
                                             "CD_RGN_REFNIS", "TX_RGN_DESCR_NL", "TX_RGN_DESCR_FR", "nuts0", "nuts1", "nuts2", "nuts3")]

x <- split(BE_ADMIN_SECTORS, BE_ADMIN_SECTORS$CD_MUNTY_REFNIS)
x <- lapply(x, FUN=function(data){
  SpatialPolygonsDataFrame(gUnaryUnion(spgeom = data),
                           data = data.frame(CD_MUNTY_REFNIS = unique(data$CD_MUNTY_REFNIS),
                                             TX_MUNTY_DESCR_NL = unique(data$TX_MUNTY_DESCR_NL),
                                             TX_MUNTY_DESCR_FR = unique(data$TX_MUNTY_DESCR_FR),
                                             CD_DSTR_REFNIS = unique(data$CD_DSTR_REFNIS),
                                             TX_ADM_DSTR_DESCR_NL = unique(data$TX_ADM_DSTR_DESCR_NL),
                                             TX_ADM_DSTR_DESCR_FR = unique(data$TX_ADM_DSTR_DESCR_FR),
                                             CD_PROV_REFNIS = unique(data$CD_PROV_REFNIS),
                                             TX_PROV_DESCR_NL = unique(data$TX_PROV_DESCR_NL),
                                             TX_PROV_DESCR_FR = unique(data$TX_PROV_DESCR_FR),
                                             CD_RGN_REFNIS = unique(data$CD_RGN_REFNIS),
                                             TX_RGN_DESCR_NL = unique(data$TX_RGN_DESCR_NL),
                                             TX_RGN_DESCR_FR = unique(data$TX_RGN_DESCR_FR),
                                             nuts0 = paste(unique(data$nuts0), collapse=","),
                                             nuts1 = paste(unique(data$nuts1), collapse=","),
                                             nuts2 = paste(unique(data$nuts2), collapse=","),
                                             nuts3 = paste(unique(data$nuts3), collapse=","),
                                             SURFACE.GIS.h = sum(data@data$gis.area.h),
                                             SURFACE.CAD.h = sum(data@data$cad.area.h),
                                             SURFACE.GIS.km2 = sum(data@data$gis.area.km2),
                                             SURFACE.CAD.km2 = sum(data@data$cad.area.km2),
                                             stringsAsFactors=FALSE))
})
BE_ADMIN_MUNTY <- do.call(sbind, x)
plot(BE_ADMIN_MUNTY)

x <- split(BE_ADMIN_SECTORS, BE_ADMIN_SECTORS$CD_DSTR_REFNIS)
x <- lapply(x, FUN=function(data){
  SpatialPolygonsDataFrame(gUnaryUnion(spgeom = data),
                           data = data.frame(CD_DSTR_REFNIS = unique(data$CD_DSTR_REFNIS),
                                             TX_ADM_DSTR_DESCR_NL = unique(data$TX_ADM_DSTR_DESCR_NL),
                                             TX_ADM_DSTR_DESCR_FR = unique(data$TX_ADM_DSTR_DESCR_FR),
                                             CD_PROV_REFNIS = unique(data$CD_PROV_REFNIS),
                                             TX_PROV_DESCR_NL = unique(data$TX_PROV_DESCR_NL),
                                             TX_PROV_DESCR_FR = unique(data$TX_PROV_DESCR_FR),
                                             CD_RGN_REFNIS = unique(data$CD_RGN_REFNIS),
                                             TX_RGN_DESCR_NL = unique(data$TX_RGN_DESCR_NL),
                                             TX_RGN_DESCR_FR = unique(data$TX_RGN_DESCR_FR),
                                             nuts0 = paste(unique(data$nuts0), collapse=","),
                                             nuts1 = paste(unique(data$nuts1), collapse=","),
                                             nuts2 = paste(unique(data$nuts2), collapse=","),
                                             nuts3 = paste(unique(data$nuts3), collapse=","),
                                             SURFACE.GIS.h = sum(data@data$gis.area.h),
                                             SURFACE.CAD.h = sum(data@data$cad.area.h),
                                             SURFACE.GIS.km2 = sum(data@data$gis.area.km2),
                                             SURFACE.CAD.km2 = sum(data@data$cad.area.km2),
                                             stringsAsFactors=FALSE))
})
BE_ADMIN_DISTRICT <- do.call(sbind, x)
plot(BE_ADMIN_DISTRICT)

x <- split(BE_ADMIN_SECTORS, BE_ADMIN_SECTORS$CD_PROV_REFNIS)
x <- lapply(x, FUN=function(data){
  SpatialPolygonsDataFrame(gUnaryUnion(spgeom = data),
                           data = data.frame(CD_PROV_REFNIS = unique(data$CD_PROV_REFNIS),
                                             TX_PROV_DESCR_NL = unique(data$TX_PROV_DESCR_NL),
                                             TX_PROV_DESCR_FR = unique(data$TX_PROV_DESCR_FR),
                                             CD_RGN_REFNIS = unique(data$CD_RGN_REFNIS),
                                             TX_RGN_DESCR_NL = unique(data$TX_RGN_DESCR_NL),
                                             TX_RGN_DESCR_FR = unique(data$TX_RGN_DESCR_FR),
                                             nuts0 = paste(unique(data$nuts0), collapse=","),
                                             nuts1 = paste(unique(data$nuts1), collapse=","),
                                             nuts2 = paste(unique(data$nuts2), collapse=","),
                                             SURFACE.GIS.h = sum(data@data$gis.area.h),
                                             SURFACE.CAD.h = sum(data@data$cad.area.h),
                                             SURFACE.GIS.km2 = sum(data@data$gis.area.km2),
                                             SURFACE.CAD.km2 = sum(data@data$cad.area.km2),
                                             stringsAsFactors=FALSE))
})
BE_ADMIN_PROVINCE <- do.call(sbind, x)
plot(BE_ADMIN_PROVINCE)


x <- split(BE_ADMIN_SECTORS, BE_ADMIN_SECTORS$CD_RGN_REFNIS)
x <- lapply(x, FUN=function(data){
  SpatialPolygonsDataFrame(gUnaryUnion(spgeom = data),
                           data = data.frame(CD_RGN_REFNIS = unique(data$CD_RGN_REFNIS),
                                             TX_RGN_DESCR_NL = unique(data$TX_RGN_DESCR_NL),
                                             TX_RGN_DESCR_FR = unique(data$TX_RGN_DESCR_FR),
                                             nuts0 = paste(unique(data$nuts0), collapse=","),
                                             nuts1 = paste(unique(data$nuts1), collapse=","),
                                             SURFACE.GIS.h = sum(data@data$gis.area.h),
                                             SURFACE.CAD.h = sum(data@data$cad.area.h),
                                             SURFACE.GIS.km2 = sum(data@data$gis.area.km2),
                                             SURFACE.CAD.km2 = sum(data@data$cad.area.km2),
                                             stringsAsFactors=FALSE))
})
BE_ADMIN_REGION <- do.call(sbind, x)
plot(BE_ADMIN_REGION)

BE_ADMIN_BELGIUM <- SpatialPolygonsDataFrame(gUnaryUnion(spgeom = BE_ADMIN_SECTORS),
                                             data = data.frame(nuts0 = paste(unique(BE_ADMIN_SECTORS$nuts0), collapse=","),
                                                               SURFACE.GIS.h = sum(BE_ADMIN_SECTORS@data$gis.area.h),
                                                               SURFACE.CAD.h = sum(BE_ADMIN_SECTORS@data$cad.area.h),
                                                               SURFACE.GIS.km2 = sum(BE_ADMIN_SECTORS@data$gis.area.km2),
                                                               SURFACE.CAD.km2 = sum(BE_ADMIN_SECTORS@data$cad.area.km2)))


save(BE_ADMIN_HIERARCHY, file = file.path(getwd(), "data", "BE_ADMIN_HIERARCHY.RData"), compress = 'xz')
save(BE_ADMIN_SECTORS, file = file.path(getwd(), "data", "BE_ADMIN_SECTORS.RData"), compress = 'xz')
save(BE_ADMIN_MUNTY, file = file.path(getwd(), "data", "BE_ADMIN_MUNTY.RData"), compress = 'xz')
save(BE_ADMIN_DISTRICT, file = file.path(getwd(), "data", "BE_ADMIN_DISTRICT.RData"), compress = 'xz')
save(BE_ADMIN_PROVINCE, file = file.path(getwd(), "data", "BE_ADMIN_PROVINCE.RData"), compress = 'xz')
save(BE_ADMIN_REGION, file = file.path(getwd(), "data", "BE_ADMIN_REGION.RData"), compress = 'xz')
save(BE_ADMIN_BELGIUM, file = file.path(getwd(), "data", "BE_ADMIN_BELGIUM.RData"), compress = 'xz')
save(BE_ADMIN_AGGLOMERATIONS, file = file.path(getwd(), "data", "BE_ADMIN_AGGLOMERATIONS.RData"), compress = 'xz')


# library(rmapshaper)
# x <- ms_simplify(BE_ADMIN_REGION, keep = 0.8)
# plot(BE_ADMIN_BELGIUM)
# save(BE_ADMIN_SECTORS, file = "BE_ADMIN_SECTORS.RData", compress = 'xz')
# save(BE_ADMIN_MUNTY, file = "BE_ADMIN_MUNTY.RData", compress = 'xz')
# save(BE_ADMIN_DISTRICT, file = "BE_ADMIN_DISTRICT.RData", compress = 'xz')
# save(BE_ADMIN_PROVINCE, file = "BE_ADMIN_PROVINCE.RData", compress = 'xz')
# save(BE_ADMIN_REGION, file = "BE_ADMIN_REGION.RData", compress = 'xz')
# save(BE_ADMIN_BELGIUM, file = "BE_ADMIN_BELGIUM.RData", compress = 'xz')
# plot(x)
# x <- gSimplify(BE_ADMIN_BELGIUM, tol = 10)
# 
# Hmisc::describe(BE_ADMIN_SECTORS@data)
