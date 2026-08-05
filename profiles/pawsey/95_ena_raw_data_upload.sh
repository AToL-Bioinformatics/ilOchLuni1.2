#!/bin/bash
#SBATCH --job-name=ena_raw_data_upload
#SBATCH --time=0-04
#SBATCH --cpus-per-task=2
#SBATCH --ntasks=1
#SBATCH --mem=8g

# Source snakemake environment
source profiles/pawsey/lib/snakemake_env.sh

# Setup and run
setup_snakemake
run_snakemake ena_raw_data_upload
