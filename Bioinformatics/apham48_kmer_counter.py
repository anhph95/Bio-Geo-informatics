#!/usr/bin/env python3
import sys, re

# Function to read fasta files
def read_fasta(read):
    seq = []
    with open(read,'r') as file:
        for line in file:
            if not re.search("^>",line):
                seq.append(line)
    # Join all line and strip whitespace characters
    seq = "".join(line.strip() for line in seq)
    return seq
    file.close()

# Function to count kmers
def kmer_counter(read, k):
    counts = {}
    # Number of kmer of length k in read
    n_kmer = len(read) - k + 1
    for i in range(n_kmer):
        # Get all kmers
        kmer = read[i:i+k]
        # Add new kmer to dictionary
        if kmer not in counts:
            counts[kmer] = 0
        # Counting the current kmer
        counts[kmer] += 1
    return counts

# Create dictionary of kmer and count
dict = kmer_counter(read_fasta(sys.argv[2]), int(sys.argv[1]))

# Sort and print keys and values
for i in sorted(dict):
     print("{}\t{}".format(i,dict[i]))
