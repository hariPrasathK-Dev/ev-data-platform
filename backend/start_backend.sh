#!/bin/bash
#
# Start FastAPI Backend Server
# RUN AS hduser
#

set -e

echo "========================================================================"
echo "Starting EV Charging Analytics Backend API"
echo "========================================================================"
echo ""

# Set environment variables for Hadoop and Hive
export HADOOP_HOME=${HADOOP_HOME:-/usr/local/hadoop}
export HIVE_HOME=${HIVE_HOME:-/usr/local/hive}
export JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java-8-openjdk-amd64}
export PATH=$HADOOP_HOME/bin:$HIVE_HOME/bin:$JAVA_HOME/bin:$PATH

echo "Environment:"
echo "  HADOOP_HOME: $HADOOP_HOME"
echo "  HIVE_HOME: $HIVE_HOME"
echo "  JAVA_HOME: $JAVA_HOME"
echo ""

# Check if running as hduser
CURRENT_USER=$(whoami)
if [ "$CURRENT_USER" != "hduser" ]; then
    echo "⚠ Warning: Should be run as 'hduser' for HDFS/Hive access"
    echo "Current user: $CURRENT_USER"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "✓ User: $CURRENT_USER"
echo ""

# Check if in correct directory
if [ ! -f "main.py" ]; then
    echo "ERROR: main.py not found"
    echo "Please run from backend/ directory"
    exit 1
fi

echo "✓ In correct directory"
echo ""

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 not found"
    exit 1
fi

echo "✓ Python 3 found: $(python3 --version)"
echo ""
# Check Hadoop services
echo "Checking Hadoop services..."
if command -v jps &> /dev/null; then
    JPS_OUTPUT=$(jps)
    if echo "$JPS_OUTPUT" | grep -q "NameNode"; then
        echo "✓ HDFS is running"
    else
        echo "⚠ HDFS may not be running"
        echo "  Start with: start-dfs.sh"
    fi
    
    if echo "$JPS_OUTPUT" | grep -q "ResourceManager"; then
        echo "✓ YARN is running"
    else
        echo "⚠ YARN may not be running"
        echo "  Start with: start-yarn.sh"
    fi
else
    echo "⚠ JPS command not found, cannot check Hadoop services"
fi
echo ""

# Check Hive
echo "Checking Hive..."
if command -v hive &> /dev/null; then
    echo "✓ Hive CLI found: $(which hive)"
else
    echo "⚠ Hive CLI not found in PATH"
    echo "  Make sure HIVE_HOME is set and Hive is installed"
fi
echo "" echo "  Start with: /usr/local/hadoop/sbin/start-dfs.sh"
    fi
    
    if echo "$JPS_OUTPUT" | grep -q "ResourceManager"; then
        echo "✓ YARN is running"
    else
        echo "⚠ YARN may not be running"
        echo "  Start with: /usr/local/hadoop/sbin/start-yarn.sh"
    fi
else
    echo "⚠ JPS command not found, cannot check Hadoop services"
fi
echo ""

# Display configuration
echo "========================================================================"
echo "Backend Configuration"
echo "========================================================================"
echo "Host: 0.0.0.0"
echo "Port: 8000"
echo "API Docs: http://localhost:8000/api/docs"
echo "Health Check: http://localhost:8000/api/health"
echo ""
echo "Endpoints:"
echo "  - HDFS: /api/hdfs/*"
echo "  - MapReduce: /api/mapreduce/*"
echo "  - Hive: /api/hive/*"
echo "  - WebSocket: /ws/mapreduce/{job_id}"
echo "========================================================================"
echo ""

# Start server
echo "Starting FastAPI server..."
echo "Press Ctrl+C to stop"
echo ""

python3 main.py

# Alternative using uvicorn directly:
# uvicorn main:app --host 0.0.0.0 --port 8000 --reload
