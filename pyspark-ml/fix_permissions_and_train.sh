#!/bin/bash

echo "====================================================================="
echo "FIX PERMISSIONS AND RE-RUN TRAINING"
echo "====================================================================="

cd /home/hduser/ev-charging-station-availability-analytics/pyspark-ml

echo ""
echo "[1] Current ownership:"
ls -la models/ outputs/

echo ""
echo "[2] Fixing permissions (requires sudo)..."
echo "    Making hduser owner of models/ directory..."
sudo chown -R hduser:hadoop models/
sudo chmod -R 755 models/

echo ""
echo "[3] Verifying permissions:"
ls -la models/ outputs/

echo ""
echo "[4] Removing old empty model directory if exists..."
rm -rf models/availability_model

echo ""
echo "[5] Setting up Python environment..."
if [ ! -d "venv" ]; then
    echo "    Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    echo "    Installing dependencies..."
    pip install --quiet pyspark==3.5.0 numpy pandas setuptools
else
    echo "    Using existing virtual environment"
    source venv/bin/activate
fi

echo ""
echo "[6] Running training..."
python train_model.py

echo ""
echo "[7] Verifying model was saved:"
ls -laR models/

echo ""
echo "====================================================================="
if [ -d "models/availability_model" ] && [ "$(ls -A models/availability_model)" ]; then
    echo "✓ SUCCESS! Model files created in models/availability_model/"
else
    echo "✗ FAILED - Model directory is still empty"
fi
echo "====================================================================="
