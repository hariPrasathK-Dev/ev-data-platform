# Scala Spark RDD Analysis

Complete RDD-based analysis of EV charging station data demonstrating all required Spark concepts.

## Features Implemented

### ✅ RDD Operations
- **RDD Creation**: `textFile()` from 323 MB CSV
- **Transformations**:
  - `map()` - Extract key fields
  - `filter()` - Keep operational stations only
  - `flatMap()` - Extract weather conditions
- **Actions**:
  - `count()` - Count records
  - `take()` - Sample records
  - `reduce()` - Sum utilization rates

### ✅ Key-Value Operations
- `reduceByKey()` - Aggregate by network, city, hour
- Pair RDD transformations
- Sorting results

### ✅ Advanced Features
- **Partitioning**: Shows partition count
- **Caching**: `cache()` demonstrated with reuse
- **Persistence**: Storage level inspection
- **Lineage**: `toDebugString` showing RDD lineage
- **DAG**: Explanation of narrow vs wide transformations
- **Shuffle**: Identified at `reduceByKey` and `sortBy`

## Analysis Outputs

The program generates:

1. **Network Statistics** - Performance by charging network
2. **City Statistics** - Utilization by city
3. **Hourly Patterns** - Demand by hour of day
4. **Summary** - Overall metrics

## How to Run

**IMPORTANT: Must run as user `hprasatk` who has Spark configured**

### Step 1: Switch User
```bash
su hprasatk
cd /home/hduser/ev-charging-station-availability-analytics/spark-scala
```

### Step 2: Build
```bash
./build.sh
```

This compiles `EVChargingRDDAnalysis.scala` using `scalac` with Spark dependencies.

### Step 3: Run
```bash
./run.sh
```

This executes the compiled Scala program using `spark-submit`.

## Output Files

Results are saved to `../data/processed/spark/`:
- `network_stats.json` - Network performance
- `city_stats.json` - City-level utilization
- `hourly_stats.json` - Hourly demand patterns
- `summary.json` - Overall statistics

## Academic Requirements Met

✅ RDD creation from large dataset (323 MB)
✅ At least 3 transformations (`map`, `filter`, `flatMap`)
✅ At least 2 actions (`count`, `take`, `reduce`)
✅ Key-value operations (`reduceByKey`)
✅ Partition count displayed
✅ Cache/persist demonstrated
✅ RDD lineage shown via `toDebugString`
✅ DAG explanation provided
✅ Shuffle boundaries identified
✅ Real analytical aggregations
✅ Proper CSV parsing with quoted fields
✅ Invalid record handling
✅ Verified output generation

## Troubleshooting

**"SPARK_HOME not set"**
- Run as user `hprasatk`
- Spark 3.5.9 and Scala 2.12.18 are configured for this user

**"CSV file not found"**
- Make sure you're in the `spark-scala/` directory
- CSV should be at `../ev_charging_station_data_cleaned.csv`

**Compilation errors**
- Check Scala version: `scala -version`
- Should be 2.12.x
- Check Spark jars exist: `ls $SPARK_HOME/jars/spark-core*`
