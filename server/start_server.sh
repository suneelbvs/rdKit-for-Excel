#!/bin/bash
echo "Starting Atomicas ChemTools API..."
cd "$(dirname "$0")"

# Activate conda environment
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate cadd

uvicorn server:app --host 0.0.0.0 --port 8000 --reload
