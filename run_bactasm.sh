#!/bin/bash
#SBATCH --job-name=BactAsm
#SBATCH --output=logs/bactasm_%j.out
#SBATCH --error=logs/bactasm_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64gb
#SBATCH --time=24:00:00
#SBATCH --account=your_account
#SBATCH --partition=standard

# ====== USER SETTINGS - edit these ======
BACTASM_DIR=/path/to/BactAsm          # path to cloned BactAsm directory
OUTPUT=/path/to/your/output            # path to output directory
SAMPLE_LIST=/path/to/sample_list.txt  # path to sample list (sampleID TAB sraID)
REF=/path/to/your/reference.fna       # path to reference genome (optional)
THREADS=16                             # number of threads (match --cpus-per-task)
KINGDOM=Bacteria                       # kingdom (default: Bacteria)
GENUS=Leptospira                       # genus of organism
# =========================================

source ~/.bashrc
conda activate BactAsm
export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH
mkdir -p $BACTASM_DIR/logs
cd $BACTASM_DIR

python BactAsm.py \
  -l $SAMPLE_LIST \
  -f $REF \
  -o $OUTPUT \
  -t $THREADS \
  -k $KINGDOM \
  -g $GENUS
