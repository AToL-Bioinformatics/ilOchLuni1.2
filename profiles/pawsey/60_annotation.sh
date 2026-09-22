#!/bin/bash
#SBATCH --job-name=annotation
#SBATCH --time=1-00
#SBATCH --cpus-per-task=2
#SBATCH --ntasks=1
#SBATCH --mem=8g
#SBATCH --output=logs/slurm/annotation.%j.out
#SBATCH --error=logs/slurm/annotation.%j.err

# Source snakemake environment
source profiles/pawsey/lib/snakemake_env.sh

# Setup and run
setup_snakemake

# check this here because it's annotation-specific (for now)
export GPU_ACCOUNT="${PAWSEY_ACCOUNT:?Set PAWSEY_ACCOUNT to run the Annotation job}_gpu"

# we need a custom snakemake command because the Pawsey GPU queue doesn't
# accept the normal SBATCH arguments.
XDG_CACHE_HOME="$(mktemp -d)" \
	snakemake --profile profiles/pawsey \
	--cluster-generic-submit-cmd "\
			mkdir -p logs/slurm/{rule} \
			&& \
			sbatch \
			--time={resources.runtime} \
			{resources.partitionFlag} \
			--account=${GPU_ACCOUNT} \
			--gres=gpu:{resources.gpu} \
			--job-name={rule}-smk \
			--output=logs/slurm/{rule}/{rule}-%j.out \
			--parsable" \
	tiberius

exit 0

run_snakemake annotation
