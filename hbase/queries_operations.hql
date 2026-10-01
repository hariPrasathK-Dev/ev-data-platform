# ==============================================================================
# HBase Operations Demo - GET, DELETE, DELETEALL with Real Examples
# ==============================================================================

# -----------------------------------------------------------------------------
# PART 1: GET Operations
# -----------------------------------------------------------------------------

echo "=========================================================================="
echo "PART 1: GET OPERATIONS"
echo "=========================================================================="
echo ""

# First, scan to get some valid row keys
echo "Step 1: Getting sample row keys for GET demonstrations..."
scan 'ev_charging_stations', {LIMIT => 3, COLUMNS => 'cf_station:name'}

echo ""
echo "--- GET Operation 1: Retrieve Complete Row ---"
echo "Description: Get all column families for a specific row"
echo "# Syntax: get 'table_name', 'row_key'"
echo "# Example: get 'ev_charging_stations', 'EV00001#9223370511254775807'"
echo ""

echo "--- GET Operation 2: Get Specific Column Family ---"
echo "Description: Retrieve only station information"
echo "# Syntax: get 'table_name', 'row_key', {COLUMNS => 'cf_name'}"
echo "# Example: get 'ev_charging_stations', 'EV00001#9223370511254775807', {COLUMNS => 'cf_station'}"
echo ""

echo "--- GET Operation 3: Get Specific Columns ---"
echo "Description: Retrieve only specific columns"
echo "# Syntax: get 'table_name', 'row_key', {COLUMNS => ['cf:col1', 'cf:col2']}"
echo "# Example: get 'ev_charging_stations', 'EV00001#9223370511254775807', {COLUMNS => ['cf_metrics:utilization_rate', 'cf_pricing:current_price']}"
echo ""

# -----------------------------------------------------------------------------
# PART 2: DELETE Operations (Commented for Safety)
# -----------------------------------------------------------------------------

echo ""
echo "=========================================================================="
echo "PART 2: DELETE OPERATIONS"
echo "=========================================================================="
echo ""

echo "--- DELETE Operation 1: Delete Specific Column ---"
echo "Description: Remove a single column value from a row"
echo "Use Case: Remove outdated or incorrect data point"
echo "# Syntax: delete 'table_name', 'row_key', 'cf:column'"
echo ""
echo "# Example 1: Delete wait time data"
echo "# delete 'ev_charging_stations', 'EV00001#9223370511254775807', 'cf_metrics:wait_time_mins'"
echo ""
echo "# Example 2: Delete weather condition"
echo "# delete 'ev_charging_stations', 'EV00001#9223370511254775807', 'cf_weather:weather_condition'"
echo ""

echo "--- DELETE Operation 2: Delete Multiple Columns ---"
echo "Description: Remove multiple columns from same row"
echo "Use Case: Clean up corrupted data fields"
echo ""
echo "# delete 'ev_charging_stations', 'ROW_KEY', 'cf_metrics:wait_time_mins'"
echo "# delete 'ev_charging_stations', 'ROW_KEY', 'cf_metrics:avg_session_mins'"
echo ""

echo "--- DELETE Operation 3: Delete Entire Column Family ---"
echo "Description: Remove all columns in a column family for a row"
echo "Use Case: Remove sensitive or deprecated data family"
echo ""
echo "# delete 'ev_charging_stations', 'ROW_KEY', 'cf_weather'"
echo ""

# -----------------------------------------------------------------------------
# PART 3: DELETEALL Operations (Commented for Safety)
# -----------------------------------------------------------------------------

echo ""
echo "=========================================================================="
echo "PART 3: DELETEALL OPERATIONS"
echo "=========================================================================="
echo ""

echo "--- DELETEALL Operation 1: Delete Complete Row ---"
echo "Description: Remove all data for a specific timestamp entry"
echo "Use Case: Remove erroneous reading from a specific time"
echo "# Syntax: deleteall 'table_name', 'row_key'"
echo ""
echo "# Example: Delete specific station reading"
echo "# deleteall 'ev_charging_stations', 'EV00001#9223370511254775807'"
echo ""

