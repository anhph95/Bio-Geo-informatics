#!/usr/bin/env python3

# Import modules
import sys

# Function to read fasta files
def read_fasta(file):
    seq = ""
    with open(file,'r') as f:
        for line in f:
            if line.startswith(">"):
                continue
            else:
                seq += line.rstrip()
    return seq

# Fuction to perform Needleman-Wunsch alignment
def align(x, y):
    # Setting up
    match = 1
    mismatch = -1
    gap = -1
    nx = len(x)
    ny = len(y)

    ## Initialization
    # Match/mismatch matrix
    C = [[0 for j in range(ny)] for i in range(nx)]
    for i in range(nx):
        for j in range(ny):
            if x[i] == y[j]:
                C[i][j] = match
            else:
                C[i][j] = mismatch

    # Score matrix
    M = [[0 for j in range(ny+1)] for i in range(nx+1)]

    ## Matrix filling
    for i in range(1,nx+1):
        for j in range(1,ny+1):
            M[i][j]=max(M[i-1][j-1]+C[i-1][j-1],M[i-1][j]+gap,M[i][j-1]+gap)
            if M[i][j] < 0:
                M[i][j] = 0

    ## Traceback:
    maxval = max([(max(i),M.index(i),i.index(max(i))) for i in M])
    i = maxval[1]
    j = maxval[2]
    align_1 = ""
    align_2 = ""
    symbol = ""
    while M[i][j] > 0:
        if M[i][j] == M[i-1][j-1]+C[i-1][j-1]:
            align_1 = x[i-1] + align_1
            align_2 = y[j-1] + align_2
            symbol = "|" + symbol
            i -= 1
            j -= 1
        elif M[i][j] == M[i-1][j] + gap:
            align_1 = x[i-1] + align_1
            align_2 = "-" + align_2
            symbol = " " + symbol
            i -= 1
        else:
            align_1 = "-" + align_1
            align_2 = y[j-1] + align_2
            symbol = " " + symbol
            j -= 1

    # Result output
    print(align_1)
    print(symbol)
    print(align_2)
    print(f'Alignment scores: {maxval[0]}')

align(read_fasta(sys.argv[1]),read_fasta(sys.argv[2]))
