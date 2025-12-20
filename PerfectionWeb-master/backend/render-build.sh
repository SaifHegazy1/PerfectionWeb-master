#!/usr/bin/env bash
set -euo pipefail
echo "Using Python: $(python --version)"
python -m pip install --upgrade pip setuptools wheel
# Install a prebuilt NumPy wheel first to avoid building from source
python -m pip install numpy==1.26.4
# Install remaining requirements
python -m pip install -r requirements.txt
echo "Dependencies installed successfully"