echo "--- DELETEALL Operation 2: Delete Multiple Rows ---"
echo "Description: Remove several rows (must be done individually)"
echo "Use Case: Clean up test data or corrupted time series"
echo ""
echo "# deleteall 'ev_charging_stations', 'EV00001#9223370511254775807'"
echo "# deleteall 'ev_charging_stations', 'EV00001#9223370511254775806'"
echo "# deleteall 'ev_charging_stations', 'EV00001#9223370511254775805'"
echo ""

echo "--- DELETEALL Operation 3: Delete All Records for a Station ---"
echo "Description: Remove all historical data for a decommissioned station"
echo "Use Case: Station permanently closed or data privacy requirements"
echo ""
echo "# Note: HBase doesn't support bulk delete by prefix in shell"
echo "# This requires scanning and deleting in a loop or using Java API"
echo "# Example approach in shell:"
echo "# scan 'ev_charging_stations', {STARTROW => 'EV00001#', STOPROW => 'EV00001~'}"
echo "# Then deleteall for each row key returned"
echo ""

# -----------------------------------------------------------------------------
# PART 4: Practical DELETE/DELETEALL Examples
# -----------------------------------------------------------------------------

echo ""
echo "=========================================================================="
echo "PART 4: PRACTICAL DELETE SCENARIOS"
echo "=========================================================================="
echo ""

echo "--- Scenario 1: Remove Maintenance Period Data ---"
echo "Use Case: Station was under maintenance, remove invalid readings"
echo "# 1. Identify rows during maintenance period"
echo "# scan 'ev_charging_stations', {STARTROW => 'EV00050#', STOPROW => 'EV00050~', LIMIT => 10}"
echo "# 2. Delete rows with station_status = 'under_maintenance'"
echo "# deleteall 'ev_charging_stations', 'IDENTIFIED_ROW_KEY'"
echo ""

echo "--- Scenario 2: Clean Up Test Data ---"
echo "Use Case: Remove test records before production deployment"
echo "# Identify test station (e.g., EV99999)"
echo "# scan 'ev_charging_stations', {STARTROW => 'EV99999#', STOPROW => 'EV99999~'}"
echo "# Delete all test records"
echo "# deleteall 'ev_charging_stations', 'TEST_ROW_KEY'"
echo ""

echo "--- Scenario 3: Delete Specific Column Across Multiple Rows ---"
echo "Use Case: Remove deprecated field from all records"
echo "# This requires programmatic approach (Java API or script)"
echo "# Scan all rows and delete specific column from each"
echo ""

echo "--- Scenario 4: Partial Row Update (Delete + Put) ---"
echo "Use Case: Correct erroneous data"
echo "# Step 1: Delete incorrect value"
echo "# delete 'ev_charging_stations', 'ROW_KEY', 'cf_metrics:utilization_rate'"
echo "# Step 2: Insert correct value"
echo "# put 'ev_charging_stations', 'ROW_KEY', 'cf_metrics:utilization_rate', '0.75'"
echo ""

# -----------------------------------------------------------------------------
# PART 5: COUNT Operations
# -----------------------------------------------------------------------------

echo ""
echo "=========================================================================="
echo "PART 5: COUNT OPERATIONS"
echo "=========================================================================="
echo ""

echo "--- COUNT Operation 1: Total Table Count ---"
echo "Description: Count all rows in the table"
count 'ev_charging_stations'

echo ""
echo "--- COUNT Operation 2: Count with Interval ---"
echo "Description: Show progress every N rows"
echo "# count 'ev_charging_stations', INTERVAL => 1000"
echo ""

echo "--- COUNT Operation 3: Count Specific Station Records ---"
echo "Description: Count how many readings exist for a station"
echo "Note: HBase count doesn't support row range, use scan to estimate"
scan 'ev_charging_stations', {STARTROW => 'EV00001#', STOPROW => 'EV00001~', COLUMNS => 'cf_temporal:timestamp'}

echo ""
echo "=========================================================================="
echo "NOTES:"
echo "- DELETE operations are commented to prevent accidental data loss"
echo "- Replace ROW_KEY placeholders with actual row keys from scan results"
echo "- Always verify row keys before executing DELETE/DELETEALL"
echo "- Consider taking snapshots before bulk delete operations"
echo "- For production, implement delete operations in Java API with validation"
echo "=========================================================================="
