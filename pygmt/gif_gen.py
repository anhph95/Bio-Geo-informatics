#!/usr/bin/env python3

import glob
import imageio
import re

# Get list of file
filenames = glob.glob("temp/temp_*.png")
filenames.sort(key=lambda filenames : list(map(int, re.findall(r'\d+',filenames)))[0])

# images = []
# for filename in filenames:
#     images.append(imageio.v3.imread(filename))
# imageio.mimsave('M174_stn_31.gif', images, duration=1)
# # #
# # # For longer movies, use the streaming approach:
#
# import imageio
with imageio.get_writer('EN614_cruise_track_v0.gif', mode='I',duration=0.5, format='GIF-PIL') as writer:
    for filename in filenames:
        image = imageio.imread(filename,format='PNG-PIL',pilmode='RGBX')
        writer.append_data(image)
