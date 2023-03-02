#!/usr/bin/env python3

# Import libraries
import pygmt
import xarray as xr
import os

# define parameters for plotting
pygmt.config(MAP_FRAME_TYPE = 'fancy',
            FONT_ANNOT_PRIMARY = '10p,Helvetica',
            FONT_LABEL = '10p,Helvetica',
            FONT_TITLE = '10p,Helvetica',
            FONT_TAG = '11p,Helvetica-Bold',
            FORMAT_GEO_MAP = 'dddF',
            FORMAT_FLOAT_OUT = '%2.1f',
            PS_MEDIA = "A4")

# Time dimension to read
i = 6
# Output file name
#name = "temp_{}.png".format(i)
name = "M174.png"
# Station coord
lon = -56.25
lat = 14.92
# Load data
mydata = xr.open_dataset("global-analysis-forecast-phy-001-024_1667835423172_M174.nc").isel(time=i,depth=0)

# Plot
fig = pygmt.Figure()
# Define figure subplot
with fig.subplot(nrows=2,ncols=2,autolabel="A+JTL+o0.5c",subsize=("8c", "8c"),margins=['0.5c','1c'],title="M174"):
    with fig.set_panel(panel=0):
        # Gridding of data
        # In terminal, run:
        # gmt makecpt -Cvik -T0.02/0.26 > ssh.cpt
        fig.grdimage(grid=mydata.zos,cmap='ssh.cpt',projection="M?",frame=True)
        # Add land, shorelines
        fig.coast(resolution="f",shorelines=True,land="gray")
        # Add colorbar
        fig.colorbar(cmap='ssh.cpt',frame=['x+lSSH','y+lm'])
        # Add stations
        fig.plot(x=lon,y=lat,style="c.3c", color="lightred", pen="1p")
        # Edit frame
        fig.basemap(frame=["afg"])
    with fig.set_panel(panel=1):
        # In terminal, run:
        # gmt makecpt -Crainbow -T22/37 > salinity.cpt
        # pygmt.makecpt(cmap='imola',series=[22,38,1],output='salinity.cpt')
        fig.grdimage(grid=mydata.so,cmap='salinity.cpt',projection="M?",frame=True)
        # Add land, shorelines
        fig.coast(resolution="f",shorelines=True,land="gray")
        # Add colorbar
        fig.colorbar(cmap='salinity.cpt',frame=['x+lSSS','y+lm'])
        # Add stations
        fig.plot(x=lon,y=lat,style="c.3c", color="lightred", pen="1p")
        # Edit frame
        fig.basemap(frame=["afg"])
    with fig.set_panel(panel=2):
        # In terminal, run:
        # gmt makecpt -Cmagma -T25/28 > temperature.cpt
        fig.grdimage(grid=mydata.thetao,cmap='temperature.cpt',projection="M?",frame=True)
        # Add land, shorelines
        fig.coast(resolution="f",shorelines=True,land="gray")
        # Add colorbar
        fig.colorbar(cmap='temperature.cpt',frame=['x+lSST','y+lm'])
        # Add stations
        fig.plot(x=lon,y=lat,style="c.3c", color="lightred", pen="1p")
        # Edit frame
        fig.basemap(frame=["afg"])



# Save figures
fig.savefig(name,crop=True)
