#!/bin/bash
#SBATCH --job-name=star_index
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=6
#SBATCH --mem=6gb
#SBATCH --output=./SLURM_logs/star_index_%j.out
#SBATCH --error=./SLURM_logs/star_index_%j.err
#SBATCH --account=rcc-staff
#SBATCH --mail-type=ALL
#SBATCH --mail-user=hyadav@rcc.uchicago.edu

module load apptainer/1.4.1

IMAGE_PATH="$HOST_PROJECT_DIR/software/STAR.sif"

apptainer exec --bind $PWD:/workspace $IMAGE_PATH \
    STAR --runThreadN 6 --runMode genomeGenerate --genomeSAindexNbases 13 --genomeDir ./calbi.genome.masked.star --genomeFastaFiles ./calbi.genome.fasta.masked