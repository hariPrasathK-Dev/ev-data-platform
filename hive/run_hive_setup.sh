#!/bin/bash
#
# Create Hive Table for EV Charging Dataset
# RUN AS hduser
#

set -e  # Exit on error

echo "========================================================================"
echo "Creating Hive Table: ev_charging_stations"
echo "========================================================================"
echo ""

# Check if running as hduser
CURRENT_USER=$(whoami)
if [ "$CURRENT_USER" != "hduser" ]; then
    echo "ERROR: This script must be run as 'hduser', not '$CURRENT_USER'"
    exit 1
fi

echo "✓ Running as hduser"
echo ""

# Verify HIVE_HOME is set
if [ -z "$HIVE_HOME" ]; then
    echo "⚠ HIVE_HOME is not set, setting to /usr/local/hive"
    export HIVE_HOME=/usr/local/hive
fi

echo "✓ HIVE_HOME=$HIVE_HOME"
echo ""

# Check if data exists in HDFS
echo "Checking HDFS for dataset..."
if hdfs dfs -test -e /home/hduser/Hive_Assignment/ev_charging_station_data_cleaned.csv; then
    echo "✓ Dataset found in HDFS"
    hdfs dfs -ls /home/hduser/Hive_Assignment/ev_charging_station_data_cleaned.csv
else
    echo "✗ Dataset NOT found in HDFS"
    echo "Please run phase2_upload_to_hdfs.sh first"
    exit 1
fi
echo ""

# Execute table creation script
echo "Executing create_table.hql..."
echo ""
echo "========================================================================"

hive -f create_table.hql

if [ $? -eq 0 ]; then
    echo "========================================================================"
    echo "✓ Table created successfully!"
    echo "========================================================================"
else
    echo "✗ Table creation failed!"
    exit 1
fi

echo ""
echo "Table 'ev_charging_stations' is ready for querying"
echo ""
echo "Next steps:"
echo "  1. Run queries: ./run_queries.sh"
echo "  2. Or use Hive CLI: hive"
echo "  3. Or use Beeline: beeline -u jdbc:hive2://localhost:10000"
echo ""
