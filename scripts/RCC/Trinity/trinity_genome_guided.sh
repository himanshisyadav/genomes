#!/bin/bash
#SBATCH --job-name=trinity_gg
#SBATCH --partition=caslake
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=3:00:00
#SBATCH --cpus-per-task=48
#SBATCH --mem=128GB
#SBATCH --output=./SLURM_logs/trinity_gg_%j.out
#SBATCH --error=./SLURM_logs/trinity_gg_%j.err
#SBATCH --account=rcc-staff

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

HOST_INPUT_FILE="$HOST_PROJECT_DIR/transcript_data/bams/merged.bam"
CONTAINER_INPUT_FILE="$CONTAINER_PROJECT_DIR/transcript_data/bams/merged.bam"

HOST_OUTPUT_DIR="$HOST_PROJECT_DIR/transcript_data/trinity_gg"
CONTAINER_OUTPUT_DIR="$CONTAINER_PROJECT_DIR/transcript_data/trinity_gg"

BIND_MOUNTS="/home:/home,/scratch:/scratch,$HOST_PROJECT_DIR:$CONTAINER_PROJECT_DIR"

# Run Trinity with apptainer
echo "Starting Genome-Guided Trinity assembly..."

echo "Using image: $IMAGE_PATH"

apptainer exec \
    --bind $BIND_MOUNTS \
    $IMAGE_PATH \
        Trinity --genome_guided_bam $CONTAINER_INPUT_FILE \
        --max_memory $max_memory_arg \
        --CPU $SLURM_CPUS_PER_TASK \
        --output $CONTAINER_OUTPUT_DIR \
        --genome_guided_max_intron 100000 