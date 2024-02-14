#!/usr/bin/env python3
import sys

file = open(sys.argv[2],'r')
l = file.readlines()
temp = []
k = int(sys.argv[1])

# Check input k
if k > len(l[1].split('\t')) or k == 0:
    print('Invalid k value')
    quit()
else:
    # Append kth colum of each line to list
    for i in l:
        temp.append(i.rstrip().split('\t')[k-1])

    # Print list as column
    for r in temp:
        print(r)
file.close()

# Using list comprehension
# import sys
# for k in ([i.rstrip().split('\t')[int(sys.argv[1])-1] for i in open(sys.argv[2]).readlines()]):
#     print(k)
