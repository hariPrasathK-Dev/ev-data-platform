#!/bin/bash
# Run Scala Spark RDD Analysis

echo "======================================"
echo "Running Scala Spark RDD Analysis"
echo "======================================"

# Check if compiled
if [ ! -f "EVChargingRDDAnalysis.class" ]; then
    echo "Error: EVChargingRDDAnalysis.class not found"
    echo "Please run ./build.sh first"
    exit 1
fi

# Find Spark
if [ -z "$SPARK_HOME" ]; then
    echo "Error: SPARK_HOME not set"
    echo "Please run as user 'hprasatk' who has Spark configured"
    exit 1
fi

CSV_PATH="../ev_charging_station_data_cleaned.csv"
OUTPUT_PATH="../data/processed/spark"

if [ ! -f "$CSV_PATH" ]; then
    echo "Error: CSV file not found at $CSV_PATH"
    exit 1
fi

echo ""
echo "Configuration:"
echo "  CSV: $CSV_PATH"
echo "  Output: $OUTPUT_PATH"
echo ""

# Create output directory
mkdir -p "$OUTPUT_PATH"

# Run with Spark
spark-submit \
  --class EVChargingRDDAnalysis \
  --master local[*] \
  --driver-memory 2g \
  --executor-memory 2g \
  . \
  "$CSV_PATH" \
  "$OUTPUT_PATH"

if [ $? -eq 0 ]; then
    echo ""
    echo "======================================"
    echo "SUCCESS! Check outputs in:"
    echo "  $OUTPUT_PATH/"
    echo "======================================"
else
    echo ""
    echo "✗ Execution failed"
    exit 1
fi
