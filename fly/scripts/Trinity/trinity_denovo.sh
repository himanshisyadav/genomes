#!/bin/bash
#SBATCH --job-name=trinity_denovo_fly
#SBATCH --partition=caslake
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=4:00:00
#SBATCH --cpus-per-task=48
#SBATCH --mem=128G
#SBATCH --output=./SLURM_logs/%x_%j.out
#SBATCH --error=./SLURM_logs/%x_%j.err
#SBATCH --account=rcc-staff
#SBATCH --mail-type=ALL
##SBATCH --exclusive

# Load required modules
module load apptainer/1.4.1

# Print SLURM job information
echo "=========================================="
echo "SLURM Job Information"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Job Name: $SLURM_JOB_NAME"
echo "Node List: $SLURM_JOB_NODELIST"
echo "Number of Nodes: $SLURM_JOB_NUM_NODES"
echo "Number of Tasks: $SLURM_NTASKS"
echo "CPUs per Task: $SLURM_CPUS_PER_TASK"
echo "Memory per Node: $SLURM_MEM_PER_NODE"
echo "Partition: $SLURM_JOB_PARTITION"
JOB_TIME_LIMIT=$(squeue -j $SLURM_JOB_ID -h --Format TimeLimit)
echo "Time Limit: $JOB_TIME_LIMIT"
echo "Working Directory: $SLURM_SUBMIT_DIR"
echo "Start Time: $(date)"
echo "=========================================="
echo ""

# Parse memory to GB in the format "{integer}G" for Trinity
mem_gb=$(echo "scale=0; $SLURM_MEM_PER_NODE / 1024" | bc)
max_memory_arg="${mem_gb}G"
echo "Calculated max_memory argument: $max_memory_arg"
echo ""

# Set variables
HOST_PROJECT_DIR="/project/rcc/hyadav/genomes"
CONTAINER_PROJECT_DIR="/workspace"

IMAGE_PATH="$HOST_PROJECT_DIR/software/trinityrnaseq.v2.15.2.simg"

# HOST_FASTQ_DIR="$HOST_PROJECT_DIR/transcript_data/fastqs"
HOST_FASTQ_DIR="/scratch/midway3/hyadav/fly/Mab_RNA_seq_fastas"
CONTAINER_FASTQ_DIR="/scratch/midway3/hyadav/fly/Mab_RNA_seq_fastas"

# HOST_OUTPUT_DIR="$HOST_PROJECT_DIR/transcript_data/trinity_denovo"
HOST_OUTPUT_DIR="/scratch/midway3/hyadav/fly/Trinity/output"
CONTAINER_OUTPUT_DIR="/scratch/midway3/hyadav/fly/Trinity/output"

# Optional: Set bind mounts
BIND_MOUNTS="/home:/home,/scratch:/scratch,$HOST_FASTQ_DIR:$CONTAINER_FASTQ_DIR,$HOST_PROJECT_DIR:$CONTAINER_PROJECT_DIR,$HOST_OUTPUT_DIR:$CONTAINER_OUTPUT_DIR"

# Output samples file
SAMPLES_FILE="$HOST_FASTQ_DIR/samples.txt"

# Debug: Check if directory exists and list files
echo "Checking FASTQ directory: $HOST_FASTQ_DIR"
if [ -d "$HOST_FASTQ_DIR" ]; then
    echo "Directory exists. Contents:"
    ls -la "$HOST_FASTQ_DIR/"
    echo ""
else
    echo "Directory $HOST_FASTQ_DIR does not exist!"
    exit 1
fi

# Initialize empty file (no header)
> "$SAMPLES_FILE"

# Find all R1 files and extract sample info
# Handles both patterns: *_R1.fastq.gz and *_R1_001.fastq.gz
for R1 in "$HOST_FASTQ_DIR"/*_R1*.fastq.gz; do
    # Check if file exists (in case no matches)
    [ -e "$R1" ] || continue
    
    # Get corresponding R2 file
    # Handle both patterns
    if [[ "$R1" == *"_R1_001.fastq.gz" ]]; then
        R2="${R1/_R1_001.fastq.gz/_R2_001.fastq.gz}"
    else
        R2="${R1/_R1.fastq.gz/_R2.fastq.gz}"
    fi
    
    # Check if R2 exists
    if [ ! -f "$R2" ]; then
        echo "Warning: R2 file not found for $R1, skipping..."
        continue
    fi
    
    # Extract sample name
    basename=$(basename "$R1")
    
    # Remove file extension patterns
    if [[ "$basename" == *"_R1_001.fastq.gz" ]]; then
        basename_clean=$(echo "$basename" | sed 's/_R1_001.fastq.gz$//')
    else
        basename_clean=$(echo "$basename" | sed 's/_R1.fastq.gz$//')
    fi
    
    # Column 1: Everything before first underscore
    sample_name=$(echo "$basename_clean" | cut -d'_' -f1)
    
    # Column 2: Everything after first underscore to the end
    rep_name=$(echo "$basename_clean" | cut -d'_' -f2-)
    
    # Get paths (use container paths)
    R1_path=$(echo "$R1" | sed "s|$HOST_FASTQ_DIR|$CONTAINER_FASTQ_DIR|g")
    R2_path=$(echo "$R2" | sed "s|$HOST_FASTQ_DIR|$CONTAINER_FASTQ_DIR|g")
    
    # Write to file
    echo -e "${sample_name}\t${rep_name}\t${R1_path}\t${R2_path}"
done >> "$SAMPLES_FILE"

# Run Trinity with apptainer
echo "Starting Trinity assembly..."

echo "Using image: $IMAGE_PATH"

apptainer exec \
    --bind $BIND_MOUNTS \
    $IMAGE_PATH \
        Trinity \
            --seqType fq \
            --max_memory $max_memory_arg \
            --samples_file $SAMPLES_FILE \
            --CPU $SLURM_CPUS_PER_TASK \
            --normalize_by_read_set \
            --min_kmer_cov 2 \
            --monitoring \
            --no_run_inchworm 
