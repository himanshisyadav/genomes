#!/bin/bash
#SBATCH --job-name=Stringtie
#SBATCH --partition=caslake
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:05:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=16gb
#SBATCH --output=./SLURM_logs/Stringtie.out
#SBATCH --error=./SLURM_logs/Stringtie.err
#SBATCH --account=rcc-staff
#SBATCH --mail-type=ALL

module load gcc/13.2.0
export PATH="/project/rcc/hyadav/genomes/software/stringtie:$PATH"

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

INPUT_FILE="/project/rcc/hyadav/genomes/transcript_data/bams/merged.bam"
OUTPUT_FILE="/project/rcc/hyadav/genomes/transcript_data/stringie/stringtie_yeast.gtf"
ABUNDANCE_OUTPUT_FILE="/project/rcc/hyadav/genomes/transcript_data/stringie/stringtie_yeast_abundances.txt"

# Default prefix (-l) for the output transcripts is STRG
# Default minimum isoform fraction (-f) is 0.01
# -A gene abundance estimation output file
# -j minimum junction coverage (default: 1)
#  -c minimum reads per bp coverage to consider for multi-exon transcript (default: 1)

stringtie $INPUT_FILE \
	  -o $OUTPUT_FILE \
	  -p $SLURM_CPUS_PER_TASK \
	  -l STRG -f 0.10 -A $ABUNDANCE_OUTPUT_FILE \
	  -j 3 \
	  -c 3 \
	  

