#!/bin/bash

##############################################################################
# Master Demo Script - HBase EV Charging Station Analytics
# Runs all demonstrations in sequence for project presentation
##############################################################################

echo "=========================================================================="
echo "HBase Project Demonstration"
echo "Application: EV Charging Station Availability Analytics"
echo "=========================================================================="
echo ""
echo "This script will demonstrate:"
echo "  1. Table creation and schema"
echo "  2. Data loading (sample records)"
echo "  3. Basic HBase operations (GET, SCAN, COUNT, DELETE)"
echo "  4. Analysis queries"
echo "  5. Filter demonstrations"
echo "  6. Java API execution"
echo ""
read -p "Press ENTER to start the demonstration..."
echo ""

# Set output directory for logs
OUTPUT_DIR="demo_output"
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

##############################################################################
# STEP 1: Environment Check
##############################################################################
echo "=========================================================================="
echo "STEP 1: Environment Check"
echo "=========================================================================="
echo ""

echo "Checking HBase installation..."
if ! command -v hbase &> /dev/null; then
    echo "ERROR: HBase command not found"
    exit 1
fi

hbase version 2>&1 | head -3
echo ""
echo "✓ HBase is available"
echo ""

echo "Checking Python..."
python3 --version
echo "✓ Python is available"
echo ""

echo "Checking Java..."
java -version 2>&1 | head -1
echo "✓ Java is available"
echo ""

read -p "Press ENTER to continue to table creation..."
echo ""

##############################################################################
# STEP 2: Table Creation
##############################################################################
echo "=========================================================================="
echo "STEP 2: HBase Table Creation"
echo "=========================================================================="
echo ""

echo "Creating table: ev_charging_stations"
echo "Column Families: cf_station, cf_metrics, cf_pricing, cf_weather, cf_context, cf_temporal"
echo ""

hbase shell create_table.hql 2>&1 | tee "$OUTPUT_DIR/01_table_creation_$TIMESTAMP.log"

echo ""
echo "✓ Table creation complete"
echo "Log saved: $OUTPUT_DIR/01_table_creation_$TIMESTAMP.log"
echo ""

read -p "Press ENTER to continue to data loading..."
echo ""

##############################################################################
# STEP 3: Data Loading
##############################################################################
echo "=========================================================================="
echo "STEP 3: Data Loading"
echo "=========================================================================="
echo ""

echo "Loading sample data (5000 records)..."
echo "This may take a few minutes..."
echo ""

bash load_sample_data.sh 2>&1 | tee "$OUTPUT_DIR/02_data_loading_$TIMESTAMP.log"

echo ""
echo "✓ Data loading complete"
echo "Log saved: $OUTPUT_DIR/02_data_loading_$TIMESTAMP.log"
echo ""

# Verify data count
echo "Verifying data..."
ROW_COUNT=$(echo "count 'ev_charging_stations'" | hbase shell 2>/dev/null | grep "row(s)" | awk '{print $1}')
echo "Total rows in table: $ROW_COUNT"
echo ""

read -p "Press ENTER to continue to basic operations..."
echo ""

##############################################################################
# STEP 4: Basic Operations
##############################################################################
echo "=========================================================================="
echo "STEP 4: Basic HBase Operations"
echo "=========================================================================="
echo ""

echo "Running basic operations: SCAN, COUNT, GET..."
echo ""

hbase shell queries_basic.hql 2>&1 | tee "$OUTPUT_DIR/03_basic_operations_$TIMESTAMP.log"

echo ""
echo "✓ Basic operations complete"
echo "Log saved: $OUTPUT_DIR/03_basic_operations_$TIMESTAMP.log"
echo ""

read -p "Press ENTER to continue to analysis queries..."
echo ""

##############################################################################
# STEP 5: Analysis Queries
##############################################################################
echo "=========================================================================="
echo "STEP 5: Analysis Queries"
echo "=========================================================================="
echo ""

echo "Running real-world analysis queries..."
echo "  - Current station status"
echo "  - Historical patterns"
echo "  - Pricing analysis"
echo "  - Weather impact"
echo "  - Peak hour utilization"
echo ""

