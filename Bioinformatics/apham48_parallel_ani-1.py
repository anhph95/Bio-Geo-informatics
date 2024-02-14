#!/usr/bin/env python3

# Import modules
import sys, os, argparse, glob, subprocess
from multiprocessing import Pool

# Argument input
parser = argparse.ArgumentParser()
parser.add_argument("-o", help="Output file", required=True)
parser.add_argument("-t", help="Number of threads", type=int,default=2)
parser.add_argument('files', help="input files",nargs='+')
args = parser.parse_args()

# Function to remove files
def rm(pattern):
	f = glob.glob(pattern)
	for i in f:
		os.remove(i)

# Function to computes ANI
def anical(file1,file2):
	prefix = os.path.splitext(file1)[0] + os.path.splitext(file2)[0]
	subprocess.run(['dnadiff','-p',prefix,file1,file2])
	# Get ANI value from out file
	outname = prefix + '.report'
	ani = subprocess.check_output(['awk','NR==19 {print $3}',outname],universal_newlines=True).strip()
	# Cleaning up
	wildcard = prefix + '.*'
	rm(wildcard)
	return ani

# Create file pairs from input files
filenames = [(a,b) for idx, a in enumerate(args.files) for b in args.files[idx + 1:]]

# Multiprocessing
pool = Pool(args.t)
result = pool.starmap(anical, filenames)
pool.close()
pool.join()

# Matrix filling
n = len(args.files)
M = [[0 for j in range(n+1)] for i in range(n+1)]
for i in range(1,n+1):
	M[i][0] = args.files[i-1]
	M[0][i] = args.files[i-1]
	M[i][i] = 100

k=0
for i in range(1,n+1):
	for j in range(1,n+1):
		if M[i][j] == 0:
			M[i][j] = result[k]
			M[j][i] = result[k]
			k += 1	

# Save output:
print('Generating output file...')
with open(args.o,'w') as outf:
	for row in M:
		outf.write('\t'.join(map(str,(row))))
		outf.write('\n')

print('----DONE----')
