#!/bin/bash
#SBATCH --job-name=star_map
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=3:00:00
#SBATCH --cpus-per-task=48
#SBATCH --mem=96gb
#SBATCH --output=./SLURM_logs/star_map_%j.out
#SBATCH --error=./SLURM_logs/star_map_%j.err
#SBATCH --account=rcc-staff
#SBATCH --mail-type=END
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

IMAGE_PATH="$HOST_PROJECT_DIR/software/STAR.sif"

# HOST_FASTQ_DIR="$HOST_PROJECT_DIR/transcript_data/fastqs"
HOST_FASTQ_DIR="$HOST_PROJECT_DIR/transcript_data/fastqs"
CONTAINER_FASTQ_DIR="$CONTAINER_PROJECT_DIR/transcript_data/fastqs"

STAR_FILE="$CONTAINER_PROJECT_DIR/reference/Scer_genome.star"

BIND_MOUNTS="/home:/home,/scratch:/scratch,$HOST_PROJECT_DIR:$CONTAINER_PROJECT_DIR"

# Debug: Check if directory exists and list files
echo "Checking FASTQ directory: $FASTQ_DIR"
if [ -d "$HOST_FASTQ_DIR" ]; then
    echo "Directory exists. Contents:"
    ls -la $HOST_FASTQ_DIR/
    FASTQ_FILES=$(ls $HOST_FASTQ_DIR/* | tr '\n' ',' | sed 's/,$//')
    echo "fastq files found: $FASTQ_FILES"
    FASTQ_FILES_CONTAINER=$(echo "$FASTQ_FILES" | sed "s|$HOST_FASTQ_DIR|$CONTAINER_FASTQ_DIR|g" | tr '\n' ',' | sed 's/,$//')
    echo "fastq files for container: $FASTQ_FILES_CONTAINER"
else
    echo "Directory $HOST_FASTQ_DIR does not exist!"
    exit 1
fi

SAMPLE_NAMES=$(echo "$FASTQ_FILES" | tr ',' '\n' | sed 's|.*/||; s/_.*$//' | sort | uniq | tr '\n' ' ')

echo "Sample names: $SAMPLE_NAMES"

# Run STAR mapping with apptainer
echo "Starting STAR mapping..."

echo "Using image: $IMAGE_PATH"

for SAMPLE in $SAMPLE_NAMES; do
    echo "Processing sample: $SAMPLE"

    FASTQ_FILES_CONTAINER="$CONTAINER_PROJECT_DIR/transcript_data/fastqs/${SAMPLE}_pass_1.fastq.gz \
        $CONTAINER_PROJECT_DIR/transcript_data/fastqs/${SAMPLE}_pass_2.fastq.gz"

    apptainer exec --bind $BIND_MOUNTS $IMAGE_PATH \
    STAR --runThreadN $SLURM_CPUS_PER_TASK \
        --genomeDir $STAR_FILE \
        --readFilesIn $FASTQ_FILES_CONTAINER \
        --readFilesCommand zcat \
        --outFileNamePrefix $CONTAINER_PROJECT_DIR/transcript_data/bams/${SAMPLE} \
        --outTmpDir /scratch/midway3/hyadav/STAR_tmp/STAR_${SAMPLE} \
        --outSAMstrandField intronMotif \
        --limitBAMsortRAM 89519393895 \
        --outSAMtype BAM SortedByCoordinate

    echo "Finished processing sample: $SAMPLE"
done

echo "All samples processed!"


