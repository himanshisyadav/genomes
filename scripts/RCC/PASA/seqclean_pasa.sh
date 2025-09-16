#!/bin/bash
#SBATCH --job-name=pasa_seqclean
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:10:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=16gb
#SBATCH --partition=caslake
#SBATCH --output=./SLURM_logs/%x_%j.out
#SBATCH --error=./SLURM_logs/%x_%j.err
#SBATCH --account=rcc-staff
#SBATCH --mail-type=ALL

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

# Load required modules
module load apptainer/1.4.1

# Set variables
HOST_PROJECT_DIR="/project/rcc/hyadav/genomes"
CONTAINER_PROJECT_DIR="/workspace"

IMAGE_PATH="$HOST_PROJECT_DIR/software/PASA.sif"

# Set bind mounts
BIND_MOUNTS="$PWD/temp:/tmp,$HOST_PROJECT_DIR:$CONTAINER_PROJECT_DIR"

INPUT_FILE_PATH="$CONTAINER_PROJECT_DIR/transcript_data/trinity_transcripts.fa"
VECTOR_SEQUENCE_PATH="$CONTAINER_PROJECT_DIR/scripts/RCC/PASA/UniVec"

echo "Running PASA seqclean..."

apptainer run \
     --bind $BIND_MOUNTS \
     $IMAGE_PATH \
          bash -c "cd /workspace/transcript_data/pasa \
               && /usr/local/src/PASApipeline/bin/seqclean \
               $INPUT_FILE_PATH \
               -v $VECTOR_SEQUENCE_PATH \
               -c $SLURM_CPUS_PER_TASK"
