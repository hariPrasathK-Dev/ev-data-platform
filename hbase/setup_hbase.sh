#!/bin/bash

##############################################################################
# Complete HBase Setup Script
# Creates table, loads sample data, and verifies installation
##############################################################################

echo "========================================================================"
echo "HBase Setup for EV Charging Station Availability Analytics"
echo "========================================================================"
echo ""

# Check if HBase is running
echo "Step 1: Checking HBase status..."
if ! command -v hbase &> /dev/null; then
    echo "ERROR: HBase command not found. Please ensure HBase is installed."
    exit 1
fi

# Check if HBase is accessible
hbase version 2>&1 | head -1
if [ $? -ne 0 ]; then
    echo "ERROR: Cannot access HBase. Please start HBase first."
    echo "Run: start-hbase.sh"
    exit 1
fi

echo "✓ HBase is accessible"
echo ""

# Create table
echo "Step 2: Creating HBase table..."
echo "Table: ev_charging_stations"
echo "Column Families: cf_station, cf_metrics, cf_pricing, cf_weather, cf_context, cf_temporal"
echo ""

hbase shell create_table.hql

if [ $? -eq 0 ]; then
    echo "✓ Table created successfully"
else
    echo "⚠ Table creation returned an error (may already exist)"
fi
echo ""

# Load sample data
echo "Step 3: Loading sample data..."
bash load_sample_data.sh

if [ $? -ne 0 ]; then
    echo "ERROR: Data loading failed"
    exit 1
fi

# Verify data
echo ""
echo "Step 4: Verifying data load..."
echo "Running row count..."
echo ""

echo "count 'ev_charging_stations'" | hbase shell 2>/dev/null | grep "row(s)"

echo ""
echo "========================================================================"
echo "✓ HBase setup complete!"
echo "========================================================================"
echo ""
echo "Table: ev_charging_stations"
echo "Status: Ready for queries"
echo ""
echo "You can now run:"
echo "  - Analysis queries: bash run_analysis.sh"
echo "  - Filter examples: bash run_filters.sh"
echo "  - Java API demo: bash run_java_api.sh"
echo ""
