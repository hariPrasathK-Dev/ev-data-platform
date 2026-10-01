# ==============================================================================
# HBase Basic Operations - EV Charging Station Analytics
# Demonstrates: GET, SCAN, COUNT, DELETE, DELETEALL
# ==============================================================================

# -----------------------------------------------------------------------------
# 1. COUNT - Get total number of records in the table
# -----------------------------------------------------------------------------
echo "=== Operation 1: COUNT - Total Records ==="
count 'ev_charging_stations'

# -----------------------------------------------------------------------------
# 2. SCAN - Display first 5 rows to understand data structure
# -----------------------------------------------------------------------------
echo ""
echo "=== Operation 2: SCAN - First 5 Records ==="
scan 'ev_charging_stations', {LIMIT => 5}

# -----------------------------------------------------------------------------
# 3. SCAN - Get records for a specific station (EV00001)
# -----------------------------------------------------------------------------
echo ""
echo "=== Operation 3: SCAN - Specific Station (EV00001) ==="
scan 'ev_charging_stations', {STARTROW => 'EV00001#', STOPROW => 'EV00001~', LIMIT => 10}

# -----------------------------------------------------------------------------
# 4. SCAN - Get only station info column family
# -----------------------------------------------------------------------------
echo ""
echo "=== Operation 4: SCAN - Station Info Only ==="
scan 'ev_charging_stations', {COLUMNS => 'cf_station', LIMIT => 3}

# -----------------------------------------------------------------------------
# 5. SCAN - Get only metrics column family
# -----------------------------------------------------------------------------
echo ""
echo "=== Operation 5: SCAN - Metrics Only ==="
scan 'ev_charging_stations', {COLUMNS => 'cf_metrics', LIMIT => 3}

# -----------------------------------------------------------------------------
# 6. GET - Retrieve a specific row (requires actual row key)
# Use scan first to get a valid row key, then use it here
# -----------------------------------------------------------------------------
echo ""
echo "=== Operation 6: GET - Specific Row ==="
echo "First, getting a sample row key..."
# Note: In actual execution, replace with a real row key from your data
# Example: get 'ev_charging_stations', 'EV00001#9223370511254775807'

# -----------------------------------------------------------------------------
# 7. SCAN - Get specific columns only
# -----------------------------------------------------------------------------
echo ""
echo "=== Operation 7: SCAN - Specific Columns ==="
scan 'ev_charging_stations', {COLUMNS => ['cf_station:name', 'cf_metrics:utilization_rate', 'cf_pricing:current_price'], LIMIT => 5}

# -----------------------------------------------------------------------------
# 8. SCAN - Time-range query for a station (latest records first)
# -----------------------------------------------------------------------------
echo ""
echo "=== Operation 8: SCAN - Latest Records for Station ==="
scan 'ev_charging_stations', {STARTROW => 'EV00001#', LIMIT => 5}

# -----------------------------------------------------------------------------
# 9. SCAN - Get records from different stations
# -----------------------------------------------------------------------------
echo ""
echo "=== Operation 9: SCAN - Multiple Stations ==="
scan 'ev_charging_stations', {LIMIT => 20, COLUMNS => ['cf_station:station_id', 'cf_station:name', 'cf_metrics:utilization_rate']}

# -----------------------------------------------------------------------------
# 10. COUNT - Count records for a specific station
# -----------------------------------------------------------------------------
echo ""
echo "=== Operation 10: COUNT - Records for Specific Station ==="
# Note: HBase count doesn't support row range, so we use scan with counter
scan 'ev_charging_stations', {STARTROW => 'EV00001#', STOPROW => 'EV00001~', COLUMNS => 'cf_station:name'}

# -----------------------------------------------------------------------------
# 11. DELETE - Delete a specific cell value
# -----------------------------------------------------------------------------
echo ""
echo "=== Operation 11: DELETE - Specific Cell ==="
echo "# Deleting a specific column value from a row"
echo "# delete 'ev_charging_stations', 'ROW_KEY', 'cf_metrics:wait_time_mins'"
echo "# Note: Replace ROW_KEY with actual row key"

# -----------------------------------------------------------------------------
# 12. DELETEALL - Delete entire row
# -----------------------------------------------------------------------------
echo ""
echo "=== Operation 12: DELETEALL - Entire Row ==="
echo "# Deleting an entire row"
echo "# deleteall 'ev_charging_stations', 'ROW_KEY'"
echo "# Note: Replace ROW_KEY with actual row key"

# -----------------------------------------------------------------------------
# 13. SCAN - Verify table structure
# -----------------------------------------------------------------------------
echo ""
echo "=== Operation 13: DESCRIBE - Table Structure ==="
describe 'ev_charging_stations'

# -----------------------------------------------------------------------------
# 14. SCAN - Count by column family
# -----------------------------------------------------------------------------
echo ""
echo "=== Operation 14: SCAN - Sample with All Column Families ==="
scan 'ev_charging_stations', {LIMIT => 1}

# -----------------------------------------------------------------------------
# Notes for Actual Execution:
# - Replace 'ROW_KEY' placeholders with actual row keys from your data
# - Some operations are commented to prevent accidental deletions
# - Run get operations after obtaining valid row keys from scan results
# -----------------------------------------------------------------------------
