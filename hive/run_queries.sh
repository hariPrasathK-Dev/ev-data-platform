#!/bin/bash
#
# Execute All 15 Hive Analytical Queries
# RUN AS hduser
#

set -e  # Exit on error

echo "========================================================================"
echo "Executing 15 Hive Analytical Queries"
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

# Create output directory for results
OUTPUT_DIR="query_results_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "✓ Results will be saved to: $OUTPUT_DIR"
echo ""

# Verify table exists
echo "Verifying Hive table exists..."
TABLE_CHECK=$(hive -e "SHOW TABLES LIKE 'ev_charging_stations';" 2>/dev/null || echo "")

if [ -z "$TABLE_CHECK" ]; then
    echo "✗ Table 'ev_charging_stations' not found"
    echo "Please run ./run_hive_setup.sh first"
    exit 1
fi

echo "✓ Table 'ev_charging_stations' exists"
echo ""

# Execute all queries
echo "========================================================================"
echo "Executing queries..."
echo "========================================================================"
echo ""

START_TIME=$(date +%s)

# Note: We'll execute the full queries.hql file which contains all 15 queries
echo "Running all 15 queries from queries.hql..."
echo ""

hive -f queries.hql > "$OUTPUT_DIR/all_queries_output.txt" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ All queries executed successfully!"
else
    echo "⚠ Some queries may have failed. Check output file for details."
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "========================================================================"
echo "Query Execution Complete!"
echo "========================================================================"
echo "Total execution time: ${DURATION} seconds"
echo ""

# Display summary
echo "Results saved to: $OUTPUT_DIR/all_queries_output.txt"
echo ""

# Create a summary file
cat > "$OUTPUT_DIR/SUMMARY.txt" << EOF
===========================================================================
Hive Query Execution Summary
===========================================================================
Execution Date: $(date)
Execution Duration: ${DURATION} seconds
Output Directory: $OUTPUT_DIR

Queries Executed:
1. Peak Utilization Hours
2. Network Performance Comparison
3. High-Demand Stations
4. Weekend vs Weekday Demand
5. Weather Impact on Charging Demand
6. Location Type Performance
7. Peak Hours by Network
8. Pricing Model Effectiveness
9. Charger Type Demand Analysis
10. State-Level Demand Analysis
11. Traffic Congestion Impact
12. Port Utilization Efficiency
13. Monthly Trend Analysis
14. Station Reliability Analysis
15. Comprehensive Business Intelligence Summary

SQL Operators Covered:
✓ SELECT, WHERE, ORDER BY, GROUP BY, HAVING
✓ COUNT, SUM, AVG, MAX, MIN
✓ CASE expressions, DISTINCT, ROUND, LIMIT

Output File: all_queries_output.txt
===========================================================================
EOF

echo "✓ Summary saved to: $OUTPUT_DIR/SUMMARY.txt"
echo ""

# Show preview of results
echo "Preview of query results (first 50 lines):"
echo "========================================================================"
head -50 "$OUTPUT_DIR/all_queries_output.txt"
echo "========================================================================"
echo ""
echo "View full results:"
echo "  cat $OUTPUT_DIR/all_queries_output.txt"
echo ""
echo "Or execute individual queries interactively:"
echo "  hive"
echo "  hive> USE default;"
echo "  hive> SELECT * FROM ev_charging_stations LIMIT 10;"
echo ""

# Save output directory path
echo "$OUTPUT_DIR" > last_query_results_dir.txt
echo "✓ Output directory path saved to last_query_results_dir.txt"
echo ""
