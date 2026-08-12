#!/bin/bash
#
# Execute All 3 Hadoop MapReduce Jobs
# RUN AS hduser
#

set -e  # Exit on error

echo "========================================================================"
echo "Running All 3 EV Charging Station MapReduce Jobs"
echo "========================================================================"
echo ""

# Set environment variables
export HADOOP_HOME=${HADOOP_HOME:-/usr/local/hadoop}
export JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java-8-openjdk-amd64}
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$JAVA_HOME/bin:$PATH

# Check if running as hduser
CURRENT_USER=$(whoami)
if [ "$CURRENT_USER" != "hduser" ]; then
    echo "ERROR: This script must be run as 'hduser', not '$CURRENT_USER'"
    exit 1
fi

# Verify HADOOP_HOME is set
if [ -z "$HADOOP_HOME" ]; then
    echo "ERROR: HADOOP_HOME is not set"
    export HADOOP_HOME=/usr/local/hadoop
fi

echo "✓ Running as hduser"
echo "✓ HADOOP_HOME=$HADOOP_HOME"
echo ""

# Check if JARs exist
if [ ! -f "StationUtilizationAnalysis.jar" ] || [ ! -f "WeatherImpactAnalysis.jar" ] || [ ! -f "StationReliabilityAnalysis.jar" ]; then
    echo "ERROR: JAR files not found"
    echo "Please run ./compile.sh first"
    exit 1
fi

echo "✓ All JAR files found"
echo ""

# Define HDFS paths
INPUT_PATH="/input/ev_charging_station_data_cleaned.csv"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Verify input file exists in HDFS
echo "Verifying input file in HDFS..."
if hdfs dfs -test -e $INPUT_PATH; then
    echo "✓ Input file exists in HDFS at: $INPUT_PATH"
else
    echo "✗ Input file NOT found in HDFS: $INPUT_PATH"
    echo ""
    echo "Please upload the dataset first:"
    echo "  hdfs dfs -put ~/ev-charging-station-availability-analytics/ev_charging_station_data_cleaned.csv /input/"
    echo ""
    echo "Alternative: Use existing HDFS location"
    echo "  INPUT_PATH=/home/hduser/Hive_Assignment/ev_charging_station_data_cleaned.csv"
    exit 1
fi
echo ""

# ========== JOB 1: Station Utilization Analysis ==========
echo "========================================================================"
echo "JOB 1/3: Station Utilization Analysis"
echo "========================================================================"
echo "Business Question: What are peak utilization hours by network?"
echo ""

OUTPUT_PATH_1="/output/utilization_analysis_${TIMESTAMP}"
echo "Output: $OUTPUT_PATH_1"
echo ""

START_TIME_1=$(date +%s)
hadoop jar StationUtilizationAnalysis.jar StationUtilizationAnalysis $INPUT_PATH $OUTPUT_PATH_1
END_TIME_1=$(date +%s)
DURATION_1=$((END_TIME_1 - START_TIME_1))

echo ""
echo "✓ Job 1 completed in ${DURATION_1} seconds"
echo ""
echo "Results Preview (First 10 lines):"
echo "Format: Network,Hour | Count,AvgUtil,AvgWait,AvgSession,MinUtil,MaxUtil"
hdfs dfs -cat $OUTPUT_PATH_1/part-r-00000 | head -10
echo ""

# ========== JOB 2: Weather Impact Analysis ==========
echo "========================================================================"
echo "JOB 2/3: Weather Impact Analysis"
echo "========================================================================"
echo "Business Question: How does weather affect charging demand?"
echo ""

OUTPUT_PATH_2="/output/weather_impact_${TIMESTAMP}"
echo "Output: $OUTPUT_PATH_2"
echo ""

START_TIME_2=$(date +%s)
hadoop jar WeatherImpactAnalysis.jar WeatherImpactAnalysis $INPUT_PATH $OUTPUT_PATH_2
END_TIME_2=$(date +%s)
DURATION_2=$((END_TIME_2 - START_TIME_2))

echo ""
echo "✓ Job 2 completed in ${DURATION_2} seconds"
echo ""
echo "Results Preview (First 10 lines):"
echo "Format: WeatherCondition | Count,AvgUtil,AvgTemp,MinUtil,MaxUtil"
hdfs dfs -cat $OUTPUT_PATH_2/part-r-00000 | head -10
echo ""

# ========== JOB 3: Station Reliability Analysis ==========
echo "========================================================================"
echo "JOB 3/3: Station Reliability Analysis"
echo "========================================================================"
echo "Business Question: Which stations have best/worst uptime?"
echo ""

OUTPUT_PATH_3="/output/reliability_analysis_${TIMESTAMP}"
echo "Output: $OUTPUT_PATH_3"
echo ""

START_TIME_3=$(date +%s)
hadoop jar StationReliabilityAnalysis.jar StationReliabilityAnalysis $INPUT_PATH $OUTPUT_PATH_3
END_TIME_3=$(date +%s)
DURATION_3=$((END_TIME_3 - START_TIME_3))

echo ""
echo "✓ Job 3 completed in ${DURATION_3} seconds"
echo ""
echo "Results Preview (First 10 lines):"
echo "Format: StationID|Name|Network | Total,Operational,Offline,Maintenance,PartialOutage,UptimePct,DowntimePct"
hdfs dfs -cat $OUTPUT_PATH_3/part-r-00000 | head -10
echo ""

# ========== SUMMARY ==========
TOTAL_DURATION=$((DURATION_1 + DURATION_2 + DURATION_3))

echo "========================================================================"
echo "ALL 3 MAPREDUCE JOBS COMPLETED SUCCESSFULLY!"
echo "========================================================================"
echo ""
echo "Execution Summary:"
echo "  Job 1 (Utilization):  ${DURATION_1} seconds"
echo "  Job 2 (Weather):      ${DURATION_2} seconds"
echo "  Job 3 (Reliability):  ${DURATION_3} seconds"
echo "  Total Time:           ${TOTAL_DURATION} seconds"
echo ""
echo "Output Directories:"
echo "  1. $OUTPUT_PATH_1"
echo "  2. $OUTPUT_PATH_2"
echo "  3. $OUTPUT_PATH_3"
echo ""
echo "View Complete Results:"
echo "  hdfs dfs -cat $OUTPUT_PATH_1/part-r-00000 > job1_results.txt"
echo "  hdfs dfs -cat $OUTPUT_PATH_2/part-r-00000 > job2_results.txt"
echo "  hdfs dfs -cat $OUTPUT_PATH_3/part-r-00000 > job3_results.txt"
echo ""
echo "View Job History:"
echo "  Access YARN ResourceManager UI at http://localhost:8088"
echo ""

# Save output paths for reference
cat > last_run_info.txt <<EOF
Run Date: $(date)
Job 1 Output: $OUTPUT_PATH_1
Job 2 Output: $OUTPUT_PATH_2
Job 3 Output: $OUTPUT_PATH_3
EOF

echo "✓ Run info saved to last_run_info.txt"
echo ""
