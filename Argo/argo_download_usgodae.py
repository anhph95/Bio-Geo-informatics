#!/usr/bin/env python3
## Script to download BGC-ARGO float data
## First make script executable: chmod u+x argo_download.py
## Run ./argo_download.py --help for usage

# Import packages
#from unittest.mock import NonCallableMagicMock
import numpy as np
import pandas as pd
import xarray as xr
import matplotlib.pyplot as plt
import os
from mpl_toolkits.basemap import Basemap
from datetime import datetime
import requests, time, os, urllib3, shutil, argparse

# Argument Input
parser = argparse.ArgumentParser()
parser.add_argument("--float", help="WMOID number/list", nargs='+', type=int, default=None)
parser.add_argument("--lat", help="Latitude range: lower upper (within -90 to 90)", nargs=2, type=int, default=None)
parser.add_argument("--lon", help="Longitude range: lower upper (within either -180 to 180 or 0 to 360)", nargs=2, type=int, default=None)
parser.add_argument('--start', help="Start date: datetime object", type=lambda d: datetime.strptime(d, '%Y%m%d'), default=None)
parser.add_argument('--end', help="End date: datetime object", type=lambda d: datetime.strptime(d, '%Y%m%d'), default=None)
parser.add_argument("--sensor", help="Specify required sensors: PRES, TEMP, PSAL, DOXY, CHLA, BBP700, PH_IN_SITU_TOTAL, and NITRATE", nargs='+',default=None)
parser.add_argument("--folder",help="File download folder",default="temp")
parser.add_argument("--export", help="Export .nc files to .csv files", default=False, action="store_true")
parser.add_argument("--plot", help="Plotting trajectories", default=False, action="store_true")
parser.add_argument("--overwrite", help="Overwrite existing files", default=False, action="store_true")
parser.add_argument("--skip",help="Return list of file names, skip download",default=False,action="store_true")
args = parser.parse_args()

# Root path
root = os.getcwd()+'/'

if args.folder not in os.listdir(root):
   print(f"Creating folder {args.folder}/")
   os.makedirs(args.folder)
else:
  print(f"Saving files in {args.folder}/")

profile_dir = args.folder+"/"


# Function to download a single file
def download_file(url_path,filename,save_to=None,overwrite=False,verbose=True):
    """ Downloads and saves a file from a given URL using HTTP protocol.
    Note: If '404 file not found' error returned, function will return without downloading anything.
    Arguments:
        url_path: root URL to download from including trailing slash ('/')
        filename: filename to download including suffix
        save_to: None (to download to root Google Drive GO-BGC directory)
                 or directory path
        overwrite: False to leave existing files in place
                   or True to overwrite existing files
        verbose: True to announce progress
                 or False to stay silent
    """
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    if save_to is None:
      save_to = profile_dir

    try:
      if filename in os.listdir(save_to):
          if not overwrite:
              if verbose: print('>>> File ' + filename + ' already exists. Leaving current version.')
              return
          else:
              if verbose: print('>>> File ' + filename + ' already exists. Overwriting with new version.')

      def get_func(url,stream=True):
          try:
              return requests.get(url,stream=stream,auth=None,verify=False)
          except requests.exceptions.ConnectionError as error_tag:
              print('Error connecting:',error_tag)
              time.sleep(1)
              return get_func(url,stream=stream)

      response = get_func(url_path + filename,stream=True)

      if response.status_code == 404:
          if verbose: print('>>> File ' + filename + ' returned 404 error during download.')
          return
      with open(save_to + filename,'wb') as out_file:
          shutil.copyfileobj(response.raw,out_file)
      del response
      if verbose: print('>>> Successfully downloaded ' + filename + '.')

    except:
      if verbose: print('>>> An error occurred while trying to download ' + filename + '.')

