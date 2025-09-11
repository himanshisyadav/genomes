#!/bin/bash
#SBATCH --job-name=star_map_array
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=32
#SBATCH --mem=48gb
#SBATCH --output=./SLURM_logs/star_map_%A_%a.out
#SBATCH --error=./SLURM_logs/star_map_%A_%a.err
#SBATCH --account=rcc-staff
##SBATCH --mail-type=END
##SBATCH --mail-user=hyadav@rcc.uchicago.edu

module load apptainer/1.4.1

# Print SLURM job information
echo "=========================================="
echo "SLURM Array Job Information"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Array Job ID: $SLURM_ARRAY_JOB_ID"
echo "Array Task ID: $SLURM_ARRAY_TASK_ID"
echo "Job Name: $SLURM_JOB_NAME"
echo "Node List: $SLURM_JOB_NODELIST"
echo "CPUs per Task: $SLURM_CPUS_PER_TASK"
echo "Memory per Node: $SLURM_MEM_PER_NODE"
echo "Partition: $SLURM_JOB_PARTITION"
JOB_TIME_LIMIT=$(squeue -j $SLURM_JOB_ID -h --Format TimeLimit 2>/dev/null || echo "Unknown")
echo "Time Limit: $JOB_TIME_LIMIT"
echo "Working Directory: $SLURM_SUBMIT_DIR"
echo "Start Time: $(date)"
echo "=========================================="
echo ""

# Verify this is running as an array job
if [ -z "$SLURM_ARRAY_TASK_ID" ]; then
    echo "ERROR: This script must be submitted as an array job!"
    echo "Use: sbatch --array=1-N star_map_array.slurm"
    echo "Or use the discovery submission script."
    exit 1
fi

# Set variables
HOST_PROJECT_DIR="/project/rcc/hyadav/genomes"
CONTAINER_PROJECT_DIR="/workspace"

IMAGE_PATH="$HOST_PROJECT_DIR/software/STAR.sif"

HOST_FASTQ_DIR="$HOST_PROJECT_DIR/transcript_data/fastqs"
CONTAINER_FASTQ_DIR="$CONTAINER_PROJECT_DIR/transcript_data/fastqs"

STAR_FILE="$CONTAINER_PROJECT_DIR/reference/Scer_genome.star"

BIND_MOUNTS="/home:/home,/scratch:/scratch,$HOST_PROJECT_DIR:$CONTAINER_PROJECT_DIR"

# Check if sample list file exists
SAMPLE_LIST_FILE="sample_list.txt"
if [ ! -f "$SAMPLE_LIST_FILE" ]; then
    echo "ERROR: Sample list file '$SAMPLE_LIST_FILE' not found!"
    echo "This file should be created by the discovery job."
    echo "Current directory contents:"
    ls -la
    exit 1
fi

# Debug: Show sample list info
echo "Sample list file: $SAMPLE_LIST_FILE"
echo "Total samples in list: $(wc -l < $SAMPLE_LIST_FILE)"
echo "Array Task ID: $SLURM_ARRAY_TASK_ID"

# Get the sample name for this array task
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST_FILE")

# Clean any whitespace
SAMPLE=$(echo "$SAMPLE" | xargs)

echo "Raw sample extracted: '$SAMPLE'"

if [ -z "$SAMPLE" ]; then
    echo "ERROR: No sample found for array task ID $SLURM_ARRAY_TASK_ID"
    echo "Available array indices: 1 to $(wc -l < $SAMPLE_LIST_FILE)"
    echo "Sample list contents:"
    cat -n "$SAMPLE_LIST_FILE"
    exit 1
fi

echo "Processing sample: $SAMPLE (Array Task $SLURM_ARRAY_TASK_ID)"

# Check if FASTQ files exist for this sample
FASTQ1="$HOST_FASTQ_DIR/${SAMPLE}_pass_1.fastq.gz"
FASTQ2="$HOST_FASTQ_DIR/${SAMPLE}_pass_2.fastq.gz"

echo "Looking for FASTQ files:"
echo "  Read 1: $FASTQ1"
echo "  Read 2: $FASTQ2"

