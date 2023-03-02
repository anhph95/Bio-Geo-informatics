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
            FONT_ANNOT_PRIMARY = '12p,Helvetica',
            FONT_LABEL = '12p,Helvetica',
            FONT_TITLE = '12p,Helvetica',
            FONT_TAG = '14p,Helvetica-Bold,white',
            FORMAT_GEO_MAP = 'dddF',
            FORMAT_FLOAT_OUT = '%2.1f',
            PS_MEDIA = "A4",
            COLOR_NAN = "gray")



coord = "-70/-30/-10/30"


# Get list of file
filenames = glob.glob("temp/*.nc")

mydata = xr.open_dataset("ARP_salinity.nc")

cmdln1 = "gmt makecpt -Crainbow -T0/38 > salinity.cpt" # SSS
subprocess.call(cmdln1,shell=True)

for i in range(0,len(mydata.time)):
    # Data subset
    subdata = mydata.isel(time=i,depth=0) # rm depth if no depth dimension
    # Time string for title
    mytime = pd.to_datetime(str(subdata.time.values)).strftime('%b %Y')
    # Output file name
    outname = "temp/temp_{}.png".format(i)
    # Plot
    fig = pygmt.Figure()
    # Gridding of data
    print("-----Gridding topography------")
    #fig.grdimage(grid="mygrid.grd",cmap='globe',projection="M20c",frame=True,region=coord,shading="myillum.grd")
    fig.grdimage(grid=subdata["so"],projection="M12c",cmap='salinity.cpt',frame=True,region=coord)
    # Add land, shorelines
    fig.coast(resolution="f",shorelines=True,land="gray")
    #fig.coast(resolution="f",land="gray",shorelines="0.2p,black",projection="M15c",frame=True,region=coord)
    # Add EEZ boundaries
    #fig.plot("World_Maritime_Boundaries_v5_20091001.gmt", pen="0.75p,white")
    # Edit frame
    fig.basemap(frame=["afg"])
    # Add colorbar
    fig.colorbar(cmap='salinity.cpt',frame=['x+l"SSS"','y+l"psu"'])
    # Add information
    fig.text(text=mytime,position="TL",offset="j0c/-1c",font='18p,Helvetica-Bold',no_clip=True)
    # Save figures
    print("-----Exporting figure-----")
    fig.savefig(outname,crop=False,transparent=False,anti_alias=True)



