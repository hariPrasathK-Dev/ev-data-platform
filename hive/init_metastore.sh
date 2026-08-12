#!/bin/bash
#
# Initialize Hive Metastore Database (Derby)
# RUN AS hduser - FIRST TIME SETUP ONLY
#

echo "========================================================================"
echo "Hive Metastore Initialization"
echo "========================================================================"
echo ""

# Check if running as hduser
CURRENT_USER=$(whoami)
if [ "$CURRENT_USER" != "hduser" ]; then
    echo "ERROR: This script must be run as 'hduser'"
    exit 1
fi

echo "✓ Running as hduser"
echo ""

# Set environment variables
export HIVE_HOME=${HIVE_HOME:-/usr/local/hive}
export HADOOP_HOME=${HADOOP_HOME:-/usr/local/hadoop}
export PATH=$HIVE_HOME/bin:$HADOOP_HOME/bin:$PATH

echo "Environment:"
echo "  HIVE_HOME: $HIVE_HOME"
echo "  HADOOP_HOME: $HADOOP_HOME"
echo ""

# Stop metastore if running
echo "Stopping any running metastore service..."
pkill -f "service metastore" 2>/dev/null
sleep 3
echo "✓ Stopped"
echo ""

# Go to a clean directory (Derby creates files in current directory)
METASTORE_DIR="/usr/local/hive"
cd $METASTORE_DIR
echo "Working directory: $(pwd)"
echo ""

# Check if metastore_db already exists
if [ -d "metastore_db" ]; then
    echo "⚠ metastore_db directory already exists"
    echo "This may indicate metastore was previously initialized"
    echo ""
    read -p "Delete and reinitialize? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf metastore_db
        rm -f derby.log
        echo "✓ Cleaned up old metastore"
    else
        echo "Keeping existing metastore"
        echo ""
        echo "Starting metastore service..."
        nohup hive --service metastore > /tmp/hive-metastore.log 2>&1 &
        sleep 10
        ps aux | grep metastore | grep -v grep
        echo ""
        echo "✓ Metastore started"
        exit 0
    fi
fi
echo ""

# Initialize the schema
echo "Initializing Hive Metastore schema (Derby)..."
echo "This may take a minute..."
echo ""

$HIVE_HOME/bin/schematool -dbType derby -initSchema

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Metastore schema initialized successfully!"
else
    echo ""
    echo "✗ Schema initialization failed"
    echo "Check error messages above"
    exit 1
fi
echo ""

# Start metastore service
echo "Starting Hive Metastore service..."
nohup hive --service metastore > /tmp/hive-metastore.log 2>&1 &
sleep 10

# Verify it's running
if ps aux | grep -q "[m]etastore"; then
    echo "✓ Metastore service started"
    ps aux | grep metastore | grep -v grep
else
    echo "✗ Failed to start metastore"
    echo "Check logs: tail -f /tmp/hive-metastore.log"
    exit 1
fi
echo ""

# Test Hive connection
echo "Testing Hive CLI connection..."
hive -e "SHOW DATABASES;" > /tmp/hive-test.txt 2>&1

if grep -q "default" /tmp/hive-test.txt; then
    echo "✓ Hive is working!"
    echo ""
    echo "Databases:"
    cat /tmp/hive-test.txt | grep -v "^SLF4J" | grep -v "^Logging" | grep -v "^Hive Session"
else
    echo "⚠ Hive test had issues. Output:"
    cat /tmp/hive-test.txt
fi
echo ""

echo "========================================================================"
echo "METASTORE INITIALIZATION COMPLETE!"
echo "========================================================================"
echo ""
echo "Metastore is now running on port 9083"
echo "Log file: /tmp/hive-metastore.log"
echo ""
echo "To check status:"
echo "  ps aux | grep metastore"
echo ""
echo "To stop metastore:"
echo "  pkill -f 'service metastore'"
echo ""
echo "To restart metastore:"
echo "  cd /usr/local/hive && nohup hive --service metastore > /tmp/hive-metastore.log 2>&1 &"
echo ""

