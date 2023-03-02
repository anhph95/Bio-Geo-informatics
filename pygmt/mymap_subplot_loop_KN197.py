#!/usr/bin/env python3

# Import libraries
import pygmt
import xarray as xr
import pandas as pd
import numpy as np
import subprocess

################################################################################

## USER SETTING
# define parameters for plotting
pygmt.config(MAP_FRAME_TYPE = 'fancy',
            FONT_ANNOT_PRIMARY = '10p,Helvetica',
            FONT_LABEL = '10p,Helvetica',
            FONT_TITLE = '10p,Helvetica',
            FONT_HEADING = '12p,Helvetica-Bold',
            FORMAT_GEO_MAP = 'dddF',
            FORMAT_FLOAT_OUT = '%2.1f',
            PS_MEDIA = "A4")

# Set file and columns to read
# Grid file
gridfile = "physic_data_kn197.nc"
grid_ssh = "zos"
grid_sss = "so"
grid_sst = "thetao"

# Moving station file
stnfile = "eventlog_kn197.csv"
stn_time = 'Time (Z)'
stn_lon = 'lon'
stn_lat = 'lat'

# Fixed station file
stn_fix = "KN197_stn.txt"

# Track file
trackfile = "track_kn197.xydat"

# Others
cruise = "KN197" # Cruise name for plot title
coord = "-62/-42/-2/18" # coordination for plot subset
#coord = "-62/-12/-2/28"

# CPT color files to generate
cmdln1 = "gmt makecpt -Cvik -T-0.3/0.3 > ssh.cpt" # SSH
cmdln2 = "gmt makecpt -Crainbow -T0/38 > salinity.cpt" # SSS
cmdln3 = "gmt makecpt -Cmagma -T24/30 > temperature.cpt" # SST
cmdln4 = "gmt grdcut @earth_relief_15s -R{} -GAmazonBathy.grd".format(coord)
cmdln5 = "gmt grdgradient AmazonBathy.grd -GAmazonIllum.grd -A270/20 -Nt"

################################################################################

# Generate color files
# Better to call from subprocess than using the python command
subprocess.call(cmdln1,shell=True)
subprocess.call(cmdln2,shell=True)
subprocess.call(cmdln3,shell=True)
subprocess.call(cmdln4,shell=True)
subprocess.call(cmdln5,shell=True)


# Read files
mydata = xr.open_dataset(gridfile)
stn = pd.read_csv(stnfile)

# Convert track and station time to datetime format for comparison
stn[stn_time] = pd.to_datetime(stn[stn_time]).dt.tz_localize(None)

# Iterate through netCDF time dimension
for i in range(0,len(mydata.time)):
    # Data subset
    subdata = mydata.isel(time=i,depth=0) # rm depth if no depth dimension
    # Expand time dimension to 24h range
    dt_low = subdata.time.values - np.timedelta64(12,'h')
    dt_high = subdata.time.values + np.timedelta64(12,'h')
    # Subset station by date
    substn = stn[(stn[stn_time] > dt_low ) & (stn[stn_time] <= dt_high) & (stn['Operation']=='CTD')] # also filter for CTD station only
    # Time string for title
    mytime = pd.to_datetime(str(subdata.time.values)).strftime('%m.%d.%Y')
    # Title
    if len(substn) != 0:
        mytitle = "{} - {} - {}".format(cruise,mytime,substn['Text'].iloc[0]) # Get station number
    else:
        mytitle = "{} - {}".format(cruise,mytime)
    # Output file name
    outname = "temp/temp_{}.png".format(i)
    # Plot
    fig = pygmt.Figure()
    # Define figure subplot
    with fig.subplot(nrows=2,ncols=2,autolabel="A+JTL+o0.5c",subsize=("7c", "7c"),margins=['1c','1.5c']):
        with fig.set_panel(panel=0):
            # Gridding of data
            fig.grdimage(grid=subdata[grid_ssh],cmap='ssh.cpt',projection="M?",frame=True,region=coord)
            # Add land, shorelines
            fig.coast(resolution="f",shorelines=True,land="gray")
            # Add colorbar
            fig.colorbar(cmap='ssh.cpt',frame=['x+l"Sea surface height above geoid"','y+lm'])
            # Edit frame
            fig.basemap(frame=["afg"])
            # Add stations
            if len(substn) != 0:
                fig.plot(x=substn[stn_lon],y=substn[stn_lat],style="c6p", color="lightred", pen="0.5p")
            # Add information
            fig.text(text=mytitle,position="TL",offset="j-0.5c/-2c",font='14p,Helvetica-Bold',no_clip=True)
        with fig.set_panel(panel=1):
            # Gridding of data
            fig.grdimage(grid=subdata[grid_sss],cmap='salinity.cpt',projection="M?",frame=True,region=coord)
            # Add land, shorelines
            fig.coast(resolution="f",shorelines=True,land="gray")
            # Add colorbar
            fig.colorbar(cmap='salinity.cpt',frame=['x+l"Salinity"','y+l"psu"'])
            # Edit frame
            fig.basemap(frame=["afg"])
            # Add stations
            if len(substn) != 0:
                fig.plot(x=substn[stn_lon],y=substn[stn_lat],style="c6p", color="lightred", pen="0.5p")
        with fig.set_panel(panel=2):
            # Gridding of data
            fig.grdimage(grid=subdata[grid_sst],cmap='temperature.cpt',projection="M?",frame=True,region=coord)
            # Add land, shorelines
            fig.coast(resolution="f",shorelines=True,land="gray")
            # Add colorbar
            fig.colorbar(cmap='temperature.cpt',frame=['x+l"Potential temperature"','y+l"degree C"'])
            # Edit frame
            fig.basemap(frame=["afg"])
            # Add stations
            if len(substn) != 0:
                fig.plot(x=substn[stn_lon],y=substn[stn_lat],style="c6p", color="lightred", pen="0.5p")
        with fig.set_panel(panel=3):
            # Gridding of data
            fig.grdimage(grid="AmazonBathy.grd",cmap='globe',projection="M?",frame=True,region=coord,shading="AmazonIllum.grd")
            # Add land, shorelines
            fig.coast(resolution="f",shorelines="0.1p,black",borders="1/thick,red",rivers="a/blue",projection="M?",frame=True,region=coord)
            # # Add colorbar
            # fig.colorbar(cmap='globe',frame=['x+lElevation','y+lm'])
            # Add EEZ boundaries
            fig.plot("World_Maritime_Boundaries_v5_20091001.gmt", pen="0.75p,gold")
            # Add track
            fig.plot(trackfile, pen="0.6p,black")
            # Add stations
            fig.plot(stn_fix,style="c6p", color="lightred", pen="0.5p")
            # Edit frame
            fig.basemap(frame=["afg"])
    # Save figures
    fig.savefig(outname,crop=False,transparent=False,anti_alias=True)
