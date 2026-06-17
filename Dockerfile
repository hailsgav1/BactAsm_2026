FROM condaforge/mambaforge:latest

LABEL maintainer="biowizardhailey"
LABEL description="BactAsm - Bacterial Genome Assembly Pipeline"

# Set working directory
WORKDIR /BactAsm

# Copy the entire repo into the container
COPY . .

# Set conda channel priority
RUN conda config --set channel_priority flexible

# Install Python and base tools
RUN mamba install -c conda-forge -c bioconda \
    python=3.11 snakemake packaging joblib -y

# Install QC tools
RUN mamba install -c conda-forge -c bioconda \
    fastp fastqc multiqc -y

# Install assembly tools
RUN mamba install -c conda-forge -c bioconda \
    spades=4.0.0 quast=5.3.0 -y

# Install annotation and SNP tools
RUN mamba install -c conda-forge -c bioconda \
    prokka=1.14.6 snippy=4.6.0 samtools sra-tools qualimap -y

RUN pip install pyyaml biopython

# Fix QUAST distutils issue
RUN find /opt/conda -name "qconfig.py" -path "*/quast*" -exec \
    sed -i 's|from distutils.version import LooseVersion|from packaging.version import Version as LooseVersion|g' {} \;

# Fix QUAST joblib3 issue
RUN find /opt/conda -name "qutils.py" -path "*/quast*" -exec \
    sed -i 's|from joblib3 import Parallel, delayed|from joblib import Parallel, delayed|g' {} \;

# Make BactAsm.py executable
RUN chmod +x BactAsm.py

# Default command
ENTRYPOINT ["python", "BactAsm.py"]
