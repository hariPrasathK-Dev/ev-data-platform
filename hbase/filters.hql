# ==============================================================================
# HBase Filters - EV Charging Station Analytics
# Demonstrates 6+ meaningful filters for real-world applications
# ==============================================================================

echo "=========================================================================="
echo "HBase Filter Demonstrations"
echo "Application: EV Charging Station Availability Analytics"
echo "=========================================================================="
echo ""

# ==============================================================================
# FILTER 1: SingleColumnValueFilter - High Utilization Stations
# ==============================================================================
echo "--- Filter 1: SingleColumnValueFilter - High Utilization Stations ---"
echo "Use Case: Find stations with utilization > 80% (congested stations)"
echo "Business Value: Identify stations needing capacity expansion"
echo ""
echo "Query: Find all records with utilization_rate > 0.8"
echo ""

scan 'ev_charging_stations', {LIMIT => 10, FILTER => "SingleColumnValueFilter('cf_metrics', 'utilization_rate', >, 'binary:0.8')"}

echo ""
echo "Alternative: High utilization with available details"
scan 'ev_charging_stations', {LIMIT => 10, FILTER => "SingleColumnValueFilter('cf_metrics', 'utilization_rate', >, 'binary:0.8')", COLUMNS => ['cf_station:name', 'cf_station:city', 'cf_metrics:utilization_rate', 'cf_metrics:ports_available', 'cf_temporal:timestamp']}

# ==============================================================================
# FILTER 2: SingleColumnValueFilter - Extreme Weather Conditions
# ==============================================================================
echo ""
echo ""
echo "--- Filter 2: SingleColumnValueFilter - Extreme Weather Impact ---"
echo "Use Case: Analyze station performance during extreme weather"
echo "Business Value: Understand weather impact on charging demand"
echo ""
echo "Query: Find records during extreme heat (temperature > 95°F)"
echo ""

scan 'ev_charging_stations', {LIMIT => 15, FILTER => "SingleColumnValueFilter('cf_weather', 'temperature_f', >, 'binary:95')", COLUMNS => ['cf_station:name', 'cf_weather:temperature_f', 'cf_weather:weather_condition', 'cf_metrics:utilization_rate']}

# ==============================================================================
# FILTER 3: PrefixFilter - Station-Specific Queries
# ==============================================================================
echo ""
echo ""
echo "--- Filter 3: PrefixFilter - All Records for Specific Station ---"
echo "Use Case: Retrieve complete time-series data for a single station"
echo "Business Value: Deep-dive analysis for individual station performance"
echo ""
echo "Query: Get all records for station EV00001"
echo ""

scan 'ev_charging_stations', {LIMIT => 10, FILTER => "PrefixFilter('EV00001#')", COLUMNS => ['cf_temporal:timestamp', 'cf_metrics:utilization_rate', 'cf_metrics:ports_available']}

echo ""
echo "Alternative: Multiple station prefixes using FilterList"
echo "Query: Get records for stations EV00001 through EV00010"
scan 'ev_charging_stations', {LIMIT => 20, FILTER => "PrefixFilter('EV0001')"}

# ==============================================================================
# FILTER 4: ColumnPaginationFilter - Limit Column Results
# ==============================================================================
echo ""
echo ""
echo "--- Filter 4: ColumnPaginationFilter - Paginated Column Access ---"
echo "Use Case: Retrieve subset of columns to reduce bandwidth"
echo "Business Value: Optimize data transfer for mobile apps"
echo ""
echo "Query: Get first 5 columns from each row"
echo ""

scan 'ev_charging_stations', {LIMIT => 5, FILTER => "ColumnPaginationFilter(5, 0)"}

# ==============================================================================
# FILTER 5: RowFilter with RegexStringComparator - Pattern Matching
# ==============================================================================
echo ""
echo ""
echo "--- Filter 5: RowFilter with RegexStringComparator - Pattern Match ---"
echo "Use Case: Find stations in specific ID range or pattern"
echo "Business Value: Query stations by deployment batch or region code"
echo ""
echo "Query: Find all records for stations EV00010-EV00019"
echo ""

scan 'ev_charging_stations', {LIMIT => 15, FILTER => "RowFilter(=, 'regexstring:EV0001[0-9]#')", COLUMNS => ['cf_station:name', 'cf_station:city']}

