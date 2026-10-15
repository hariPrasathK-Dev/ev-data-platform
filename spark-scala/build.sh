#!/bin/bash
# Compile Scala Spark RDD Analysis

echo "======================================"
echo "Compiling Scala Spark Application"
echo "======================================"

# Find Spark installation
if [ -z "$SPARK_HOME" ]; then
    echo "Error: SPARK_HOME not set"
    echo "Please run as user 'hprasatk' who has Spark configured"
    exit 1
fi

echo "SPARK_HOME: $SPARK_HOME"
echo "Scala version: $(scala -version 2>&1 | head -1)"

# Compile
echo ""
echo "Compiling EVChargingRDDAnalysis.scala..."

scalac -classpath "$SPARK_HOME/jars/*" EVChargingRDDAnalysis.scala

if [ $? -eq 0 ]; then
    echo "✓ Compilation successful!"
    echo ""
    echo "Next step: Run ./run.sh"
else
    echo "✗ Compilation failed"
    exit 1
fi
