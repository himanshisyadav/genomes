# Software Collection

This directory contains multiple software tools, each with their corresponding Slurm scripts for execution on the RCC Midway3 cluster. 

## Directory Structure

```
.
├── Trinity/
│   ├── run.sh
│   ├── config/
├── PASA/
│   ├── run.sh
│   ├── config/
├── STAR/
│   ├── run.sh
│   ├── config/
├── Nextflow/
│   ├── nextflow.config
└── README.md (this file)
```

## Available Software

| Software | Directory | SLURM Script | Description |
|----------|-----------|--------------|-------------|
| [Trinity](https://github.com/trinityrnaseq/trinityrnaseq) | `Trinity/` | `run.sh` | Trinity assembles transcript sequences from Illumina RNA-Seq data |
| [PASA](https://github.com/PASApipeline/PASApipeline) | `PASA/` | `run.sh` | PASA, acronym for Program to Assemble Spliced Alignments (and pronounced 'pass-uh'), is a eukaryotic genome annotation tool  |
| [STAR](https://github.com/alexdobin/STAR) | `STAR/` | `run.sh` | Spliced Transcripts Alignment to a Reference |

## Quick Start

### 1. Navigate to Software Directory
```bash
cd software/  # Replace with desired software
```

### 2. Submit Job
```bash
sbatch run.sh  # Use the appropriate batch script
```

### 3. Monitor Job
```bash
squeue -u $USER
```

## Useful Commands
```bash
# Check job status
squeue -u $USER

# Cancel a job
scancel JOB_ID

# View job details
scontrol show job JOB_ID

# Check account usage
sacct -u $USER --starttime=2025-01-01

# View cluster partitions
sinfo
```

## Notes
- All batch scripts are configured for Midway3 cluster
- Default partition: caslake
- For large jobs, consider using bigmem

---
*For cluster-specific documentation, see: [link to cluster documentation](https://docs.rcc.uchicago.edu/)*