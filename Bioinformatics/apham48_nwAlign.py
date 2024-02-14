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
    for i in range(nx+1):
        M[i][0] = i*gap
    for j in range(ny+1):
        M[0][j] = j*gap

    ## Matrix filling
    for i in range(1,nx+1):
        for j in range(1,ny+1):
            M[i][j]=max(M[i-1][j-1]+C[i-1][j-1],M[i-1][j]+gap,M[i][j-1]+gap)

    ## Traceback:
    align_1 = ""
    align_2 = ""
    symbol = ""
    i = nx
    j = ny
    while (i > 0 and j > 0):
        if (i > 0 and j > 0 and M[i][j] == M[i-1][j-1]+C[i-1][j-1]):
            align_1 = x[i-1] + align_1
            align_2 = y[j-1] + align_2
            if C[i-1][j-1] == 1:
                symbol = "|" + symbol
            else:
                symbol = "*" + symbol
            i -= 1
            j -= 1
        elif (i > 0 and M[i][j] == M[i-1][j] + gap):
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
    print(f'Alignment scores: {M[nx][ny]}')

align(read_fasta(sys.argv[1]),read_fasta(sys.argv[2]))
# seq1 = "ATAGACGACATACAGACAGCATACAGACAGCATACAGA"
# seq2 = "TTTAGCATGCGCATATCAGCAATACAGACAGATACG"
# align(seq1,seq2)
