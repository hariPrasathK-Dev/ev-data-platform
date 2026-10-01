#!/bin/bash

##############################################################################
# Compile and Run HBase Java API Program
# Application: High Utilization Station Finder
##############################################################################

echo "========================================================================"
echo "HBase Java API - Compilation and Execution"
echo "Program: HighUtilizationStationFinder.java"
echo "========================================================================"
echo ""

# Configuration
JAVA_FILE="HighUtilizationStationFinder.java"
CLASS_NAME="HighUtilizationStationFinder"
JAR_NAME="EVChargingStationAnalyzer.jar"

# Check if Java source file exists
if [ ! -f "$JAVA_FILE" ]; then
    echo "ERROR: Java source file not found: $JAVA_FILE"
    exit 1
fi

echo "Step 1: Checking Java environment..."
java -version
if [ $? -ne 0 ]; then
    echo "ERROR: Java is not installed or not in PATH"
    exit 1
fi
echo "✓ Java is available"
echo ""

echo "Step 2: Checking HBase environment..."
if [ -z "$HBASE_HOME" ]; then
    echo "WARNING: HBASE_HOME not set, trying to detect..."
    # Try common HBase locations
    if [ -d "/usr/local/hbase" ]; then
        export HBASE_HOME="/usr/local/hbase"
    elif [ -d "$HOME/hbase" ]; then
        export HBASE_HOME="$HOME/hbase"
    else
        echo "ERROR: Cannot find HBase installation"
        echo "Please set HBASE_HOME environment variable"
        exit 1
    fi
fi

echo "HBASE_HOME: $HBASE_HOME"
echo "✓ HBase home found"
echo ""

echo "Step 3: Setting up HBase classpath..."
# Get HBase classpath
HBASE_CP=$(hbase classpath 2>/dev/null)
if [ -z "$HBASE_CP" ]; then
    echo "ERROR: Failed to get HBase classpath"
    echo "Please ensure HBase is properly installed and hbase command is available"
    exit 1
fi
echo "✓ HBase classpath configured"
echo ""

echo "Step 4: Compiling Java program..."
echo "Compiling: $JAVA_FILE"
echo ""

javac -cp "$HBASE_CP" "$JAVA_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Compilation successful"
    echo "Generated: ${CLASS_NAME}.class"
else
    echo ""
    echo "ERROR: Compilation failed"
    echo "Please check the Java source code for errors"
    exit 1
fi
echo ""

echo "Step 5: Creating JAR file..."
jar cf "$JAR_NAME" *.class
if [ $? -eq 0 ]; then
    echo "✓ JAR created: $JAR_NAME"
else
    echo "WARNING: JAR creation failed, will run with .class files"
fi
echo ""

echo "Step 6: Running HBase Java API program..."
echo "========================================================================"
echo ""

# Run the program
java -cp "$HBASE_CP:." "$CLASS_NAME"

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================================================"
    echo "✓ Program executed successfully"
    echo "========================================================================"
else
    echo ""
    echo "========================================================================"
    echo "ERROR: Program execution failed"
    echo "Please check:"
    echo "  1. HBase is running (run: start-hbase.sh)"
    echo "  2. Table 'ev_charging_stations' exists"
    echo "  3. Data is loaded into the table"
    echo "========================================================================"
    exit 1
fi

echo ""
echo "Output files:"
echo "  - ${CLASS_NAME}.class (compiled class)"
echo "  - ${JAR_NAME} (executable JAR)"
echo ""
echo "To run again: java -cp \$(hbase classpath):. $CLASS_NAME"
echo "Or with JAR: java -cp \$(hbase classpath):$JAR_NAME $CLASS_NAME"
echo ""
