#!/bin/bash
#
# Phase 2: Upload Dataset to HDFS
# RUN THIS SCRIPT AS hduser: su - hduser, then cd to project dir and run ./phase2_upload_to_hdfs.sh
#

set -e  # Exit on error

echo "========================================================================"
echo "Phase 2: Uploading EV Charging Dataset to HDFS"
echo "========================================================================"
echo ""

# Check if running as hduser
CURRENT_USER=$(whoami)
if [ "$CURRENT_USER" != "hduser" ]; then
    echo "ERROR: This script must be run as 'hduser', not '$CURRENT_USER'"
    echo "Please run: su - hduser"
    echo "Then navigate to: cd /home/hduser/ev-charging-station-availability-analytics"
    echo "And execute: ./phase2_upload_to_hdfs.sh"
    exit 1
fi

echo "✓ Running as hduser"
echo ""

# Set environment variables
export HADOOP_HOME=${HADOOP_HOME:-/usr/local/hadoop}
export JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java-8-openjdk-amd64}
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$JAVA_HOME/bin:$PATH

# Verify Hadoop environment
if [ -z "$HADOOP_HOME" ]; then
    echo "ERROR: HADOOP_HOME is not set"
    echo "Please source your .bashrc or set HADOOP_HOME=/usr/local/hadoop"
    exit 1
fi

echo "✓ HADOOP_HOME=$HADOOP_HOME"
echo ""

# Check if Hadoop services are running
echo "Checking Hadoop services..."
JPS_OUTPUT=$(jps)
if echo "$JPS_OUTPUT" | grep -q "NameNode" && echo "$JPS_OUTPUT" | grep -q "DataNode"; then
    echo "✓ HDFS services are running"
else
    echo "⚠ Hadoop services are not running. Starting them now..."
    $HADOOP_HOME/sbin/start-dfs.sh
    sleep 10  # Wait for services to start
    $HADOOP_HOME/sbin/start-yarn.sh
    sleep 5
    echo "✓ Hadoop services started"
fi
echo ""

# Verify cleaned dataset exists
CLEANED_FILE="ev_charging_station_data_cleaned.csv"
if [ ! -f "$CLEANED_FILE" ]; then
    echo "ERROR: Cleaned dataset not found: $CLEANED_FILE"
    echo "Please run data_inspection.py first to generate the cleaned dataset"
    exit 1
fi

echo "✓ Found cleaned dataset: $CLEANED_FILE"
FILE_SIZE=$(du -h "$CLEANED_FILE" | cut -f1)
echo "  File size: $FILE_SIZE"
echo ""

# Create HDFS directory
echo "Creating HDFS directory structure..."
hdfs dfs -mkdir -p /input
echo "✓ HDFS directory created/verified: /input"
echo ""

# Check if file already exists in HDFS
echo "Checking if file already exists in HDFS..."
if hdfs dfs -test -e /input/ev_charging_station_data_cleaned.csv; then
    echo "⚠ File already exists in HDFS at /input/"
    read -p "Do you want to overwrite it? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing existing file..."
        hdfs dfs -rm /input/ev_charging_station_data_cleaned.csv
        echo "✓ Existing file removed"
    else
        echo "Skipping upload. Using existing file in HDFS."
        echo ""
        echo "HDFS file details:"
        hdfs dfs -ls /input/ev_charging_station_data_cleaned.csv
        exit 0
    fi
fi

# Upload to HDFS
echo ""
echo "Uploading $CLEANED_FILE to HDFS..."
echo "This may take a few minutes (uploading ~323 MB)..."
hdfs dfs -put "$CLEANED_FILE" /input/
echo "✓ Upload complete!"
echo ""

# Verify upload
echo "========================================================================"
echo "VERIFICATION"
echo "========================================================================"
echo ""

echo "1. HDFS Directory Listing:"
hdfs dfs -ls /input/
echo ""

echo "2. File Size in HDFS:"
hdfs dfs -du -h /input/ev_charging_station_data_cleaned.csv
echo ""

echo "3. Line Count (should be 1,317,751 including header):"
LINE_COUNT=$(hdfs dfs -cat /input/ev_charging_station_data_cleaned.csv | wc -l)
echo "   Lines: $LINE_COUNT"
echo ""

echo "4. Preview - First 10 lines:"
hdfs dfs -cat /input/ev_charging_station_data_cleaned.csv | head -10
echo ""

echo "5. Preview - Last 5 lines:"
hdfs dfs -cat /input/ev_charging_station_data_cleaned.csv | tail -5
echo ""

echo "========================================================================"
echo "Phase 2 COMPLETE!"
echo "========================================================================"
echo ""
echo "Dataset successfully uploaded to HDFS:"
echo "  HDFS Path: /input/ev_charging_station_data_cleaned.csv"
echo "  Records: 1,317,750 (plus 1 header row)"
echo "  Size: ~323 MB"
echo ""
echo "Next Steps:"
echo "  1. Run MapReduce jobs: cd mapreduce && bash run_mapreduce.sh"
echo "  2. Initialize Hive: cd hive && bash run_hive_setup.sh"
echo ""