if [ ! -f "$FASTQ1" ]; then
    echo "ERROR: Read 1 file not found: $FASTQ1"
    exit 1
fi

if [ ! -f "$FASTQ2" ]; then
    echo "ERROR: Read 2 file not found: $FASTQ2"
    exit 1
fi

echo "✓ Both FASTQ files found for sample $SAMPLE"

# Set container paths for FASTQ files
FASTQ_FILES_CONTAINER="$CONTAINER_FASTQ_DIR/${SAMPLE}_pass_1.fastq.gz $CONTAINER_FASTQ_DIR/${SAMPLE}_pass_2.fastq.gz"

# Create output directory if it doesn't exist
HOST_OUTPUT_DIR="$HOST_PROJECT_DIR/transcript_data/bams"
mkdir -p "$HOST_OUTPUT_DIR"

# Create scratch directory for this sample
SCRATCH_DIR="/scratch/midway3/hyadav/STAR_tmp/STAR_${SAMPLE}_${SLURM_ARRAY_TASK_ID}"

if [ -d "$SCRATCH_DIR" ]; then
    echo "Cleaning up existing directory: $SCRATCH_DIR"
    rm -rf "$SCRATCH_DIR"
fi

# Verify STAR index exists
echo "Checking STAR index: $STAR_FILE"
if [ ! -d "$HOST_PROJECT_DIR/reference/Scer_genome.star" ]; then
    echo "ERROR: STAR index directory not found: $HOST_PROJECT_DIR/reference/Scer_genome.star"
    exit 1
fi

# Verify container image exists
echo "Checking container image: $IMAGE_PATH"
if [ ! -f "$IMAGE_PATH" ]; then
    echo "ERROR: Container image not found: $IMAGE_PATH"
    exit 1
fi

echo ""
echo "=========================================="
echo "Starting STAR mapping for sample: $SAMPLE"
echo "=========================================="
echo "Input files:"
echo "  Read 1: $FASTQ1"
echo "  Read 2: $FASTQ2"
echo "Output prefix: $CONTAINER_PROJECT_DIR/transcript_data/bams/${SAMPLE}_"
echo "Scratch directory: $SCRATCH_DIR"
echo "Threads: $SLURM_CPUS_PER_TASK"
echo "Container image: $IMAGE_PATH"
echo "STAR index: $STAR_FILE"
echo "=========================================="
echo ""

# Run STAR mapping with apptainer
echo "Executing STAR command..."
apptainer exec --bind $BIND_MOUNTS $IMAGE_PATH \
    STAR --runThreadN $SLURM_CPUS_PER_TASK \
        --genomeDir $STAR_FILE \
        --readFilesIn $FASTQ_FILES_CONTAINER \
        --readFilesCommand zcat \
        --outFileNamePrefix $CONTAINER_PROJECT_DIR/transcript_data/bams/${SAMPLE}_ \
        --outTmpDir $SCRATCH_DIR \
        --outSAMstrandField intronMotif \
        --limitBAMsortRAM 89519393895 \
        --outSAMtype BAM SortedByCoordinate

# Check if STAR completed successfully
STAR_EXIT_CODE=$?
echo ""
echo "=========================================="
if [ $STAR_EXIT_CODE -eq 0 ]; then
    echo "✓ STAR completed successfully for sample: $SAMPLE"
    
    # List output files
    echo "Output files created:"
    ls -lh "$HOST_OUTPUT_DIR"/${SAMPLE}_*
    
    # Clean up scratch directory
    echo "Cleaning up scratch directory: $SCRATCH_DIR"
    rm -rf "$SCRATCH_DIR"
    
    echo "Sample $SAMPLE processing completed successfully!"
    
else
    echo "✗ ERROR: STAR failed for sample: $SAMPLE (Exit code: $STAR_EXIT_CODE)"
    echo "Scratch directory preserved for debugging: $SCRATCH_DIR"
    echo "Check STAR log files in the output directory."
    exit $STAR_EXIT_CODE
fi

echo "=========================================="
echo "Array task $SLURM_ARRAY_TASK_ID completed at: $(date)"
echo "Sample: $SAMPLE"
echo "=========================================="