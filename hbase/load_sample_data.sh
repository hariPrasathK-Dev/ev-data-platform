#!/bin/bash

##############################################################################
# HBase Sample Data Loading Script
# Loads a subset of EV charging station data into HBase for testing
##############################################################################

echo "========================================================================"
echo "HBase Data Loading Script - EV Charging Station Analytics"
echo "========================================================================"
echo ""

# Configuration
CSV_FILE="../ev_charging_station_data.csv"
SAMPLE_SIZE=5000  # Load 5000 records for demonstration
OUTPUT_FILE="sample_data_puts.hql"
TABLE_NAME="ev_charging_stations"

# Check if CSV file exists
if [ ! -f "$CSV_FILE" ]; then
    echo "ERROR: CSV file not found: $CSV_FILE"
    exit 1
fi

echo "Step 1: Generating HBase PUT commands from CSV..."
echo "Source File: $CSV_FILE"
echo "Sample Size: $SAMPLE_SIZE records"
echo ""

# Generate HBase put commands
python3 generate_hbase_puts.py "$CSV_FILE" "$SAMPLE_SIZE" > "$OUTPUT_FILE" 2>&1

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to generate PUT commands"
    exit 1
fi

echo "✓ PUT commands generated successfully"
echo "Output file: $OUTPUT_FILE"
echo ""

# Count generated commands
PUT_COUNT=$(grep -c "^put" "$OUTPUT_FILE" 2>/dev/null || echo "0")
echo "Generated $PUT_COUNT PUT commands"
echo ""

echo "Step 2: Loading data into HBase..."
echo "Table: $TABLE_NAME"
echo ""
echo "Executing HBase shell commands..."
echo "(This may take a few minutes depending on data size)"
echo ""

# Load data into HBase
hbase shell "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================================================"
    echo "✓ Data loaded successfully into HBase table: $TABLE_NAME"
    echo "========================================================================"
    echo ""
    echo "Next steps:"
    echo "  1. Verify data: hbase shell"
    echo "  2. Run: count '$TABLE_NAME'"
    echo "  3. Run: scan '$TABLE_NAME', {LIMIT => 5}"
    echo ""
else
    echo ""
    echo "ERROR: Failed to load data into HBase"
    echo "Please check HBase is running and table exists"
    exit 1
fi
