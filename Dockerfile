FROM continuumio/miniconda3:latest

LABEL maintainer="biowizardhailey"
LABEL description="BactAsm - Bacterial Genome Assembly Pipeline"

# Set working directory
WORKDIR /BactAsm

# Copy the entire repo into the container
COPY . .

# Set conda channel priority flexible
RUN conda config --set channel_priority flexible

# Install Python and base tools
RUN conda install -c conda-forge -c bioconda \
    python=3.11 snakemake packaging joblib -y

# Install QC tools
RUN conda install -c conda-forge -c bioconda \
    fastp fastqc multiqc -y

# Install assembly tools
RUN conda install -c conda-forge -c bioconda \
    spades=4.0.0 quast=5.3.0 -y

# Install Prokka without defaults channel
RUN conda create -n prokka_env -c conda-forge -c bioconda prokka -y

# Fix Perl library path issue
RUN cd /opt/conda/envs/prokka_env/lib/site_perl/5.26.2/ && \
    ln -s ../../perl5/site_perl/5.22.0/* . 2>/dev/null || true

# Install SNP tools
RUN conda install -c conda-forge -c bioconda snippy -y

# Install other tools
RUN conda install -c conda-forge -c bioconda samtools sra-tools -y

# Install qualimap
RUN conda install -c conda-forge -c bioconda qualimap -y

# Fix QUAST distutils issue
RUN find /opt/conda -name "qconfig.py" -path "*/quast*" -exec \
    sed -i 's|from distutils.version import LooseVersion|from packaging.version import Version as LooseVersion|g' {} \;

# Fix QUAST joblib3 issue
RUN find /opt/conda -name "qutils.py" -path "*/quast*" -exec \
    sed -i 's|from joblib3 import Parallel, delayed|from joblib import Parallel, delayed|g' {} \;

# Add prokka to PATH but keep base conda Python first
ENV PATH="/opt/conda/bin:/opt/conda/envs/prokka_env/bin:${PATH}"

RUN pip install pyyaml biopython

# Make BactAsm.py executable
RUN chmod +x /BactAsm/BactAsm.py

# Default command using full path
ENTRYPOINT ["python", "/BactAsm/BactAsm.py"]
