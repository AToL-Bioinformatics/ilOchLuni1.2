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
export GPU_ACCOUNT="${PAWSEY_PROJECT:?PAWSEY_PROJECT must be set for Annotation}_gpu"

# we need a custom snakemake command because the Pawsey GPU queue doesn't
# accept the normal SBATCH arguments:
#   - `ntasks` and `nodes` must be set to 1
#   - `gres=gpu` and `gpus-per-task` control the number of GPUs
#   - normal RAM can't be requested, it is controlled by "GPU
#     allocation-packs". See
#     https://pawsey.atlassian.net/wiki/spaces/US/pages/51928618/Setonix+GPU+Partition+Quick+Start#f1f2fb2d-8761-45c3-9523-2f95f43e01cf-Pawsey's-way-for-requesting-resources-on-GPU-nodes-(different-to-standard-Slurm)
XDG_CACHE_HOME="$(mktemp -d)" \
	snakemake --profile profiles/pawsey \
	--retries 1 \
	--cluster-generic-submit-cmd "\
		mkdir -p logs/slurm/{rule} \
		&& \
		sbatch \
		--account=${GPU_ACCOUNT} \
		--gpus-per-task={resources.gpu} \
		--gres=gpu:{resources.gpu} \
		--job-name={rule}-smk \
		--ntasks=1 --nodes=1 \
		--output=logs/slurm/{rule}/{rule}-%j.out \
		--parsable \
		--time={resources.runtime} \
		{resources.partitionFlag}" \
	tiberius

# This target runs QC, uploads etc. with the standard command.
run_snakemake post_annotation
