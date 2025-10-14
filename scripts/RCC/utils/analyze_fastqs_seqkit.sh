#!/bin/bash

module load python/miniforge-25.3.0
source activate seqkit_env

FASTQ_DIR="/project/rcc/hyadav/genomes/transcript_data/fastqs"
OUTPUT_FILE="/project/rcc/hyadav/genomes/transcript_data/fastqs/fastq_summary.txt"

seqkit stats -a -j 4 "$FASTQ_DIR"/*.fastq.gz > $OUTPUT_FILE