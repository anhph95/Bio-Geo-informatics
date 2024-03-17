#!/usr/bin/env python3

import cartopy.crs as ccrs
import cartopy.feature as cfeature
from cartopy.mpl.ticker import LongitudeFormatter, LatitudeFormatter
import matplotlib.pyplot as plt
import numpy as np


import copernicusmarine
# Load xarray dataset
print('Loading data')
phy = copernicusmarine.open_dataset(
    dataset_id = "cmems_obs-sl_glo_phy-ssh_nrt_allsat-l4-duacs-0.25deg_P1D",
    start_datetime = '2022-01-01',
    end_datetime = '2022-12-31',
)


for i in range(0,365):
    print(f'Plotting {i}')
    subdata = phy.adt.isel(time=i)
    fig, ax = plt.subplots(figsize=(10,10),subplot_kw=dict(projection=ccrs.Robinson()))
    m = subdata.plot(ax=ax,cmap='jet',vmin=0,vmax=2,add_colorbar=False,transform=ccrs.PlateCarree())
    #quiver = plt.quiver(uo_subset.longitude, uo_subset.latitude, uo_subset, vo_subset, scale=50,transform=ccrs.PlateCarree())
    ax.coastlines()
    ax.add_feature(cfeature.LAND,facecolor='lightgray')
    gl = ax.gridlines(draw_labels=True, dms=True, x_inline=False, y_inline=False,color='black',linestyle='--',alpha=0.5)
    gl.xlabel_style = {'size': 12}  # Adjust x-axis gridline label size and color
    gl.ylabel_style = {'size': 12}  # Adjust y-axis gridline label size and color
    ax.set_title('')

    ax.set_xlabel('Longitude',size=12)
    ax.set_ylabel('Latitude',size=12)
    cbar = fig.colorbar(m, ax=ax, orientation='horizontal', pad=0.05,shrink=0.5)
    #cbar.set_ticks(np.linspace(0,4,5))
    mystr = subdata.time.dt.strftime('%m/%d/%Y').item()
    cbar.set_label(f'Sea surface height above geoid (m) - {mystr}',size=12)
    cbar.ax.tick_params(labelsize=12)
    plt.savefig(f'sshplot/{i}.png')
    plt.close()