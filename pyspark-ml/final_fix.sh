#!/bin/bash
set -e

echo "====================================================================="
echo "FINAL FIX - NO MORE PERMISSION ISSUES"
echo "====================================================================="

cd /home/hduser/ev-charging-station-availability-analytics/pyspark-ml

echo ""
echo "[1] Fixing ALL ownership issues..."
sudo chown -R hduser:hadoop /home/hduser/ev-charging-station-availability-analytics/pyspark-ml/

echo ""
echo "[2] Installing Python dependencies system-wide (one time)..."
pip3 install --break-system-packages pyspark==3.5.0 numpy pandas 2>/dev/null || echo "    (dependencies may already be installed)"

echo ""
echo "[3] Cleaning up..."
rm -rf models/availability_model
rm -rf venv

echo ""
echo "[4] Running training with system Python..."
python3 train_model.py

echo ""
echo "[5] Verifying model was saved:"
if [ -d "models/availability_model" ] && [ "$(ls -A models/availability_model 2>/dev/null)" ]; then
    echo ""
    echo "====================================================================="
    echo "✓✓✓ SUCCESS! Model saved successfully! ✓✓✓"
    echo "====================================================================="
    ls -lh models/availability_model/ | head -10
    echo ""
    echo "Backend can now load the model for predictions!"
else
    echo ""
    echo "====================================================================="
    echo "Model directory contents:"
    ls -laR models/
    echo "====================================================================="
fi