# ==============================================================================
# FILTER 6: ValueFilter - Find Specific Values
# ==============================================================================
echo ""
echo ""
echo "--- Filter 6: ValueFilter - Operational Status Filter ---"
echo "Use Case: Find stations currently under maintenance"
echo "Business Value: Operations team monitoring for service issues"
echo ""
echo "Query: Find records with any value matching 'under_maintenance'"
echo ""

scan 'ev_charging_stations', {LIMIT => 10, FILTER => "ValueFilter(=, 'substring:under_maintenance')", COLUMNS => ['cf_station:name', 'cf_metrics:station_status', 'cf_metrics:ports_out_of_service', 'cf_temporal:timestamp']}

echo ""
echo "Alternative: Find offline stations"
scan 'ev_charging_stations', {LIMIT => 10, FILTER => "ValueFilter(=, 'substring:offline')", COLUMNS => ['cf_station:name', 'cf_metrics:station_status', 'cf_temporal:timestamp']}

# ==============================================================================
# FILTER 7: FilterList - Combine Multiple Filters (AND Logic)
# ==============================================================================
echo ""
echo ""
echo "--- Filter 7: FilterList (AND) - Complex Multi-Condition Query ---"
echo "Use Case: Find high-utilization stations during peak hours"
echo "Business Value: Identify critical congestion periods for infrastructure planning"
echo ""
echo "Query: Utilization > 0.7 AND is_peak_hour = True"
echo ""

scan 'ev_charging_stations', {LIMIT => 10, FILTER => "FilterList(MUST_PASS_ALL, SingleColumnValueFilter('cf_metrics', 'utilization_rate', >, 'binary:0.7'), SingleColumnValueFilter('cf_temporal', 'is_peak_hour', =, 'binary:True'))", COLUMNS => ['cf_station:name', 'cf_temporal:hour', 'cf_temporal:is_peak_hour', 'cf_metrics:utilization_rate', 'cf_metrics:wait_time_mins']}

# ==============================================================================
# FILTER 8: FilterList - Multiple Filters (OR Logic)
# ==============================================================================
echo ""
echo ""
echo "--- Filter 8: FilterList (OR) - Station Issues Detection ---"
echo "Use Case: Find stations with any operational issues"
echo "Business Value: Alert system for maintenance teams"
echo ""
echo "Query: station_status = 'offline' OR station_status = 'under_maintenance'"
echo ""

scan 'ev_charging_stations', {LIMIT => 15, FILTER => "FilterList(MUST_PASS_ONE, ValueFilter(=, 'substring:offline'), ValueFilter(=, 'substring:under_maintenance'))", COLUMNS => ['cf_station:name', 'cf_metrics:station_status', 'cf_metrics:ports_out_of_service', 'cf_temporal:timestamp']}

# ==============================================================================
# FILTER 9: ColumnRangeFilter - Select Column Range
# ==============================================================================
echo ""
echo ""
echo "--- Filter 9: ColumnRangeFilter - Select Specific Column Range ---"
echo "Use Case: Retrieve only port-related metrics"
echo "Business Value: Focused data extraction for specific analytics"
echo ""
echo "Query: Get all metrics columns starting with 'ports_'"
echo ""

scan 'ev_charging_stations', {LIMIT => 5, FILTER => "ColumnRangeFilter('ports_available', true, 'ports_total', true)"}

# ==============================================================================
# FILTER 10: TimestampsFilter - Version-Based Filtering
# ==============================================================================
echo ""
echo ""
echo "--- Filter 10: FirstKeyOnlyFilter - Count Rows Efficiently ---"
echo "Use Case: Fast row counting without fetching all data"
echo "Business Value: Optimize count operations for large datasets"
echo ""
echo "Query: Count rows efficiently by fetching only row keys"
echo ""

scan 'ev_charging_stations', {LIMIT => 20, FILTER => "FirstKeyOnlyFilter()"}

# ==============================================================================
# ADVANCED FILTERS: Complex Business Scenarios
# ==============================================================================
echo ""
echo ""
echo "=========================================================================="
echo "ADVANCED FILTER COMBINATIONS"
echo "=========================================================================="
echo ""

# ==============================================================================
# ADVANCED FILTER 1: Weekend High-Demand Analysis
# ==============================================================================
echo "--- Advanced Filter 1: Weekend High-Demand Stations ---"
echo "Use Case: Find stations with high utilization on weekends"
echo "Business Value: Weekend capacity planning"
echo ""

