#!/bin/bash
# Check ML dependencies

echo "Checking ML dependencies..."
echo ""

# Check Python
echo "1. Python version:"
python3 --version
echo ""

# Check PySpark
echo "2. Checking PySpark..."
python3 -c "import pyspark; print('   ✓ PySpark', pyspark.__version__)" 2>&1 || echo "   ✗ PySpark not found"

# Check if spark-submit works
echo ""
echo "3. Checking spark-submit..."
which spark-submit && echo "   ✓ spark-submit found" || echo "   ✗ spark-submit not found"

echo ""
echo "---"
echo ""

# If PySpark not found, show installation
if ! python3 -c "import pyspark" 2>/dev/null; then
    echo "PySpark not installed. Install with:"
    echo ""
    echo "  pip3 install pyspark --user"
    echo ""
    echo "OR if you have Spark installed separately, PySpark should work"
    echo "with SPARK_HOME environment variable set."
else
    echo "✓ All dependencies ready!"
    echo ""
    echo "You can now run: ./run_training.sh"
fi