# Function to download and parse GDAC synthetic profile index file
def argo_gdac(lat_range=None,lon_range=None,start_date=None,end_date=None,sensors=None,floats=None,
              overwrite_index=False,overwrite_profiles=False,skip_download=False,
              download_individual_profs=False,save_to=None,verbose=True):
  """ Downloads GDAC Sprof index file, then selects float profiles based on criteria.
      Either returns information on profiles and floats (if skip_download=True) or downloads them (if False).
      Arguments:
          lat_range: None, to select all latitudes
                     or [lower, upper] within -90 to 90 (selection is inclusive)
          lon_range: None, to select all longitudes
                     or [lower, upper] within either -180 to 180 or 0 to 360 (selection is inclusive)
                     NOTE: longitude range is allowed to cross -180/180 or 0/360
          start_date: None or datetime object
          end_date:   None or datetime object
          sensors: None, to select profiles with any combination of sensors
                   or string or list of strings to specify required sensors
                   > note that common options include PRES, TEMP, PSAL, DOXY, CHLA, BBP700,
                                                      PH_IN_SITU_TOTAL, and NITRATE
          floats: None, to select any floats matching other criteria
                  or int or list of ints specifying floats' WMOID numbers
          overwrite_index: False to keep existing downloaded GDAC index file, or True to download new index
          overwrite_profiles: False to keep existing downloaded profile files, or True to download new files
          skip_download: True to skip download and return: (<list of WMOIDs>, <DataFrame of index file subset>,
                                                            <list of downloaded filenames [if applicable]>)
                         or False to download those profiles
          download_individual_profs: False to download single Sprof file containing all profiles for each float
                                     or True to download individual profile files for each float
          save_to: None to download to Google Drive "/GO-BGC Workshop/Profiles" directory
                   or string to specify directory path for profile downloads
          verbose: True to announce progress, or False to stay silent
  """
  # Paths
  url_root = 'https://www.usgodae.org/ftp/outgoing/argo/'
  dac_url_root = url_root + 'dac/'
  index_filename = 'argo_synthetic-profile_index.txt'
  if save_to is None: save_to = profile_dir

  # Download GDAC synthetic profile index file
  download_file(url_root,index_filename,overwrite=overwrite_index)

  # Load index file into Pandas DataFrame
  gdac_index = pd.read_csv(profile_dir + index_filename,delimiter=',',header=8,parse_dates=['date','date_update'],
                          date_parser=lambda x: pd.to_datetime(x,format='%Y%m%d%H%M%S'))

  # Establish time and space criteria
  if lat_range is None:  lat_range = [-90.0,90.0]
  if lon_range is None:  lon_range = [-180.0,180.0]
  elif lon_range[0] > 180 or lon_range[1] > 180:
    if lon_range[0] > 180: lon_range[0] -= 360
    if lon_range[1] > 180: lon_range[1] -= 360
  if start_date is None: start_date = datetime(1900,1,1)
  if end_date is None:   end_date = datetime(2200,1,1)

  float_wmoid_regexp = r'[a-z]*/[0-9]*/profiles/[A-Z]*([0-9]*)_[0-9]*[A-Z]*.nc'
  gdac_index['wmoid'] = gdac_index['file'].str.extract(float_wmoid_regexp).astype(int)
  filepath_main_regexp = '([a-z]*/[0-9]*/)profiles/[A-Z]*[0-9]*_[0-9]*[A-Z]*.nc'
  gdac_index['filepath_main'] = gdac_index['file'].str.extract(filepath_main_regexp)
  filepath_regexp = '([a-z]*/[0-9]*/profiles/)[A-Z]*[0-9]*_[0-9]*[A-Z]*.nc'
  gdac_index['filepath'] = gdac_index['file'].str.extract(filepath_regexp)
  filename_regexp = '[a-z]*/[0-9]*/profiles/([A-Z]*[0-9]*_[0-9]*[A-Z]*.nc)'
  gdac_index['filename'] = gdac_index['file'].str.extract(filename_regexp)

  # Subset profiles based on time and space criteria
  gdac_index_subset = gdac_index.loc[np.logical_and.reduce([gdac_index['latitude'] >= lat_range[0],
                                                            gdac_index['latitude'] <= lat_range[1],
                                                            gdac_index['date'] >= start_date,
                                                            gdac_index['date'] <= end_date]),:]
  if lon_range[1] >= lon_range[0]:    # range does not cross -180/180 or 0/360
    gdac_index_subset = gdac_index_subset.loc[np.logical_and(gdac_index_subset['longitude'] >= lon_range[0],
                                                             gdac_index_subset['longitude'] <= lon_range[1])]
  elif lon_range[1] < lon_range[0]:   # range crosses -180/180 or 0/360
    gdac_index_subset = gdac_index_subset.loc[np.logical_or(gdac_index_subset['longitude'] >= lon_range[0],
                                                            gdac_index_subset['longitude'] <= lon_range[1])]

  # If requested, subset profiles using float WMOID criteria
  if floats is not None:
    if type(floats) is not list: floats = [floats]
    gdac_index_subset = gdac_index_subset.loc[gdac_index_subset['wmoid'].isin(floats),:]

  # If requested, subset profiles using sensor criteria
  if sensors is not None:
    if type(sensors) is not list: sensors = [sensors]
    for sensor in sensors:
      gdac_index_subset = gdac_index_subset.loc[gdac_index_subset['parameters'].str.contains(sensor),:]

  # Examine subsetted profiles
  wmoids = gdac_index_subset['wmoid'].unique()
  wmoid_filepaths = gdac_index_subset['filepath_main'].unique()

  # Just return list of floats and DataFrame with subset of index file, or download each profile
  downloaded_filenames = []
  if not skip_download:
    if download_individual_profs:
      for p_idx in gdac_index_subset.index:
        download_file(dac_url_root + gdac_index_subset.loc[p_idx]['filepath'],
                      gdac_index_subset.loc[p_idx]['filename'],
                      save_to=save_to,overwrite=overwrite_profiles,verbose=verbose)
        downloaded_filenames.append(gdac_index_subset.loc[p_idx]['filename'])
    else:
      for f_idx, wmoid_filepath in enumerate(wmoid_filepaths):
        download_file(dac_url_root + wmoid_filepath,str(wmoids[f_idx]) + '_Sprof.nc',
                      save_to=save_to,overwrite=overwrite_profiles,verbose=verbose)
        downloaded_filenames.append(str(wmoids[f_idx]) + '_Sprof.nc')
    return wmoids, gdac_index_subset, downloaded_filenames
  else:
    return wmoids, gdac_index_subset, downloaded_filenames

