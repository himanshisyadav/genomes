#!/bin/bash
#SBATCH --job-name=trinity_denovo
#SBATCH --partition=caslake
##SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=128gb
#SBATCH --output=./SLURM_logs/trinity_denovo_%j.out
#SBATCH --error=./SLURM_logs/trinity_denovo_%j.err
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

# Set variables
HOST_PROJECT_DIR="/project/rcc/hyadav/genomes"
CONTAINER_PROJECT_DIR="/workspace"

IMAGE_PATH="$HOST_PROJECT_DIR/software/trinityrnaseq.v2.15.2.simg"

# HOST_FASTQ_DIR="$HOST_PROJECT_DIR/transcript_data/fastqs"
HOST_FASTQ_DIR="/scratch/midway3/hyadav/fastqs"
CONTAINER_FASTQ_DIR="/trinity_input_fastqs"

# HOST_OUTPUT_DIR="$HOST_PROJECT_DIR/transcript_data/trinity_denovo"
HOST_OUTPUT_DIR="/scratch/midway3/hyadav/trinity_out_dir"
CONTAINER_OUTPUT_DIR="/trinity_output"

# Optional: Set bind mounts
BIND_MOUNTS="/home:/home,/scratch:/scratch,$HOST_FASTQ_DIR:$CONTAINER_FASTQ_DIR,$HOST_PROJECT_DIR:$CONTAINER_PROJECT_DIR,$HOST_OUTPUT_DIR:$CONTAINER_OUTPUT_DIR"

# Debug: Check if directory exists and list files
echo "Checking FASTQ directory: $FASTQ_DIR"
if [ -d "$HOST_FASTQ_DIR" ]; then
    echo "Directory exists. Contents:"
    ls -la $HOST_FASTQ_DIR/
    echo ""
    echo "Files matching *1* pattern:"
    ls $HOST_FASTQ_DIR/*1* 2>/dev/null || echo "No files found with *1* pattern"
    echo ""
    echo "Files matching *2* pattern:"
    ls $HOST_FASTQ_DIR/*2* 2>/dev/null || echo "No files found with *2* pattern"
    echo ""
else
    echo "Directory $HOST_FASTQ_DIR does not exist!"
    exit 1
fi

# Create comma-separated lists of fastq files from specific directory
# First check if files exist before creating lists
if ls $HOST_FASTQ_DIR/*1.fastq.gz 1> /dev/null 2>&1; then
    LEFT_FILES=$(ls $HOST_FASTQ_DIR/*1.fastq.gz | tr '\n' ',' | sed 's/,$//')
    echo "Left files found: $LEFT_FILES"
    # LEFT_FILES_CONTAINER=$(echo $LEFT_FILES | sed "s|$PROJECT_DIR|/workspace|g")
    LEFT_FILES_CONTAINER=$(echo "$LEFT_FILES" | sed "s|$HOST_FASTQ_DIR|$CONTAINER_FASTQ_DIR|g" | tr '\n' ',' | sed 's/,$//')
    echo "Left files for container: $LEFT_FILES_CONTAINER"
else
    echo "ERROR: No left files (*1.fastq.gz) found in $HOST_FASTQ_DIR"
    echo "Available .fastq.gz files:"
    ls $HOST_FASTQ_DIR/*.fastq.gz 2>/dev/null || echo "No .fastq.gz files found"
    exit 1
fi

if ls $HOST_FASTQ_DIR/*2.fastq.gz 1> /dev/null 2>&1; then
    RIGHT_FILES=$(ls $HOST_FASTQ_DIR/*2.fastq.gz | tr '\n' ',' | sed 's/,$//')
    echo "Right files found: $RIGHT_FILES"
    RIGHT_FILES_CONTAINER=$(echo $RIGHT_FILES | sed "s|$HOST_FASTQ_DIR|$CONTAINER_FASTQ_DIR|g")
    echo "Right files for container: $RIGHT_FILES_CONTAINER"
else
    echo "ERROR: No right files (*2.fastq.gz) found in $HOST_FASTQ_DIR"
    echo "Available .fastq.gz files:"
    ls $HOST_FASTQ_DIR/*.fastq.gz 2>/dev/null || echo "No .fastq.gz files found"
    exit 1
fi

# Run Trinity with apptainer
echo "Starting Trinity assembly..."

echo "Using image: $IMAGE_PATH"

apptainer exec --bind $BIND_MOUNTS $IMAGE_PATH Trinity \
    --seqType fq \
    --left $LEFT_FILES_CONTAINER \
    --right $RIGHT_FILES_CONTAINER \
    --CPU 4 \
    --normalize_by_read_set \
    --min_kmer_cov 2 --max_memory 2G \
    --grid_exec "$CONTAINER_PROJECT_DIR/software/hpc-grid-runner/HpcGridRunner-1.0.2/hpc_cmds_GridRunner.pl \
    --grid_conf $CONTAINER_PROJECT_DIR/software/hpc-grid-runner/HpcGridRunner-1.0.2/hpc_conf/SLURM.Midway3.conf -c"




    