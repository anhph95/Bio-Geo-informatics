#!/usr/bin/env python3

# Import modules
import sys, re, argparse

# Argument input
parser = argparse.ArgumentParser()
parser.add_argument("-i", help="Input file name", required=True)
parser.add_argument("-f", metavar="FOLD",help="Number of bases per line")
args = parser.parse_args()

# FOLD
FOLD = 70
if args.f:
    FOLD = int(args.f)

# Function to wrap string
def wrap(line,n):
    start=0
    length=len(line)
    temp=[]
    while length - start >= n:
        temp.append(line[start:start+n])
        start += n
    temp.append(line[start:])
    line_wrapped = '\n'.join(temp)
    return(line_wrapped)

# DNA or PROTEIN
def type(seq):
    if re.search('[^ATGCNatgcn]',seq):
        end = 'faa'
    else:
        end = 'fna'
    return(end)

# FASTQ to FASTA
def fastq2fasta(file, filename):
    header=[]
    seq=[]
    line = file.readlines()
    for i in range(0,len(line)):
        if re.search('^@',line[i]):
            header.append(re.sub(pattern='@',string=line[i].rstrip(),repl=''))
            seq.append(line[i+1].rstrip())
    with open(f'{filename}.{type(seq[0])}','w') as out:
        print(f'Generating output file...')
        for i,j in zip(header,seq):
            out.write(f'>{i}\n{wrap(j,FOLD)}\n')

# EMBL to FASTA
def embl2fasta(file, filename):
    header=""
    seq=""
    line = file.readlines()
    for i in range(0,len(line)):
        if re.search('^ID',line[i]):
            header += re.sub(pattern='ID\s',string=line[i].rstrip(),repl='')
        elif re.search('^SQ',line[i]):
            j = i+1
            while re.search('^(?!//)',line[j]):
                seq += re.sub(pattern='\s|[0-9]',string=line[j].rstrip(),repl='')
                j += 1
    with open(f'{filename}.{type(seq)}','w') as out:
        print(f'Generating output file...')
        out.write(f'>{header}\n{wrap(seq,FOLD)}\n')

# GENEBANK to FASTA
def gb2fasta(file, filename):
    seq=""
    header=""
    line = file.readlines()
    for i in range(0,len(line)):
        if re.search('^ACCESSION',line[i]):
            header += re.sub(pattern='ACCESSION|\s',string=line[i].rstrip(),repl='')
        elif re.search('^ORIGIN',line[i]):
            j = i+1
            while re.search('^(?!//)',line[j]):
                seq += re.sub(pattern='\s|[0-9]',string=line[j].rstrip(),repl='')
                j += 1
    with open(f'{filename}.{type(seq)}','w') as out:
        print(f'Generating output file...')
        out.write(f'>{header}\n{wrap(seq,FOLD)}\n')

# MEGA to FASTA
def mega2fasta(file, filename):
    seq=""
    header=""
    for line in file:
        if re.search('#(?!MEGA)',line):
            header += re.sub(pattern='#',string=line.rstrip(),repl='')
        if not line.startswith(('#','TITLE:')):
            seq += line.rstrip()
    with open(f'{filename}.{type(seq)}','w') as out:
        print(f'Generating output file...')
        out.write(f'>{header}\n{wrap(seq,FOLD)}\n')

# SAM to FASTA
def sam2fasta(file, filename):
    temp = {}
    for line in file:
        if not line.startswith('@'):
            cols = line.rstrip().split('\t')
            temp[cols[0]] = cols[9]
    with open(f'{filename}.{type(temp[cols[0]])}','w') as out:
        print(f'Generating output file...')
        for i in temp:
            out.write(f'>{i}\n{wrap(temp[i],FOLD)}\n')

# VCF to FASTA
def vcf2fasta(file,filename):
    temp = {}
    ref = ""
    for line in file:
        if line.startswith('#CHROM'):
            header = line.rstrip().split('\t')
            for i in range(len(header)-11,len(header)):
                temp[header[i]] = ""
        if not line.startswith('#'):
            cols = line.rstrip().split('\t')
            ref += cols[3]
            case = cols[4].split(',')
            for i in range(len(header)-11,len(header)):
                if cols[i][0] == 0:
                    temp[header[i]] += cols[3]
                else:
                    temp[header[i]] += case[int(cols[i][0])-1]
    with open(f'{filename}.{type(ref)}','w') as out:
        print(f'Generating output file...')
        out.write(f'>{cols[0]}\n{wrap(ref,FOLD)}\n')
        for i in temp:
            out.write(f'>{i}\n{wrap(temp[i],FOLD)}\n')

## Read input:
with open(args.i,'r') as f:
    firstline = f.readline()
    secondline = f.readline()
    f.seek(0)
    name = str(args.i).split('.')[0]
    if firstline.startswith('@') and not secondline.startswith('@'):
        fastq2fasta(f,name)
    elif firstline.startswith('@') and secondline.startswith('@'):
        sam2fasta(f,name)
    elif firstline.startswith(('ID','id')):
        embl2fasta(f,name)
    elif firstline.startswith(('LOCUS','locus')):
        gb2fasta(f,name)
    elif firstline.startswith(('#mega','#MEGA')):
        mega2fasta(f,name)
    elif firstline.startswith(('##fileformat','##FILEFORMAT')):
        vcf2fasta(f,name)
