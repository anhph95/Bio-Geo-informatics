#!/usr/bin/env python3
# Import modules
import argparse, subprocess, shlex, os, glob

# Argument input
parser = argparse.ArgumentParser()
parser.add_argument("-i1", help="First input file")
parser.add_argument("-i2", help="Second input file")
parser.add_argument("-o", help="Output file name")
parser.add_argument("-t", help="Sequence type (n/p)")
args = parser.parse_args()

# Blast type
if args.t == "n":
    blast = 'blastn'
elif args.t == "p":
    blast = 'blastp'
else:
    print('Invalid -t argument')
    quit()

# Function to run bash command
def run(cmd):
    subprocess.run(shlex.split(cmd))

# BLAST
run(f'makeblastdb -in {args.i1} -dbtype nucl')
run(f'makeblastdb -in {args.i2} -dbtype nucl')
run(f'{blast} -db {args.i1} -query {args.i2} -evalue 1e-5 -outfmt "6 qseqid sseqid bitscore evalue" -max_target_seqs 1 -out temp1.txt')
run(f'{blast} -db {args.i2} -query {args.i1} -evalue 1e-5 -outfmt "6 qseqid sseqid bitscore evalue" -max_target_seqs 1 -out temp2.txt')

# Read first output as initial hits
with open('temp1.txt') as f:
    hit = {}
    for line in f:
        cols = line.rstrip().split('\t')
        hit[cols[0]] = cols[1]

# Matching pairs
with open('temp2.txt') as f:
    ortho = {}
    for line in f:
        cols = line.rstrip().split('\t')
        if cols[1] in hit and hit[cols[1]] == cols[0]:
            ortho[cols[1]] = cols[0]

# Write output file
print('Writing output file...')
with open(args.o,'w') as f:
    for i in sorted(ortho.keys()):
        f.write(f'{i}\t{ortho[i]}\n')

# Write README
print('Generating README file...')
with open('apham48_README.txt', 'w') as f:
    f.write(f'Input sequence 1: {args.i1}\n')
    f.write(f'Input sequence 2: {args.i2}\n')
    f.write(f'Sequence type: {args.t}\n')
    f.write(f'Evalue set to 1e-5\n')
    f.write(f'Inital BLAST hits: {len(hit)}\n')
    f.write(f'Orthologs: {len(ortho)}\n')

# Function to remove files
def rm(pattern):
    f = glob.glob(pattern)
    for i in f:
        os.remove(i)

# Cleaning up
print('Cleaning up...')
rm(f'temp*')
rm(f'{args.i1}.*')
rm(f'{args.i2}.*')