# Download data
print('-----Downloading data-----')
wmoids, gdac_index, downloaded_filenames \
                   = argo_gdac(lat_range=args.lat,lon_range=args.lon,
                               start_date=args.start,end_date=args.end,
                               sensors=args.sensor,floats=args.float,
                               overwrite_index=args.overwrite,overwrite_profiles=args.overwrite,
                               skip_download=args.skip,download_individual_profs=False,
                               save_to=None,verbose=True)

if args.skip:
  print('Floats matching search criteria:')
  print(*wmoids, sep = "\n")

# Exporting data to csv files
if args.export == True:
  print('-----Exporting to csv files-----')
  for i in downloaded_filenames:
      # Open data
      data = xr.open_dataset(profile_dir + i)
      data = data.rename({'CYCLE_NUMBER':'PROF_NUM'}).swap_dims({'N_PROF':'PROF_NUM'})
      data_cycle = data.isel(N_PARAM=0) # Reduce replicated dimension
      df = data_cycle.to_dataframe()
      temp = i.replace('_Sprof.nc','')
      df.to_csv(f'{temp}.csv')
      os.system('sed -e "s/,b/,/g" -e "s/\'//g" {}.csv -i'.format(temp)) # Remove decoding characters
      print('>>> Successfully exported {}.csv'.format(temp))

# Plotting float trajectories
if args.plot == True:
  print('-----Plotting trajectories-----')
  # Set up base map
  m = Basemap(projection='merc',llcrnrlat=args.lat[0]-10,urcrnrlat=args.lat[1]+10,llcrnrlon=args.lon[0]-10,urcrnrlon=args.lon[1]+10,lat_ts=10,resolution=None)
  # llcrnrlat,llcrnrlon,urcrnrlat,urcrnrlon
  # are the lat/lon values of the lower left and upper right corners
  # of the map.
  # lat_ts is the latitude of true scale.
  # resolution = 'c' means use crude resolution coastlines.
  m.shadedrelief()
  #m.etopo()
  m.drawmeridians(np.arange(0,360,10))
  m.drawparallels(np.arange(-90,90,10))
  for i in downloaded_filenames:
      data = xr.open_dataset(profile_dir + i)
      data.rename({'CYCLE_NUMBER':'PROF_NUM'}).swap_dims({'N_PROF':'PROF_NUM'})
      x, y = m(data['LONGITUDE'], data['LATITUDE'])
      date1 = pd.to_datetime(data['JULD'],format='%Y%m%d').min().date()
      date2 = pd.to_datetime(data['JULD'],format='%Y%m%d').max().date()
      temp = i.replace('_Sprof.nc','')
      m.plot(x,y,marker='.',label=f'{temp} ({date1} - {date2})')
      m.plot(x[0],y[0],marker='o')
  plt.legend(loc='upper right')
  plt.show()

print('-----Done-----')