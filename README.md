# BactAsm
### Bacterial Genome Assembly Pipeline

This Snakemake pipeline allows direct download from NCBI's SRA database with `fasterq-dump`.
The pipeline handles raw reads records of the bacterial genome from **SRA Accessions** to **Annotated _de novo_ Assemblies**.
**Variant calling** will also be performed after mapping to the reference genome provided. **Core SNPs** called from regions shared by all input sequences will be produced at the end of the pipeline.
All output files will be assessed by **1) FastQC, 2) QUAST**

## Sample Workflow

![dag](https://user-images.githubusercontent.com/31255012/209852338-0fbaee48-48b8-442d-b71e-98a965337e91.svg)

## Requirements

- Install Miniconda3
- Create a working directory

## Installation

### STEP 1: Download repo and change into BactAsm directory

```bash
git clone https://github.com/rx32940/BactAsm.git
cd BactAsm
```

### STEP 2: Create Environment

```bash
conda create -n BactAsm python=3.11 mamba -c conda-forge -y
conda activate BactAsm
conda config --set channel_priority flexible
pip install pyyaml biopython
mamba install -c conda-forge -c bioconda snakemake -y
```

> **Note:** Python 3.11 is required. Python 3.12+ causes compatibility issues with QUAST and SPAdes due to the removal of `distutils`.

## Running on HPC (SLURM clusters)

A SLURM submission script is included in the repo (`run_bactasm.sh`) for running BactAsm on HPC clusters. Edit the user settings at the top of the script before submitting:

```bash
# ====== USER SETTINGS - edit these ======
BACTASM_DIR=/path/to/BactAsm          # path to cloned BactAsm directory
OUTPUT=/path/to/your/output            # path to output directory
SAMPLE_LIST=/path/to/sample_list.txt  # path to sample list (sampleID TAB sraID)
REF=/path/to/your/reference.fna       # path to reference genome (optional)
THREADS=16                             # number of threads (match --cpus-per-task)
KINGDOM=Bacteria                       # kingdom (default: Bacteria)
GENUS=Leptospira                       # genus of organism
# =========================================
```

Then submit:
```bash
mkdir -p logs
sbatch run_bactasm.sh
```

> **Note:** Make sure to set `#SBATCH --account` to your HPC account name before submitting.

## Running with Docker/Apptainer (Recommended)

The easiest way to run BactPrep without installing any dependencies is to use the pre-built container. It works on any system with Docker or Apptainer/Singularity installed.

## Running with Docker/Apptainer (Recommended)

The easiest way to run BactAsm without installing any dependencies is to use the pre-built container. It works on any system with Docker or Apptainer/Singularity installed.

### Using Apptainer/Singularity (HPC):
```bash
# Set cache directory to avoid home directory space issues
export APPTAINER_CACHEDIR=/path/to/your/xdisk/.apptainer/cache

# Pull the container (one time only)
apptainer pull docker://biowizardhailey/bactasm:latest

# Run the pipeline
apptainer exec bactasm_latest.sif python /BactAsm/BactAsm.py \
  -l /path/to/sample_list.txt \
  -f /path/to/reference.fna \
  -o /path/to/output \
  -t 16 \
  -k Bacteria \
  -g Leptospira
```

> **Note:** No conda setup required — all dependencies are pre-installed in the container!

## Troubleshooting

- **Python version:** Always use `python=3.11` when creating the conda environment. Python 3.12+ breaks QUAST and SPAdes due to removal of `distutils`.
- **QUAST crashes with `No module named distutils`:** This is a known issue with QUAST on Python 3.12+. Use Python 3.11 in your conda environment to avoid this.
- **QUAST crashes with `No module named joblib3`:** This is also a known QUAST bug. The pipeline fixes this automatically by using `export PATH=$CONDA_PREFIX/bin:$PATH` in the shell rules.
- **Git fails on HPC:** If you get a `curl_global_sslset` error, run `export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH` first.
- **Missing modules:** If you get `ModuleNotFoundError` for `yaml` or `Bio`, run `pip install pyyaml biopython`.
- **SRA accession format:** BactAsm requires **run accessions** (starting with `SRR`, `ERR`, or `DRR`). Sample accessions (ERS, SRS) will not work with `fasterq-dump`.

## Usage

### Command line:

```bash
python BactAsm.py -h
```

```
usage: BactAsm.py [-h] [-s] [-b] [-l] [-f] [-o] [-t] [-k] [-g]
Fetch SRA records from NCBI and perform de novo assemble & read alignments to reference genome

optional arguments:
  -h, --help        show this help message and exit
  -s , --sra        SRA accession ID you would like to download
  -b , --sampleID   sampleID of the sample (this can be same as the SRA ID)
  -l , --list       input list (provide each sample's SampleID and sraID in a row, separated by TAB)
  -f , --ref        reference genome (optional, required for SNP calling)
  -o , --output     output directory
  -t , --thread     number of threads to use
  -k , --kingdom    which kingdom the genome is from, default is Bacteria
  -g , --genus      which genus the genome is from, default is Leptospira
```

### Sample list format:

Create a tab-separated file with sample ID and SRA run accession:

```
sample1    SRR2912551
sample2    SRR2912552
```

> **Note:** Use run accessions (SRR/ERR/DRR), not sample accessions (SRS/ERS/DRS).

### OR: use by modifying config files

1. Modify `config/config.yaml`
2. Add the bacterial genus of interest
3. Add SampleID and SRA run accession
4. Add expected output directory
5. Add path to reference genome (optional)
6. Modify the maximum number of threads

## Workflow

### Rule 1: raw.smk
1) Download fastq files from NCBI with `fasterq-dump` using samples provided in the config file
2) FastQC all raw reads files
3) Combine FastQC reports with MultiQC

### Rule 2: trim.smk
1) Trim raw reads with `fastp`
2) FastQC paired trimmed reads again
3) Aggregate FastQC reports with MultiQC

### Rule 3: asm.smk
1) Use SPAdes for de novo assembly → `outputdir/asm`
2) Use QUAST with or without reference genome for assembly quality assessment
3) Aggregate assessments with MultiQC

> **Note:** QUAST requires the conda environment's Python to run correctly on modern systems. This is handled automatically by the pipeline.

### Rule 4: annotate.smk
1) Use Prokka for genome annotation

### Rule 5: snp.smk
1) Use Snippy to call variants from the reference genome provided (no need to index the reference genome)
2) Aggregate variants for core SNPs detection

## Bug Fixes (2026)

The following bugs were fixed to make BactAsm compatible with modern tools and Python versions:

1. `BactAsm.py`: Fixed `AttributeError` — `arguments.config` attribute did not exist
2. `BactAsm.py`: Output directory is now created before writing the config file
3. `raw.smk`: Replaced deprecated `fastq-dump` with `fasterq-dump`
4. `annotate.smk`: Fixed single-dash Prokka flags to double-dash (`--kingdom`, `--genus`, etc.)
5. `asm.smk`: Fixed QUAST and SPAdes to use conda environment Python (required due to removal of `distutils` in Python 3.12)
6. `workflow/env/quast.yaml`: Updated to QUAST 5.3.0
7. `workflow/env/spades.yaml`: Updated to SPAdes 4.0.0
8. All environment yaml files updated to modern versions with `conda-forge` channel added

Tested successfully on `SRR2912551` (*Streptococcus pneumoniae* paired-end Illumina reads) on UA HPC Puma cluster. All 9 pipeline steps completed successfully.
