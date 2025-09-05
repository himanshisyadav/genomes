# Genome Annotation Slurm Scripts Collection

This repository contains Slurm sbatch scripts and configurations for running genome annotation software on HPC clusters, specifically written for UChicago RCC's Midway3 Cluster

## Repository Structure

```
.
├── scripts/              # SLURM sbatch scripts
├── .gitignore            # Git ignore rules  
└── README.md             # This file
```

## Directory Overview

### 📁 `scripts/`
Collection of bioinformatics software tools, each with corresponding Slurm sbatch scripts for cluster execution. Each subdirectory contains:
- Bash scripts (`.sbatch` or `.sh` files)
- Configuration files
- Tool-specific documentation
- Usage examples

**See [`scripts/README.md`](scripts/README.md) for detailed usage instructions.**

## Getting Started

### 1. Clone Repository
```bash
git clone git@github.com:himanshisyadav/genomes.git
cd genomes
```

### 2. Run Analysis Tools
Navigate to the `scripts/` directory and follow the instructions in [`scripts/README.md`](scripts/README.md).

## Data Management

### Repository Focus
This repository contains **only** Slurm scripts and configurations - no data files are stored here.

### What's Tracked
- Slurm sbatch scripts (`.sbatch` or `.sh` files)
- Configuration files for software tools
- Documentation and README files
- Shell scripts and utilities

### What's Not Included
- Raw data files (FASTA, BAM, VCF, etc.)
- Software binaries or installations
- Analysis results or output files
- Large reference datasets

### Local Setup
For actual data analysis:
1. Clone this repository to get the scripts
2. Set up your data directories locally (not tracked by git)
3. Modify script paths to point to your local data locations
4. Run the sbatch scripts on your cluster

## Contributing

1. Keep data files out of version control
2. Document new analysis tools in `scripts/`
3. Update README files when adding new workflows
4. Use descriptive commit messages

---
*Last updated: 19 August 2025*
