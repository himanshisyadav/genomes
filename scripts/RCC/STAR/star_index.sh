#!/bin/bash
#SBATCH --job-name=star_index
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:05:00
#SBATCH --cpus-per-task=6
#SBATCH --mem=16gb
#SBATCH --output=./SLURM_logs/star_index_%j.out
#SBATCH --error=./SLURM_logs/star_index_%j.err
#SBATCH --account=rcc-staff
#SBATCH --mail-type=ALL
#SBATCH --mail-user=hyadav@rcc.uchicago.edu

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

INPUT_FILE="$CONTAINER_PROJECT_DIR/reference/Scer_genome.fa"
OUTPUT_FILE="$CONTAINER_PROJECT_DIR/reference/Scer_genome.star"

IMAGE_PATH="$HOST_PROJECT_DIR/software/STAR.sif"

BIND_MOUNTS="/home:/home,/scratch:/scratch,$HOST_PROJECT_DIR:$CONTAINER_PROJECT_DIR"

# Run STAR indexing with apptainer
echo "Starting STAR indexing..."

echo "Using image: $IMAGE_PATH"

apptainer exec --bind $BIND_MOUNTS $IMAGE_PATH \
    STAR --runThreadN $SLURM_CPUS_PER_TASK --runMode genomeGenerate --genomeSAindexNbases 13 --genomeDir $OUTPUT_FILE --genomeFastaFiles $INPUT_FILE