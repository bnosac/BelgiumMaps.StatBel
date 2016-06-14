# Administrative boundaries of Belgium based on Open Data available at Statistics Belgium

The  **BelgiumMaps.StatBel** package contains maps with administrative boundaries (national, regions, provinces, districts, municipalities, statistical sectors, agglomerations (200m)) of Belgium extracted from Open Data at Statistics Belgium. Data is converted from Lambert CRS into the WGS84 coordinate reference system. 

This data is available in several objects:

- BE_ADMIN_SECTORS: SpatialPolygonsDataFrame with polygons and data at the level of the statistical sector
- BE_ADMIN_MUNTY: SpatialPolygonsDataFrame with polygons and data at the level of the municipality
- BE_ADMIN_DISTRICT: SpatialPolygonsDataFrame with polygons and data at the level of the district
- BE_ADMIN_PROVINCE: SpatialPolygonsDataFrame with polygons and data at the level of the province
- BE_ADMIN_REGION: SpatialPolygonsDataFrame with polygons and data at the level of the region
- BE_ADMIN_BELGIUM: SpatialPolygonsDataFrame with polygons and data at the level of the whole of Belgium
- BE_ADMIN_HIERARCHY: data.frame with administrative hierarchy of Belgium
- BE_ADMIN_AGGLOMERATIONS: SpatialPolygonsDataFrame with polygons and data at the level of an agglomeration (200m)

    
## Installation

```
install.packages(c('sp', 'knitr', 'markdown'))
devtools::install_git("http://bnosac.all2all.org:10080/gitlab/open-source/BelgiumMaps.StatBel.git", build_vignettes = TRUE)
## See the vignette
vignette("BelgiumMaps_AdministrativeAreas_StatBel.Rmd", package = "BelgiumMaps.StatBel")
```

## Support in geospatial analysis

Need support in geospatial analysis or geospatial mapping. 
Contact BNOSAC: http://www.bnosac.be

