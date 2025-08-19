#!/bin/bash
#SBATCH --job-name=pasa
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=3:00:00
#SBATCH --cpus-per-task=48
#SBATCH --mem=128G
#SBATCH --partition=caslake
#SBATCH --output=./SLURM_logs/pasa_%j.out
#SBATCH --error=./SLURM_logs/pasa_%j.err
#SBATCH --account=rcc-staff
#SBATCH --mail-type=ALL
##SBATCH --exclusive

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

cd /project/rcc/hyadav/genomes/transcript_data/pasa/

# Set bind mounts
BIND_MOUNTS="$PWD/temp:/tmp,$HOST_PROJECT_DIR:$CONTAINER_PROJECT_DIR"

TRANSCRIPTS_PATH="$CONTAINER_PROJECT_DIR/transcript_data/pasa/transcripts_combined/trinity_out_dir.Trinity.fasta"
TRANSCRIPTS_CLEAN_PATH="$CONTAINER_PROJECT_DIR/transcript_data/pasa/transcripts_combined/trinity_out_dir.Trinity.fasta.clean"
DATABASE_CONFIG_PATH="$CONTAINER_PROJECT_DIR/transcript_data/pasa/sqlite.confs/alignAssembly.config"
GENOME_PATH="$CONTAINER_PROJECT_DIR/transcript_data/yeast_genome/Scer_genome.fa"

# echo "Running PASA assembly alignment..."

apptainer run \
     --bind $BIND_MOUNTS \
     $IMAGE_PATH \
          bash -c "cd /workspace/transcript_data/pasa \
               && /usr/local/src/PASApipeline/Launch_PASA_pipeline.pl -c $DATABASE_CONFIG_PATH \
               --ALIGNERS gmap,blat,minimap2 \
               --MAX_INTRON_LENGTH 100000 \
               --CPU 8 \
               --create --run \
               --ALT_SPLICE \
               --stringent_alignment_overlap 30.0 \
               -T \
               -g $GENOME_PATH \
               -u $TRANSCRIPTS_PATH \
               -t $TRANSCRIPTS_CLEAN_PATH"
               # --TDN tdn.accs"  


