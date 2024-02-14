#!/usr/bin/env python3

# Import modules
import sys, re, argparse

# Argument input
parser = argparse.ArgumentParser()
parser.add_argument("-i", help="Input file name", required=True)
args = parser.parse_args()

# Extract data from file
data = []
with open(args.i,'r') as f:
    dict = {}
    for line in f:
        cols = line.rstrip().split('\t')
        data.append([cols[0], int(cols[1]), int(cols[2])])

# Function to extract last index of one set of chromosome
def extract(data, sub_start):
    sub_end = sub_start
    for i in range(sub_start,len(data)-1):
        if data[i][0][3:] != data[i+1][0][3:]:
            sub_end = i
            break
    if (sub_end == sub_start):
        sub_end = len(data)
    return sub_end

# Function to count overlapping elements
def count(data):
    # Create array of length maximum coordinate in one set of chromosome
    data_max = max(k[2] for k in data)
    A = [0 for i in range(data_max)]
    # Counting occurrence
    for i in data:
        for j in range(i[1],i[2]):
            A[j] += 1
    # Print output for occurrence that appears
    sub_start = 0
    sub_end = 0
    for i in range(len(A)-1):
        if A[i] != A[i+1]:
            sub_end = i
            if A[i] != 0:
                print(f'{data[0][0]}\t{sub_start}\t{sub_end+1}\t{A[i]}')
            sub_start = i + 1
    if A[len(A)-1] != 0:
        print(f'{data[0][0]}\t{sub_start}\t{len(A)}\t{A[len(A)-1]}')

# Running through all data
start = 0
while start < len(data):
    end = extract(data,start)
    subdata = data[start:end+1]
    count(subdata)
    start = end+1