hbase shell queries_analysis.hql 2>&1 | tee "$OUTPUT_DIR/04_analysis_queries_$TIMESTAMP.log"

echo ""
echo "✓ Analysis queries complete"
echo "Log saved: $OUTPUT_DIR/04_analysis_queries_$TIMESTAMP.log"
echo ""

read -p "Press ENTER to continue to filter demonstrations..."
echo ""

##############################################################################
# STEP 6: Filter Demonstrations
##############################################################################
echo "=========================================================================="
echo "STEP 6: HBase Filters"
echo "=========================================================================="
echo ""

echo "Demonstrating 10+ HBase filters..."
echo "  - SingleColumnValueFilter"
echo "  - PrefixFilter"
echo "  - ColumnPaginationFilter"
echo "  - RowFilter with RegexStringComparator"
echo "  - ValueFilter"
echo "  - FilterList (AND/OR)"
echo "  - And more..."
echo ""

hbase shell filters.hql 2>&1 | tee "$OUTPUT_DIR/05_filters_$TIMESTAMP.log"

echo ""
echo "✓ Filter demonstrations complete"
echo "Log saved: $OUTPUT_DIR/05_filters_$TIMESTAMP.log"
echo ""

read -p "Press ENTER to continue to Java API demo..."
echo ""

##############################################################################
# STEP 7: Java API Demonstration
##############################################################################
echo "=========================================================================="
echo "STEP 7: Java API Demonstration"
echo "=========================================================================="
echo ""

echo "Compiling and running Java program..."
echo "Program: HighUtilizationStationFinder.java"
echo ""

bash compile_and_run_java.sh 2>&1 | tee "$OUTPUT_DIR/06_java_api_$TIMESTAMP.log"

echo ""
echo "✓ Java API demonstration complete"
echo "Log saved: $OUTPUT_DIR/06_java_api_$TIMESTAMP.log"
echo ""

##############################################################################
# STEP 8: Summary
##############################################################################
echo ""
echo "=========================================================================="
echo "DEMONSTRATION COMPLETE"
echo "=========================================================================="
echo ""
echo "Summary of completed steps:"
echo "  ✓ Step 1: Environment verification"
echo "  ✓ Step 2: Table creation with 6 column families"
echo "  ✓ Step 3: Data loading ($ROW_COUNT rows)"
echo "  ✓ Step 4: Basic operations (SCAN, GET, COUNT, DELETE)"
echo "  ✓ Step 5: Analysis queries (12 business scenarios)"
echo "  ✓ Step 6: Filter demonstrations (10+ filters)"
echo "  ✓ Step 7: Java API execution"
echo ""
echo "All logs saved in: $OUTPUT_DIR/"
echo ""
echo "Output files:"
ls -lh "$OUTPUT_DIR/" | grep "$TIMESTAMP"
echo ""
echo "=========================================================================="
echo "Project Requirements Fulfilled:"
echo "=========================================================================="
echo "✓ Real-world dataset (EV Charging Station data - 1.3M records)"
echo "✓ HBase table with meaningful schema design"
echo "✓ Row key design: station_id#reverse_timestamp"
echo "✓ 6 column families with logical grouping"
echo "✓ Sample data insertion and display"
echo "✓ Meaningful queries for real-world application"
echo "✓ 10+ filters with business use cases"
echo "✓ Operations: GET, SCAN, DELETE, DELETEALL, COUNT"
echo "✓ Java API implementation (High Utilization Finder)"
echo "✓ Complete documentation and demonstration"
echo ""
echo "=========================================================================="
echo "Next Steps:"
echo "=========================================================================="
echo "1. Review logs in $OUTPUT_DIR/ directory"
echo "2. Run individual scripts for specific demonstrations"
echo "3. Modify Java program for additional analysis"
echo "4. Generate report with screenshots from logs"
echo ""
echo "Individual script commands:"
echo "  • Basic operations:  hbase shell queries_basic.hql"
echo "  • Analysis queries:  hbase shell queries_analysis.hql"
echo "  • Filters:          hbase shell filters.hql"
echo "  • Java API:         bash compile_and_run_java.sh"
echo ""
echo "=========================================================================="
