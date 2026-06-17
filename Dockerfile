FROM continuumio/miniconda3:latest

LABEL maintainer="biowizardhailey"
LABEL description="BactAsm - Bacterial Genome Assembly Pipeline"

# Set working directory
WORKDIR /BactAsm

# Copy the entire repo into the container
COPY . .

# Set conda channel priority
RUN conda config --set channel_priority flexible

# Install all dependencies into base environment
RUN conda install -c conda-forge -c bioconda \
    python=3.11 \
    snakemake \
    fastp \
    fastqc \
    multiqc \
    spades=4.0.0 \
    quast=5.3.0 \
    prokka=1.14.6 \
    snippy=4.6.0 \
    samtools \
    sra-tools \
    qualimap \
    packaging \
    joblib -y

RUN pip install pyyaml biopython

# Fix QUAST distutils issue (removed in Python 3.12)
RUN find /opt/conda -name "qconfig.py" -path "*/quast*" -exec \
    sed -i 's|from distutils.version import LooseVersion|from packaging.version import Version as LooseVersion|g' {} \;

# Fix QUAST joblib3 issue (joblib3 doesn't exist, use joblib)
RUN find /opt/conda -name "qutils.py" -path "*/quast*" -exec \
    sed -i 's|from joblib3 import Parallel, delayed|from joblib import Parallel, delayed|g' {} \;

# Make BactAsm.py executable
RUN chmod +x BactAsm.py

# Default command
ENTRYPOINT ["python", "BactAsm.py"]
