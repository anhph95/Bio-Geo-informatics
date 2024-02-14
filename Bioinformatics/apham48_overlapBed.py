#!/usr/bin/env python3

# Import modules
import sys, re, os, argparse

# Argument input
parser = argparse.ArgumentParser()
parser.add_argument("-i1", help="Input file 1", required=True)
parser.add_argument("-i2", help="Input file 2", required=True)
parser.add_argument("-m", help="Minimal overlap", required=True,type=int)
parser.add_argument("-o", help="Output file", required=True)
parser.add_argument("-j",help="Join the two entries",default=False,action="store_true")
args = parser.parse_args()


# Extract data from file
data1 = []
with open(args.i1,'r') as f:
    for line in f:
        cols = line.rstrip().split('\t')
        data1.append([cols[0], int(cols[1]), int(cols[2])])

data2 = []
with open(args.i2,'r') as f:
    for line in f:
        cols = line.rstrip().split('\t')
        data2.append([cols[0], int(cols[1]), int(cols[2])])

# Function to print intersect
def intersect(A,B,percent,join,outfile):
    index_a = 0
    index_b = 0
    list = []
    while index_a < len(A) and index_b < len(B):
        # Overlap when start2 <= end1 and start1 <= end2
        # s1----------e1        or      s1----------e1
        #       s2----------e2  or s2----------e2
        if B[index_b][1] <= A[index_a][2] and A[index_a][1] <= B[index_b][2]:
            # Calculate percent overlap
            overlap = (min(A[index_a][2],B[index_b][2])-max(A[index_a][1],B[index_b][1])+1)*100/(A[index_a][2]-A[index_a][1]+1)
            if overlap >= percent:
                if join == True:
                    outfile.write(f'{A[index_a][0]}\t{A[index_a][1]}\t{A[index_a][2]}\t{B[index_b][0]}\t{B[index_b][1]}\t{B[index_b][2]}\n')
                else:
                    outfile.write(f'{A[index_a][0]}\t{A[index_a][1]}\t{A[index_a][2]}\n')
        if A[index_a][2] > B[index_b][2]:
            index_b += 1
        else:
            index_a += 1

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

# Running through all data
start1 = 0
start2 = 0
with open(args.o,'w') as output:
    print('Finding overlaps...')
    while start1 < len(data1) and start2 < len(data2):
        end1 = extract(data1,start1)
        end2 = extract(data2,start2)
        subdata1 = data1[start1:end1+1]
        subdata2 = data2[start2:end2+1]
        intersect(subdata1,subdata2,args.m,args.j,output)
        start1 = end1+1
        start2 = end2+1


# Readme file
counter = 0
with open(args.o,'r') as f:
    for line in f:
        counter += 1
with open('apham48_README','w') as readme:
    print(f'Generating README file...')
    readme.write(f'First BED file is {args.i1}\n')
    readme.write(f'Second BED file is {args.i2}\n')
    readme.write(f'Minimal overlap set to {args.m}%\n')
    readme.write(f'Join option set to {args.j}\n')
    readme.write(f'Output file generated as {args.o}\n')
    readme.write(f'Output file contains {counter} lines\n')

print('DONE!')
