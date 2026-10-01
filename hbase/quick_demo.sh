#!/bin/bash

##############################################################################
# Quick Demo Script - Fast demonstration without pauses
# For quick testing and validation
##############################################################################

echo "=========================================================================="
echo "Quick Demo - HBase EV Charging Station Analytics"
echo "=========================================================================="
echo ""

# Check HBase
if ! command -v hbase &> /dev/null; then
    echo "ERROR: HBase not found"
    exit 1
fi

echo "✓ HBase available"
echo ""

##############################################################################
# 1. Table Status
##############################################################################
echo "--- 1. Table Status ---"
echo ""
echo "list" | hbase shell 2>/dev/null | grep "ev_charging_stations"
echo ""

##############################################################################
# 2. Row Count
##############################################################################
echo "--- 2. Row Count ---"
echo ""
echo "count 'ev_charging_stations', INTERVAL => 10000" | hbase shell 2>/dev/null | grep "row(s)"
echo ""

##############################################################################
# 3. Sample Data
##############################################################################
echo "--- 3. Sample Data (First 3 rows) ---"
echo ""
echo "scan 'ev_charging_stations', {LIMIT => 3, COLUMNS => ['cf_station:name', 'cf_metrics:utilization_rate', 'cf_temporal:timestamp']}" | hbase shell
echo ""

##############################################################################
# 4. High Utilization Query
##############################################################################
echo "--- 4. High Utilization Stations (>80%) ---"
echo ""
echo "scan 'ev_charging_stations', {LIMIT => 5, FILTER => \"SingleColumnValueFilter('cf_metrics', 'utilization_rate', >, 'binary:0.8')\", COLUMNS => ['cf_station:name', 'cf_metrics:utilization_rate']}" | hbase shell
echo ""

##############################################################################
# 5. Station Info Query
##############################################################################
echo "--- 5. Station Information ---"
echo ""
echo "scan 'ev_charging_stations', {STARTROW => 'EV00001#', LIMIT => 2, COLUMNS => 'cf_station'}" | hbase shell
echo ""

##############################################################################
# 6. Metrics Query
##############################################################################
echo "--- 6. Availability Metrics ---"
echo ""
echo "scan 'ev_charging_stations', {LIMIT => 3, COLUMNS => ['cf_metrics:ports_available', 'cf_metrics:ports_total', 'cf_metrics:utilization_rate', 'cf_metrics:station_status']}" | hbase shell
echo ""

##############################################################################
# Summary
##############################################################################
echo "=========================================================================="
echo "Quick Demo Complete"
echo "=========================================================================="
echo ""
echo "For full demonstration with all features:"
echo "  bash run_all_demos.sh"
echo ""
echo "For individual components:"
echo "  • Basic operations:  hbase shell queries_basic.hql"
echo "  • Analysis:         hbase shell queries_analysis.hql"
echo "  • Filters:          hbase shell filters.hql"
echo "  • Java API:         bash compile_and_run_java.sh"
echo ""
