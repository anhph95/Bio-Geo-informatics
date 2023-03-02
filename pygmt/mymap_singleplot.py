#!/usr/bin/env python3

# Import libraries
import pygmt
import xarray as xr
import geopandas as gpd
import subprocess
# define parameters for plotting
pygmt.config(MAP_FRAME_TYPE = 'fancy',
            FONT_ANNOT_PRIMARY = '10p,Helvetica',
            FONT_LABEL = '10p,Helvetica',
            FONT_TITLE = '10p,Helvetica',
            FONT_TAG = '12p,Helvetica-Bold',
            FORMAT_GEO_MAP = 'dddF',
            FORMAT_FLOAT_OUT = '%2.1f',
            PS_MEDIA = "A4",
            COLOR_NAN = "gray")

# Time dimension to read
i = 0
# Output file name
name = "KD490/KN197_kd490_v2.png".format(i)
coord = "-62/-42/-2/18"
#coord = "-65/-35/-5/25"
# Load data
mydata = xr.open_dataset("compiled/KN197_20100525-20100625.nc")
longhurst = gpd.read_file("longhurst_v4_2010/Longhurst_world_v4_2010.shp")
# Replace 0 with NaN
mydata = mydata.where(mydata['KD490_mean'] != 0.)
# Plot
fig = pygmt.Figure()
# Gridding of data
subprocess.call("gmt makecpt -Cturbo -T0.02/0.2 -M -Do > mycolor.cpt",shell=True)
# Grid data
#fig.grdimage(grid="AmazonBathy.grd",cmap='globe',projection="M15c",frame=True,region=coord,shading="AmazonIllum.grd")
fig.grdimage(grid=mydata["KD490_mean"],cmap='mycolor.cpt',projection="M15c",frame=True,region=coord)
# Add land, shorelines
fig.coast(resolution="f",shorelines=True,land="gray")
#fig.coast(resolution="f",shorelines="0.1p,black",borders="1/thick,red",rivers="a/blue",projection="M15c",frame=True,region=coord)
# Add EEZ boundaries
#fig.plot("World_Maritime_Boundaries_v5_20091001.gmt", pen="0.75p,gold")
# Add track
#fig.plot("track_kn197.xydat", pen="0.6p,black")
# Add stations
#fig.plot("KN197_stn.txt",style="c6p", color="lightred", pen="0.5p")
# Add colorbar
fig.colorbar(cmap='mycolor.cpt',frame=['x+lKD490','y+lm-1'])
# Edit frame
fig.basemap(frame=["afg"])
# Add province
fig.plot(longhurst,pen="1,red")
# Save figures
fig.savefig(name,crop=False)
