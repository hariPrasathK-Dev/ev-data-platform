#!/bin/bash
#
# Compile All 3 Hadoop MapReduce Java Programs
# RUN AS hduser
#

set -e  # Exit on error

echo "========================================================================"
echo "Compiling All 3 MapReduce Programs"
echo "========================================================================"
echo ""

# Check if running as hduser
CURRENT_USER=$(whoami)
if [ "$CURRENT_USER" != "hduser" ]; then
    echo "ERROR: This script must be run as 'hduser', not '$CURRENT_USER'"
    exit 1
fi

# Verify HADOOP_HOME is set
if [ -z "$HADOOP_HOME" ]; then
    echo "ERROR: HADOOP_HOME is not set"
    echo "Setting HADOOP_HOME=/usr/local/hadoop"
    export HADOOP_HOME=/usr/local/hadoop
fi

echo "✓ HADOOP_HOME=$HADOOP_HOME"
echo ""

# Clean previous builds
echo "Cleaning previous build artifacts..."
rm -rf classes
rm -f *.jar
echo "✓ Clean complete"
echo ""

# Create classes directory
echo "Creating classes directory..."
mkdir -p classes
echo "✓ Directory created"
echo ""

# ========== Program 1: StationUtilizationAnalysis ==========
echo "========================================================================"
echo "1/3: Compiling StationUtilizationAnalysis.java"
echo "========================================================================"
javac -classpath `$HADOOP_HOME/bin/hadoop classpath` -d classes StationUtilizationAnalysis.java

if [ $? -eq 0 ]; then
    echo "✓ Compilation successful!"
    jar -cvf StationUtilizationAnalysis.jar -C classes .
    echo "✓ JAR created: StationUtilizationAnalysis.jar"
else
    echo "✗ Compilation failed!"
    exit 1
fi
echo ""

# Clean classes for next program
rm -rf classes/*

# ========== Program 2: WeatherImpactAnalysis ==========
echo "========================================================================"
echo "2/3: Compiling WeatherImpactAnalysis.java"
echo "========================================================================"
javac -classpath `$HADOOP_HOME/bin/hadoop classpath` -d classes WeatherImpactAnalysis.java

if [ $? -eq 0 ]; then
    echo "✓ Compilation successful!"
    jar -cvf WeatherImpactAnalysis.jar -C classes .
    echo "✓ JAR created: WeatherImpactAnalysis.jar"
else
    echo "✗ Compilation failed!"
    exit 1
fi
echo ""

# Clean classes for next program
rm -rf classes/*

# ========== Program 3: StationReliabilityAnalysis ==========
echo "========================================================================"
echo "3/3: Compiling StationReliabilityAnalysis.java"
echo "========================================================================"
javac -classpath `$HADOOP_HOME/bin/hadoop classpath` -d classes StationReliabilityAnalysis.java

if [ $? -eq 0 ]; then
    echo "✓ Compilation successful!"
    jar -cvf StationReliabilityAnalysis.jar -C classes .
    echo "✓ JAR created: StationReliabilityAnalysis.jar"
else
    echo "✗ Compilation failed!"
    exit 1
fi
echo ""

# Show build artifacts
echo "========================================================================"
echo "ALL 3 PROGRAMS COMPILED SUCCESSFULLY!"
echo "========================================================================"
echo ""
echo "Build Artifacts:"
ls -lh *.jar
echo ""
echo "JAR files created:"
echo "  1. StationUtilizationAnalysis.jar - Network-hour utilization patterns"
echo "  2. WeatherImpactAnalysis.jar - Weather impact on charging demand"
echo "  3. StationReliabilityAnalysis.jar - Station uptime/reliability"
echo ""
echo "Next steps:"
echo "  1. Ensure HDFS dataset is uploaded: ../phase2_upload_to_hdfs.sh"
echo "  2. Run all jobs: ./run_mapreduce.sh"
echo ""
