#!/usr/bin/env python3
import sys

# Function to read nth column from file
def read_col(file,col):
    list = []
    for j in ([i.rstrip().split('\t')[int(col)-1] for i in open(file,'r').readlines()]):
        list.append(j)
    return list

# Reading columns

file1_id = read_col(sys.argv[1],1)
file1_chr = read_col(sys.argv[1],2)
file1_start = read_col(sys.argv[1],4)
file1_stop = read_col(sys.argv[1],5)

file2_id = read_col(sys.argv[2],1)
file2_gene = read_col(sys.argv[2],5)

file3_gene = read_col(sys.argv[3],1)

# Convert columns to dictionaries
list1 = []
for a,b,c,d in zip(file1_id,file1_chr,file1_start,file1_stop):
    temp = {'id': a, 'chr': b, 'start': c, 'stop': d}
    list1.append(temp)

list2 = []
for a,b in zip(file2_id,file2_gene):
    temp = {'id': a, 'gene':b}
    list2.append(temp)

# Filter dictionary based on list of values
list2_filter = []
id = []
for i in list2:
    if i['gene'] in file3_gene:
        list2_filter.append(i)
        id.append(i['id'])

list1_filter = []
for i in list1:
    if i['id'] in id:
        list1_filter.append(i)

# Combine 2 lists of dictionaries
list_combine = []
for i,j in zip(list1_filter,list2_filter):
    temp = {**j,**i} # values from i replace those from j
    list_combine.append(temp)

# Find unique value based on 'gene'
list_unique = list({i['gene']:i for i in list_combine}.values())

# Sort list based on 'gene'
list_sorted = sorted(list_unique, key=lambda i:i['gene'])

# Print list of dictionaries
for i in list_sorted:
    print('{}\t{}\t{}\t{}'.format(i['gene'],i['chr'],i['start'],i['stop']))
