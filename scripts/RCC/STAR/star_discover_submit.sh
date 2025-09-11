#!/bin/bash
#SBATCH --job-name=star_discover_submit
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=0:10:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=1gb
#SBATCH --output=./SLURM_logs/star_discover_%j.out
#SBATCH --error=./SLURM_logs/star_discover_%j.err
#SBATCH --account=rcc-staff

echo "=========================================="
echo "SLURM Discovery Job"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Start Time: $(date)"
echo "=========================================="

# Set paths
HOST_PROJECT_DIR="/project/rcc/hyadav/genomes"
HOST_FASTQ_DIR="$HOST_PROJECT_DIR/transcript_data/fastqs"

# Check if FASTQ directory exists
if [ ! -d "$HOST_FASTQ_DIR" ]; then
    echo "Error: FASTQ directory $HOST_FASTQ_DIR does not exist!"
    exit 1
fi

echo "Discovering samples in: $HOST_FASTQ_DIR"

# Create sample list by finding unique sample names from _pass_1.fastq.gz files
SAMPLE_LIST_FILE="sample_list.txt"
ls "$HOST_FASTQ_DIR"/*_pass_1.fastq.gz 2>/dev/null | sed 's|.*/||; s/_pass_1\.fastq\.gz$//' | sort > "$SAMPLE_LIST_FILE"

# Check if any samples were found
if [ ! -s "$SAMPLE_LIST_FILE" ]; then
    echo "Error: No FASTQ files matching pattern *_pass_1.fastq.gz found in $HOST_FASTQ_DIR"
    echo "Available files:"
    ls -la "$HOST_FASTQ_DIR"
    exit 1
fi

# Count the number of samples
NUM_SAMPLES=$(wc -l < "$SAMPLE_LIST_FILE")

echo "Found $NUM_SAMPLES samples:"
cat "$SAMPLE_LIST_FILE"

# Verify that paired files exist for each sample
echo ""
echo "Verifying paired FASTQ files..."
MISSING_FILES=0
while read SAMPLE; do
    FASTQ1="$HOST_FASTQ_DIR/${SAMPLE}_pass_1.fastq.gz"
    FASTQ2="$HOST_FASTQ_DIR/${SAMPLE}_pass_2.fastq.gz"
    
    if [ ! -f "$FASTQ1" ]; then
        echo "Missing: $FASTQ1"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
    
    if [ ! -f "$FASTQ2" ]; then
        echo "Missing: $FASTQ2"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
    
    if [ -f "$FASTQ1" ] && [ -f "$FASTQ2" ]; then
        echo "✓ $SAMPLE: Found both paired files"
    fi
done < "$SAMPLE_LIST_FILE"

if [ $MISSING_FILES -gt 0 ]; then
    echo ""
    echo "Error: $MISSING_FILES FASTQ files are missing. Cannot proceed."
    exit 1
fi

echo ""
echo "All paired FASTQ files verified successfully!"

# Create SLURM logs directory if it doesn't exist
mkdir -p ./SLURM_logs

# Submit the array job with dynamic range
echo ""
echo "Submitting STAR array job for $NUM_SAMPLES samples..."
echo "Array range: 1-$NUM_SAMPLES"

# Submit the dependent array job
ARRAY_JOB_ID=$(sbatch --dependency=afterok:${SLURM_JOB_ID} --array=1-${NUM_SAMPLES} --parsable star_map_array.sh)
6
if [ $? -eq 0 ]; then
    echo "Array job submitted successfully!"
    echo "Array Job ID: $ARRAY_JOB_ID"
    echo "Discovery Job ID: $SLURM_JOB_ID"
    echo ""
    echo "Monitor your jobs with:"
    echo "  squeue -u \$USER"
    echo ""
    echo "Array job will start after this discovery job completes."
    echo "Check logs in ./SLURM_logs/ directory"
    echo "Sample list saved as: $SAMPLE_LIST_FILE"
else
    echo "Error: Failed to submit array job"
    exit 1
fi

echo "Discovery job completed at: $(date)"