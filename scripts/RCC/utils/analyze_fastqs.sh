#!/bin/bash

# Output file
output="yeast_fastq_comparison.txt"

# Print header to file
echo -e "File\tSize_MB\tReads_Million\tAvg_Length\tIntensity" > "$output"

FASTQ_DIR="/project/rcc/hyadav/genomes/transcript_data/fastqs"

# Loop through each .fastq.gz file
for file in "$FASTQ_DIR"/*.fastq.gz; do
    size=$(du -m "$file" | cut -f1)
    reads=$(echo "scale=2; $(zcat "$file" | wc -l) / 4000000" | bc)
    length=$(zcat "$file" | head -n 40000 | awk 'NR%4==2{sum+=length($0); count++} END{print int(sum/count)}')

    # Simple intensity score (size + reads * 10)
    intensity=$(echo "$size + $reads * 10" | bc)

    # Output to txt file
    echo -e "$file\t$size\t$reads\t$length\t$intensity" >> "$output"
done

# (optional) Display the file with columns aligned
column -t "$output"