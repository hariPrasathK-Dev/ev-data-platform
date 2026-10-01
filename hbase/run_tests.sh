#!/bin/bash

##############################################################################
# Test Suite for HBase Implementation
# Validates all components before demonstration
##############################################################################

echo "=========================================================================="
echo "HBase Project Test Suite"
echo "Application: EV Charging Station Availability Analytics"
echo "=========================================================================="
echo ""

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo "Running: $test_name"
    eval "$test_command" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "  ✓ PASSED"
        ((TESTS_PASSED++))
    else
        echo "  ✗ FAILED"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
    fi
}

##############################################################################
# Test 1: Environment Tests
##############################################################################
echo ""
echo "--- Environment Tests ---"
echo ""

run_test "HBase command available" "command -v hbase"
run_test "Python3 available" "command -v python3"
run_test "Java available" "command -v java"
run_test "Javac available" "command -v javac"

##############################################################################
# Test 2: File Existence Tests
##############################################################################
echo ""
echo "--- File Existence Tests ---"
echo ""

run_test "CSV data file exists" "test -f ../ev_charging_station_data.csv"
run_test "Table creation script exists" "test -f create_table.hql"
run_test "Data generator script exists" "test -f generate_hbase_puts.py"
run_test "Basic queries script exists" "test -f queries_basic.hql"
run_test "Analysis queries script exists" "test -f queries_analysis.hql"
run_test "Filters script exists" "test -f filters.hql"
run_test "Java source file exists" "test -f HighUtilizationStationFinder.java"
run_test "Design documentation exists" "test -f DESIGN.md"
run_test "Table schema documentation exists" "test -f table_schema.txt"

##############################################################################
# Test 3: HBase Service Tests
##############################################################################
echo ""
echo "--- HBase Service Tests ---"
echo ""

run_test "HBase version command" "hbase version"
run_test "HBase shell accessible" "echo 'status' | hbase shell"

##############################################################################
# Test 4: Script Syntax Tests
##############################################################################
echo ""
echo "--- Script Syntax Tests ---"
echo ""

run_test "Python script syntax" "python3 -m py_compile generate_hbase_puts.py"
run_test "Setup script syntax" "bash -n setup_hbase.sh"
run_test "Load data script syntax" "bash -n load_sample_data.sh"
run_test "Compile Java script syntax" "bash -n compile_and_run_java.sh"
run_test "Run all demos script syntax" "bash -n run_all_demos.sh"

##############################################################################
# Test 5: HBase Table Tests
##############################################################################
echo ""
echo "--- HBase Table Tests ---"
echo ""

# Check if table exists
TABLE_EXISTS=$(echo "list" | hbase shell 2>/dev/null | grep -c "ev_charging_stations")

if [ "$TABLE_EXISTS" -gt 0 ]; then
    echo "Running: Table exists check"
    echo "  ✓ PASSED"
    ((TESTS_PASSED++))
    
    # If table exists, run more tests
    run_test "Table describe command" "echo \"describe 'ev_charging_stations'\" | hbase shell"
    run_test "Table count command" "echo \"count 'ev_charging_stations', INTERVAL => 10000\" | hbase shell"
    
    # Check if table has data
    ROW_COUNT=$(echo "count 'ev_charging_stations', INTERVAL => 10000" | hbase shell 2>/dev/null | grep "row(s)" | awk '{print $1}')
    
    if [ -n "$ROW_COUNT" ] && [ "$ROW_COUNT" -gt 0 ]; then
        echo "Running: Table has data (count: $ROW_COUNT)"
        echo "  ✓ PASSED"
        ((TESTS_PASSED++))
        
        run_test "Table scan command" "echo \"scan 'ev_charging_stations', {LIMIT => 1}\" | hbase shell"
    else
        echo "Running: Table has data"
        echo "  ✗ FAILED (table is empty)"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("Table has data")
    fi