scan 'ev_charging_stations', {LIMIT => 10, FILTER => "FilterList(MUST_PASS_ALL, SingleColumnValueFilter('cf_temporal', 'is_weekend', =, 'binary:True'), SingleColumnValueFilter('cf_metrics', 'utilization_rate', >, 'binary:0.6'))", COLUMNS => ['cf_station:name', 'cf_temporal:is_weekend', 'cf_temporal:day_of_week', 'cf_metrics:utilization_rate']}

# ==============================================================================
# ADVANCED FILTER 2: High Traffic + High Price Analysis
# ==============================================================================
echo ""
echo ""
echo "--- Advanced Filter 2: Dynamic Pricing Impact Analysis ---"
echo "Use Case: Analyze stations with high traffic congestion and surge pricing"
echo "Business Value: Pricing strategy optimization"
echo ""

scan 'ev_charging_stations', {LIMIT => 10, FILTER => "FilterList(MUST_PASS_ALL, SingleColumnValueFilter('cf_context', 'traffic_index', >, 'binary:7'), SingleColumnValueFilter('cf_pricing', 'current_price', >, 'binary:0.3'))", COLUMNS => ['cf_station:name', 'cf_context:traffic_index', 'cf_pricing:current_price', 'cf_metrics:utilization_rate']}

# ==============================================================================
# ADVANCED FILTER 3: Low Availability Alert System
# ==============================================================================
echo ""
echo ""
echo "--- Advanced Filter 3: Low Availability Alert ---"
echo "Use Case: Real-time alert when available ports are critically low"
echo "Business Value: Customer service - redirect users to available stations"
echo ""

scan 'ev_charging_stations', {LIMIT => 15, FILTER => "FilterList(MUST_PASS_ALL, SingleColumnValueFilter('cf_metrics', 'ports_available', <, 'binary:2'), SingleColumnValueFilter('cf_metrics', 'station_status', =, 'binary:operational'))", COLUMNS => ['cf_station:name', 'cf_station:city', 'cf_metrics:ports_available', 'cf_metrics:ports_total', 'cf_metrics:wait_time_mins']}

# ==============================================================================
# ADVANCED FILTER 4: Special Event Impact
# ==============================================================================
echo ""
echo ""
echo "--- Advanced Filter 4: Event Impact on Charging Demand ---"
echo "Use Case: Analyze charging patterns during local events"
echo "Business Value: Event-based resource allocation planning"
echo ""

scan 'ev_charging_stations', {LIMIT => 10, FILTER => "FilterList(MUST_PASS_ALL, SingleColumnValueFilter('cf_context', 'local_event', !=, 'binary:none'), SingleColumnValueFilter('cf_metrics', 'utilization_rate', >, 'binary:0.5'))", COLUMNS => ['cf_station:name', 'cf_context:local_event', 'cf_metrics:utilization_rate', 'cf_temporal:timestamp']}

# ==============================================================================
# SUMMARY OF FILTERS DEMONSTRATED
# ==============================================================================
echo ""
echo ""
echo "=========================================================================="
echo "FILTER SUMMARY"
echo "=========================================================================="
echo ""
echo "Filters Demonstrated:"
echo "  1. SingleColumnValueFilter - Numeric comparison (utilization > 0.8)"
echo "  2. SingleColumnValueFilter - Weather conditions (temperature > 95)"
echo "  3. PrefixFilter - Station-specific queries"
echo "  4. ColumnPaginationFilter - Limited column retrieval"
echo "  5. RowFilter with RegexStringComparator - Pattern matching"
echo "  6. ValueFilter - Status-based filtering"
echo "  7. FilterList (AND) - Peak hour high utilization"
echo "  8. FilterList (OR) - Operational issues detection"
echo "  9. ColumnRangeFilter - Column range selection"
echo " 10. FirstKeyOnlyFilter - Efficient counting"
echo ""
echo "Advanced Combinations:"
echo "  - Weekend demand analysis"
echo "  - Dynamic pricing impact"
echo "  - Low availability alerts"
echo "  - Event impact analysis"
echo ""
echo "Real-World Applications:"
echo "  • Capacity planning and expansion decisions"
echo "  • Real-time availability monitoring"
echo "  • Dynamic pricing optimization"
echo "  • Maintenance scheduling"
echo "  • Customer experience enhancement"
echo "  • Business intelligence and reporting"
echo ""
echo "=========================================================================="
