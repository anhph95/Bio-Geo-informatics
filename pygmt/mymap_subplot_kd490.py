#!/usr/bin/env python3

# Import libraries
import pygmt
import xarray as xr
import os
import subprocess
# define parameters for plotting
pygmt.config(MAP_FRAME_TYPE = 'fancy',
            FONT_ANNOT_PRIMARY = '10p,Helvetica',
            FONT_LABEL = '10p,Helvetica',
            FONT_TITLE = '10p,Helvetica',
            FONT_TAG = '12p,Helvetica-Bold,white',
            FORMAT_GEO_MAP = 'dddF',
            FORMAT_FLOAT_OUT = '%2.1f',
            PS_MEDIA = "A4",
            COLOR_NAN = "gray")

# Get files
import glob

# Time dimension to read
i = 0
# Output file name
name = "KD490/allcruise_v4.png".format(i)
coord = "-62/-42/-2/18"
#coord = "-65/-35/-5/25"
subprocess.call("gmt makecpt -Cturbo -T0.02/0.28 -M -Do > mycolor.cpt",shell=True)

# Plot
fig = pygmt.Figure()
with fig.subplot(nrows=3,ncols=2,autolabel="A+jTR+o0.6c/0.4c",subsize=("7c", "7c"),margins=['1c','0.5c']):
    with fig.set_panel(panel=0,fixedlabel="A: KN197"):
        # Load data
        mydata = xr.open_dataset("compiled/KN197_20100525-20100625.nc")
        # Replace 0 with NaN
        mydata = mydata.where(mydata['KD490_mean'] != 0.)
        # Grid data
        fig.grdimage(grid=mydata["KD490_mean"],cmap='mycolor.cpt',projection="M?",frame=True,region=coord)
        # Add land, shorelines
        fig.coast(resolution="f",shorelines=True,land="gray")
        # # Add colorbar
        # fig.colorbar(cmap='mycolor.cpt',frame=['x+lKD490','y+lm-1'])
        # Edit frame
        fig.basemap(frame=["afg"])
    with fig.set_panel(panel=1,fixedlabel="B: MV1110"):
        # Load data
        mydata = xr.open_dataset("compiled/MV1110_20110906-20111007.nc")
        # Replace 0 with NaN
        mydata = mydata.where(mydata['KD490_mean'] != 0.)
        # Grid data
        fig.grdimage(grid=mydata["KD490_mean"],cmap='mycolor.cpt',projection="M?",frame=True,region=coord)
        # Add land, shorelines
        fig.coast(resolution="f",shorelines=True,land="gray")
        # # Add colorbar
        # fig.colorbar(cmap='mycolor.cpt',frame=['x+lKD490','y+lm-1'])
        # Edit frame
        fig.basemap(frame=["afg"])
    with fig.set_panel(panel=2,fixedlabel="C: AT21-04"):
        # Load data
        mydata = xr.open_dataset("compiled/AT21-04_20120711-20120726.nc")
        # Replace 0 with NaN
        mydata = mydata.where(mydata['KD490_mean'] != 0.)
        # Grid data
        fig.grdimage(grid=mydata["KD490_mean"],cmap='mycolor.cpt',projection="M?",frame=True,region=coord)
        # Add land, shorelines
        fig.coast(resolution="f",shorelines=True,land="gray")
        # # Add colorbar
        # fig.colorbar(cmap='mycolor.cpt',frame=['x+lKD490','y+lm-1'])
        # Edit frame
        fig.basemap(frame=["afg"])
    with fig.set_panel(panel=3,fixedlabel="D: EN614"):
        # Load data
        mydata = xr.open_dataset("compiled/EN614_20180501-20180531.nc")
        # Replace 0 with NaN
        mydata = mydata.where(mydata['KD490_mean'] != 0.)
        # Grid data
        fig.grdimage(grid=mydata["KD490_mean"],cmap='mycolor.cpt',projection="M?",frame=True,region=coord)
        # Add land, shorelines
        fig.coast(resolution="f",shorelines=True,land="gray")
        # # Add colorbar
        # fig.colorbar(cmap='mycolor.cpt',frame=['x+lKD490','y+lm-1'])
        # Edit frame
        fig.basemap(frame=["afg"])
    with fig.set_panel(panel=4,fixedlabel="E: EN640"):
        # Load data
        mydata = xr.open_dataset("compiled/EN640_20190610-20190711.nc")
        # Replace 0 with NaN
        mydata = mydata.where(mydata['KD490_mean'] != 0.)
        # Grid data
        fig.grdimage(grid=mydata["KD490_mean"],cmap='mycolor.cpt',projection="M?",frame=True,region=coord)
        # Add land, shorelines
        fig.coast(resolution="f",shorelines=True,land="gray")
        # # Add colorbar
        # fig.colorbar(cmap='mycolor.cpt',frame=['x+lKD490','y+lm-1'])
        # Edit frame
        fig.basemap(frame=["afg"])
    with fig.set_panel(panel=5,fixedlabel="F: M174"):
        # Load data
        mydata = xr.open_dataset("compiled/M174_20210423-20210516.nc")
        # Replace 0 with NaN
        mydata = mydata.where(mydata['KD490_mean'] != 0.)
        # Grid data
        fig.grdimage(grid=mydata["KD490_mean"],cmap='mycolor.cpt',projection="M?",frame=True,region=coord)
        # Add land, shorelines
        fig.coast(resolution="f",shorelines=True,land="gray")
        # # Add colorbar
        # fig.colorbar(cmap='mycolor.cpt',frame=['x+lKD490','y+lm-1'])
        # Add colorbar
        fig.colorbar(cmap='mycolor.cpt',frame=['x','y+lm-1'],position="JBC+o-5c/1c+w150%/4%+h")
        # Edit frame
        fig.basemap(frame=["afg"])

# Save figures
fig.savefig(name,crop=False)
