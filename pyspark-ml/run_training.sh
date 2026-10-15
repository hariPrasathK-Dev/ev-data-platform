#!/bin/bash
# Train ML Model using PySpark

echo "======================================"
echo "EV Charging ML Model Training"
echo "======================================"
echo ""

# Check CSV exists
if [ ! -f "../ev_charging_station_data_cleaned.csv" ]; then
    echo "✗ Error: CSV file not found"
    echo "Expected: ../ev_charging_station_data_cleaned.csv"
    exit 1
fi

echo "✓ Dataset found"

# Setup venv if it doesn't exist
if [ ! -d "venv" ]; then
    echo "✓ Creating Python virtual environment..."
    python3 -m venv venv
    echo "✓ Installing dependencies..."
    source venv/bin/activate
    pip install --quiet pyspark==3.5.0 numpy pandas setuptools
else
    echo "✓ Using existing virtual environment"
    source venv/bin/activate
fi

echo "✓ Starting training (this will take 5-10 minutes)..."
echo ""

# Run training with venv Python
python train_model.py

if [ $? -eq 0 ]; then
    echo ""
    echo "======================================"
    echo "✓ SUCCESS!"
    echo "======================================"
    echo ""
    echo "Outputs generated:"
    echo "  • models/availability_model/ - Trained model"
    echo "  • outputs/metrics.json - Evaluation metrics"
    echo "  • outputs/feature_importance.json - Feature rankings"
    echo "  • outputs/confusion_matrix.json - Confusion matrix"
    echo ""
    echo "Next: Restart backend to load the model"
else
    echo ""
    echo "✗ Training failed"
    exit 1
fi
