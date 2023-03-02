#!/usr/bin/env python3

# Modules
import glob
import subprocess
import xarray as xr
import pandas as pd
import numpy as np
import pygmt

# define parameters for plotting
pygmt.config(MAP_FRAME_TYPE = 'fancy',
            FONT_ANNOT_PRIMARY = '10p,Helvetica',
            FONT_LABEL = '10p,Helvetica',
            FONT_TITLE = '10p,Helvetica',
            FONT_TAG = '12p,Helvetica-Bold,white',
            FORMAT_GEO_MAP = 'dddF',
            FORMAT_FLOAT_OUT = '%2.1f',
            PS_MEDIA = "A4",
            PS_PAGE_ORIENTATION = "landscape",
            COLOR_NAN = "gray")



coord = "-60/-10/0/20"
cmdln1 = "gmt grdcut @earth_relief_15s -R{} -Gmygrid.grd".format(coord)
cmdln2 = "gmt grdgradient mygrid.grd -Gmyillum.grd -A270/20 -Nt"

# Better to call from subprocess than using the python command
# print("-----Generating topography file-----")
# subprocess.call(cmdln1,shell=True)
# print("-----Generating shading file-----")
# subprocess.call(cmdln2,shell=True)

# Get list of file
filenames = glob.glob("atlantic/*.nc")

data = xr.open_dataset("TNA.nc").isel(time=0,depth=0)
# Plot
fig = pygmt.Figure()
 # Gridding of data
print("-----Gridding topography------")
#fig.grdimage(grid="mygrid.grd",cmap='globe',projection="M20c",frame=True,region=coord,shading="myillum.grd")
fig.grdimage(grid=data["thetao"],projection="M20c",cmap='temperature.cpt',frame=True,region=coord)
# Add land, shorelines
fig.coast(resolution="f",shorelines=True,land="gray")
#fig.coast(resolution="f",land="gray",shorelines="0.2p,black",projection="M15c",frame=True,region=coord)
# Add EEZ boundaries
#fig.plot("World_Maritime_Boundaries_v5_20091001.gmt", pen="0.75p,white")
# Edit frame
fig.basemap(frame=["afg"])
for i in filenames:
    data = xr.open_dataset(i).isel(N_LEVELS=1)
    print("Reading {}".format(i))
    fig.plot(x=data['LONGITUDE'],y=data['LATITUDE'], pen="1p,black")
    fig.plot(x=data['LONGITUDE'],y=data['LATITUDE'], style = "c2.5p", color="gold",pen="0.5p,black",transparency=50)
    fig.plot(x=data['LONGITUDE'][-1],y=data['LATITUDE'][-1], style = "c5p", color="red",pen="0.5p,black")
# Save figures
print("-----Exporting figure-----")
fig.savefig("atlantic_argo.png",crop=False,transparent=False,anti_alias=True)
