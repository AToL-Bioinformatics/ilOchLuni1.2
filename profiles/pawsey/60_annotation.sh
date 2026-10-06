#!/bin/bash
#SBATCH --job-name=annotation
#SBATCH --time=10
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
export GPU_ACCOUNT="${PAWSEY_PROJECT:?PAWSEY_PROJECT must be set for Annotation}-gpu"

# we need a custom jobscript because the Pawsey GPU queue doesn't accept the
# normal SBATCH arguments:
#   - `ntasks` and `nodes` must be set to 1
#   - `gres=gpu` and `gpus-per-task` control the number of GPUs
#   - normal RAM can't be requested, it is controlled by "GPU
#     allocation-packs". See
#     https://pawsey.atlassian.net/wiki/spaces/US/pages/51928618/Setonix+GPU+Partition+Quick+Start#f1f2fb2d-8761-45c3-9523-2f95f43e01cf-Pawsey's-way-for-requesting-resources-on-GPU-nodes-(different-to-standard-Slurm)

# To achieve this we have a second profile. Profile instances specified later
# take precedence over earlier instances, wherever the same top-level entries
# occur in multiple profiles, i.e. providing the GPU profile second means we
# can override the singularity-args and submit cmd from the generi Pawsey
# profile. See
# https://snakemake.readthedocs.io/en/stable/executing/cli.html#using-multiple-global-profiles
XDG_CACHE_HOME="$(mktemp -d)" \
	snakemake \
	--profile profiles/pawsey/config.v9+.yaml \
	--profile profiles/pawsey_gpu/config.v9+.yaml \
	tiberius

exit 0

# This target runs QC, uploads etc. with the standard command.
if [ $? -eq 0 ]; then
	run_snakemake post_annotation
fi
