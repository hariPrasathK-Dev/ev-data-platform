#!/bin/bash

# Test Hive Table Creation
# Run after: schematool -dbType derby -initSchema

echo "========================================="
echo "Testing Hive Table Creation"
echo "========================================="
echo ""

# Test 1: Show databases
echo "Step 1: Showing databases..."
hive -e "SHOW DATABASES;"
echo ""

# Test 2: Create table
echo "Step 2: Creating ev_charging_stations table..."
hive -f create_table.hql 2>&1 | head -50
echo ""

# Test 3: Verify table exists
echo "Step 3: Verifying table exists..."
hive -e "SHOW TABLES;"
echo ""

# Test 4: Count records
echo "Step 4: Counting records..."
hive -e "SELECT COUNT(*) FROM ev_charging_stations;"
echo ""

echo "========================================="
echo "Table creation test complete!"
echo "========================================="