else
    echo "Running: Table exists check"
    echo "  ⚠ WARNING (table does not exist - run setup first)"
    echo "  Note: This is expected if setup hasn't been run yet"
fi

##############################################################################
# Test 6: Python Data Generator Tests
##############################################################################
echo ""
echo "--- Data Generator Tests ---"
echo ""

if [ -f "../ev_charging_station_data.csv" ]; then
    # Test with small sample
    run_test "Python script execution (10 records)" "python3 generate_hbase_puts.py ../ev_charging_station_data.csv 10 > /tmp/test_puts.hql 2>&1"
    
    if [ -f "/tmp/test_puts.hql" ]; then
        PUT_COUNT=$(grep -c "^put" /tmp/test_puts.hql 2>/dev/null || echo "0")
        if [ "$PUT_COUNT" -eq 10 ]; then
            echo "Running: PUT commands generated correctly"
            echo "  ✓ PASSED"
            ((TESTS_PASSED++))
        else
            echo "Running: PUT commands generated correctly"
            echo "  ✗ FAILED (expected 10, got $PUT_COUNT)"
            ((TESTS_FAILED++))
            FAILED_TESTS+=("PUT commands generation")
        fi
        rm -f /tmp/test_puts.hql
    fi
else
    echo "Running: CSV data file check"
    echo "  ⚠ WARNING (CSV file not found)"
fi

##############################################################################
# Test 7: Java Compilation Test
##############################################################################
echo ""
echo "--- Java Compilation Test ---"
echo ""

if [ -n "$HBASE_HOME" ] || command -v hbase &> /dev/null; then
    HBASE_CP=$(hbase classpath 2>/dev/null)
    if [ -n "$HBASE_CP" ]; then
        run_test "Java compilation" "javac -cp \"$HBASE_CP\" HighUtilizationStationFinder.java"
        
        if [ -f "HighUtilizationStationFinder.class" ]; then
            echo "Running: Java class file generated"
            echo "  ✓ PASSED"
            ((TESTS_PASSED++))
            
            # Clean up
            rm -f *.class 2>/dev/null
        fi
    else
        echo "Running: HBase classpath"
        echo "  ⚠ WARNING (could not get HBase classpath)"
    fi
else
    echo "Running: HBase environment"
    echo "  ⚠ WARNING (HBase not configured)"
fi

##############################################################################
# Test Summary
##############################################################################
echo ""
echo "=========================================================================="
echo "TEST SUMMARY"
echo "=========================================================================="
echo ""

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))

echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo "Status: ✓ ALL TESTS PASSED"
    echo ""
    echo "System is ready for demonstration!"
    echo "Run: bash run_all_demos.sh"
    EXIT_CODE=0
else
    echo "Status: ✗ SOME TESTS FAILED"
    echo ""
    echo "Failed tests:"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  - $test"
    done
    echo ""
    echo "Please fix the issues before running demonstrations"
    EXIT_CODE=1
fi

echo ""
echo "=========================================================================="
echo "RECOMMENDATIONS"
echo "=========================================================================="
echo ""

if [ "$TABLE_EXISTS" -eq 0 ]; then
    echo "⚠ Table not found. To set up:"
    echo "  bash setup_hbase.sh"
    echo ""
fi

if [ -z "$ROW_COUNT" ] || [ "$ROW_COUNT" -eq 0 ]; then
    echo "⚠ Table has no data. To load sample data:"
    echo "  bash load_sample_data.sh"
    echo ""
fi

echo "To run individual components:"
echo "  • Table creation:    hbase shell create_table.hql"
echo "  • Data loading:      bash load_sample_data.sh"
echo "  • Basic queries:     hbase shell queries_basic.hql"
echo "  • Analysis queries:  hbase shell queries_analysis.hql"
echo "  • Filters:           hbase shell filters.hql"
echo "  • Java API:          bash compile_and_run_java.sh"
echo ""
echo "=========================================================================="

exit $EXIT_CODE
