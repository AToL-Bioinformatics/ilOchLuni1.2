# ilOchLuni1.2

This repository contains the workflows that were used to assemble the genome
ilOchLuni1.2 for *Ochrogaster lunifer*.

The repo was produced automatically from boilerplate code at
[AToL-Bioinformatics/genome-launcher-workflow](https://github.com/AToL-Bioinformatics/genome-launcher-workflow).

### Assembly data

<details>

<summary>Click to view YAML</summary>

```yaml
assembly_id: 94b49f4f-835d-47d3-b1ec-43e6efcef6d3
assembly_version: 2
augustus_dataset_name: camponotus_floridanus
busco_odb10_dataset_name: lepidoptera
busco_odb12_dataset_name: lepidoptera
dataset_id: ilOchLuni1
genetic_code_id: 1
hic_motif: GATC,GANTC,CTNAG,TTAA
mitochondrial_genetic_code_id: 5
mitohifi_reference_species: Ochrogaster lunifer
ncbi_class: Insecta
oatk_hmm_name: insecta
read_files:
- base_url: https://downloads-qcif.bioplatforms.com/bpa/avid_staging/pacbio-hifi/BPAOPS-2129/20260702_AVID_AGRF_CAGRF26050436_m84073_260626_035957_s1/
  data_type: PACBIO_SMRT
  name: bpa-avid-pacbio-hifi-702636-m84073_260626_035957_s1
  single_end:
  - md5sum: 8ce0fb7f6e0809cd79f305ea3e618abb
    url: https://data.bioplatforms.com/dataset/bpa-avid-pacbio-hifi-702636-m84073_260626_035957_s1/resource/8ce0fb7f6e0809cd79f305ea3e618abb/download/702636_AVID_AGRF_m84073_260626_035957_s1.ccs.bam
- base_url: https://downloads-qcif.bioplatforms.com/bpa/avid_staging/illumina-shortread/BPAOPS-2174/20260801_AVID_BRF_WO31020_SC2233836-SC3/
  data_type: Hi-C
  name: bpa-avid-illumina-shortread-669080-sc2233836-sc3
  r1:
  - lane_number: L001
    md5sum: f1201be8ba4c9072e3745dce1c5cdeb6
    url: https://data.bioplatforms.com/dataset/bpa-avid-illumina-shortread-669080-sc2233836-sc3/resource/f1201be8ba4c9072e3745dce1c5cdeb6/download/669080_AVID_BRF_SC2233836-SC3_TCCGTTAA-GCCAAGCT_S1_L001_R1_001.fastq.gz
  r2:
  - lane_number: L001
    md5sum: 15d71aae8ad5cdd97c925313711adb33
    url: https://data.bioplatforms.com/dataset/bpa-avid-illumina-shortread-669080-sc2233836-sc3/resource/15d71aae8ad5cdd97c925313711adb33/download/669080_AVID_BRF_SC2233836-SC3_TCCGTTAA-GCCAAGCT_S1_L001_R2_001.fastq.gz
scientific_name: Ochrogaster lunifer
taxon_id: 319761

```

</details>

## Overview

The assembly process has three main steps:

1. Assembly with
   [sanger-tol/genomeassembly](https://github.com/sanger-tol/genomeassembly/)
2. Decontamination with [sanger-tol/ascc](https://github.com/sanger-tol/ascc/)
3. Preparation of curation materials with
   [sanger-tol/treeval](https://github.com/sanger-tol/treeval/), if there are
   Hi-C reads.

The config files for these steps are in the [config](./config) directory.

The sanger-tol workflows are plumbed together by the [included Snakemake
worfklow](./workflow/Snakefile).

## Running the assembly

### Setting up

Clone this repo to the HPC where it will be run.

A profile will be needed to configure the job scheduler on the HPC. Profiles
for [Setonix](./profiles/pawsey) and [Spartan (partial)](./profiles/spartan)
are included. A profile for [local testing](./profiles/local) is also included.

<details>

<summary>More information about the profile</summary>

#### The profile needs at least the following files:

- Snakemake [**job config**](./profiles/pawsey/config.v9+.yaml) and [**workflow
  config**](./profiles/pawsey/workflow.config.yaml): configure the jobs from the
  genome-launcher-workflow.
- [**nextflow config**](./profiles/pawsey/pawsey.config): configure the
  processes from the Sanger-Tol pipelines
- [**ascc.params.config**](./profiles/pawsey/ascc.params.config): the [YAML
  params
  file](https://pipelines.tol.sanger.ac.uk/ascc/0.6.0/usage#running-the-pipeline)
  for ASCC (not shared with the other pipelines).

</details>

### Steps

1. Download the reads and run the QC scripts using the genome-launcher-workflow
   target `pre_genomeassembly`.
2. Run the `genomeassembly` workflow. See the [example 20_genomeassembly.sh
   script](profiles/pawsey/20_genomeassembly.sh).
3. Stage the ASCC reference data using the genome-launcher-workflow target
   `post_genomeassembly`.
4. Run the `ascc` workflow. See the [example 30_ascc.sh
   script](profiles/pawsey/30_ascc.sh).
5. Convert the ASCC output for TreeVal using the genome-launcher-workflow
   target `post_ascc`.
6. If Hi-C is available, run the `treeval` workflow. See the [example
   40_treeval.sh submission script](profiles/pawsey/40_treeval.sh).
7. Run the `post_treeval` target to upload the results to object storage. The
   `post_*` targets all upload the output of the preceding pipeline to object
   storage.
8. **Optional**: curate the genome manually using
   [PretextView](https://github.com/sanger-tol/PretextView). Add the AGP file
   that is output by PretextView and a list of any contigs or scaffolds to
   remove to the repository on GitHub. The files must be named as follows:
   - `curation/{dataset_id}_{assembly_version}_normal_curated_v1.pretext.agp_1`
   - `curation/{dataset_id}.{assembly_version}_scaffolds_to_remove.txt`
9. Once the files from step 8 have been added, pull the updates and run the
   `post_curation` target to split the haplotypes.
10. **Optional**: use the `all_assembly_stats` target to run `seqkit stats
    -all` on the list of expected assembly outputs.
11. **Optional**: use the `upload_all_logs` target to backup all the log files
    to object store.

<details>

<summary>Worked example</summary>

#### Run this assembly on Setonix:

> [!IMPORTANT]
>
> The pull command requires a Personal Access Token with read access to code
> and metadata.

1. Pull the repo:
   1. `git init . `
   2. `git remote add origin https://github.com/AToL-Bioinformatics/ilOchLuni1.2.git`
   3. `git pull origin main`
2. Set up the directory structure: `bash profiles/pawsey/00_preflight.sh`
3. Run the workflow steps:
   1. `sbatch profiles/pawsey/10_pre_genomeassembly.sh`
   2. `sbatch profiles/pawsey/20_genomeassembly.sh`
   3. `sbatch profiles/pawsey/25_post_genomeassembly.sh`
   4. `sbatch profiles/pawsey/30_ascc.sh`
   5. `sbatch profiles/pawsey/35_post_ascc.sh`
   6. `sbatch profiles/pawsey/40_treeval.sh`
   7. `sbatch profiles/pawsey/45_post_treeval.sh`
4. Curate manually, add the curation files to the repo, and update the repo:
   1. `git pull origin main`
   2. `sbatch profiles/pawsey/55_post_curation.sh`
5. Generate assembly stats:
   1. `sbatch profiles/pawsey/98_all_assembly_stats.sh`
6. Backup the logs:
   1. `sbatch profiles/pawsey/99_upload_all_logs.sh`

</details>