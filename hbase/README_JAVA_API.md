# HBase Java API Implementation

## Program: HighUtilizationStationFinder.java

### Purpose
This Java program demonstrates HBase API usage for the EV Charging Station Availability Analytics application. It connects to HBase and performs real-world analytical queries to identify high-utilization charging stations.

---

## Features Demonstrated

### 1. **HBase Connection Management**
- Configuration setup using `HBaseConfiguration`
- Connection creation via `ConnectionFactory`
- Proper resource management with try-with-resources

### 2. **Table Operations**
- Opening and closing HBase tables
- Accessing table data through `Table` interface

### 3. **Scanning with Filters**
- `SingleColumnValueFilter`: Filter by utilization rate
- `FilterList`: Combine multiple filters with AND/OR logic
- `CompareFilter.CompareOp`: Comparison operations (GREATER, EQUAL, etc.)

### 4. **Data Retrieval**
- Scanning rows with `Scan` and `ResultScanner`
- Extracting column family and qualifier values
- Type conversion (String, double, int, boolean)

### 5. **Result Processing**
- Parsing HBase `Result` objects
- Building domain objects (StationRecord)
- Data validation and error handling

### 6. **Statistical Analysis**
- Calculating averages, counts, and distributions
- Grouping data by city and network
- Generating business insights

---

## Program Structure

```
HighUtilizationStationFinder
├── Main Analysis Methods
│   ├── findHighUtilizationStations() - Find stations >80% utilization
│   ├── findPeakHourCongestion() - Peak hour congestion analysis
│   └── findStationsByCity() - City-specific queries
│
├── Helper Methods
│   ├── parseResult() - Convert HBase Result to StationRecord
│   ├── getStringValue() - Extract string values
│   ├── getDoubleValue() - Extract numeric values
│   ├── getIntValue() - Extract integer values
│   └── calculateStatistics() - Generate statistics
│
└── Data Model
    └── StationRecord - Domain object for station data
```

---

## Analysis Performed

### Analysis 1: High Utilization Stations
**Use Case**: Identify stations needing capacity expansion

**Filter**: `utilization_rate > 0.8` (80%)

**Business Value**: 
- Capacity planning decisions
- Infrastructure investment prioritization
- Customer experience improvement

**Output**:
- List of congested stations
- Station details (name, city, network, location type)
- Availability metrics (ports available, wait times)
- Pricing information
- Statistical summary

### Analysis 2: Peak Hour Congestion
**Use Case**: Find high utilization during peak hours (7-9 AM, 5-8 PM)

**Filters**: 
- `utilization_rate > 0.7` (70%)
- `is_peak_hour = True`

**Business Value**:
- Peak hour capacity planning
- Dynamic pricing strategy
- Staff scheduling optimization

### Analysis 3: City-Based Analysis
**Use Case**: Analyze stations in specific cities

**Filter**: `city = [specified city]`

**Business Value**:
- Regional performance comparison
- City-specific infrastructure planning
- Market-specific insights

---

## Compilation and Execution

### Prerequisites
1. **HBase Installed**: Standalone or distributed mode
2. **Java Development Kit (JDK)**: Version 8 or higher
3. **HBASE_HOME**: Environment variable set
4. **HBase Running**: `start-hbase.sh`
5. **Table Exists**: `ev_charging_stations` table created
6. **Data Loaded**: Sample data imported

### Method 1: Using Provided Script (Recommended)

```bash
chmod +x compile_and_run_java.sh
./compile_and_run_java.sh
```

The script will:
1. Check Java and HBase environment
2. Configure HBase classpath
3. Compile the Java program
4. Create JAR file
5. Execute the program
6. Display results

### Method 2: Manual Compilation

```bash
# Set HBase classpath
export HBASE_CP=$(hbase classpath)

# Compile
javac -cp "$HBASE_CP" HighUtilizationStationFinder.java

# Run
java -cp "$HBASE_CP:." HighUtilizationStationFinder
```

### Method 3: Using JAR

```bash
# Create JAR
jar cf EVChargingStationAnalyzer.jar *.class

# Run
java -cp "$(hbase classpath):EVChargingStationAnalyzer.jar" HighUtilizationStationFinder
```

---

## Expected Output

```
=================================================================
HBase Java API Demo: High Utilization Station Finder
Application: EV Charging Station Availability Analytics
=================================================================

✓ Connected to HBase successfully

--- Analysis 1: High Utilization Stations ---
Threshold: 80.0%
Business Use Case: Identify stations needing capacity expansion

Found 20 high-utilization records:

Record 1:
Station: ChargePoint - Los Angeles #1 | City: Los Angeles | Network: ChargePoint | Location: Shopping Center
  Utilization: 85.3% | Available: 1/6 ports | Wait: 15 mins
  Price: $0.24 | Time: 2025-07-01 08:00:00 (Hour: 8, Peak: True) | Status: operational

Record 2:
Station: Tesla Supercharger - San Francisco #5 | City: San Francisco | Network: Tesla | Location: Highway Corridor
  Utilization: 91.2% | Available: 0/8 ports | Wait: 25 mins
  Price: $0.28 | Time: 2025-07-15 17:30:00 (Hour: 17, Peak: True) | Status: operational

...

--- Statistical Analysis ---

Total High-Utilization Records: 20
Average Utilization Rate: 84.7%
Average Wait Time: 12.3 minutes
Average Price: $0.26 per kWh
Peak Hour Records: 14 (70.0%)

Distribution by City:
  Los Angeles: 8 records
  San Francisco: 5 records
  New York: 4 records
  Seattle: 3 records

Distribution by Network:
  ChargePoint: 7 records
  Tesla Supercharger: 6 records
  EVgo: 4 records
  Electrify America: 3 records

Business Insights:
  • Stations with utilization > 80% need capacity expansion
  • High wait times indicate customer dissatisfaction risk
  • Peak hour congestion suggests need for dynamic pricing
  • City-wise distribution helps in regional planning

--- Analysis 2: Peak Hour Congestion ---
...

--- Analysis 3: Stations in Los Angeles ---
...

=================================================================
Analysis Complete
=================================================================
```

---

## Code Highlights

### 1. Filter Creation
```java
SingleColumnValueFilter filter = new SingleColumnValueFilter(
    CF_METRICS,
    COL_UTILIZATION_RATE,
    CompareFilter.CompareOp.GREATER,
    Bytes.toBytes(String.valueOf(UTILIZATION_THRESHOLD))
);
filter.setFilterIfMissing(true);
```

### 2. Scan Configuration
```java
Scan scan = new Scan();
scan.setFilter(filter);
scan.setCaching(100);
scan.addFamily(CF_STATION);
scan.addFamily(CF_METRICS);
```

### 3. Result Processing
```java
ResultScanner scanner = table.getScanner(scan);
for (Result result : scanner) {
    StationRecord record = parseResult(result);
    // Process record
}
scanner.close();
```

### 4. Multiple Filters (AND Logic)
```java
FilterList filterList = new FilterList(FilterList.Operator.MUST_PASS_ALL);
filterList.addFilter(utilizationFilter);
filterList.addFilter(peakHourFilter);
```

---

## Real-World Applications

### 1. **Mobile App Backend**
- Real-time availability queries
- Station recommendations based on utilization
- Wait time predictions

### 2. **Operations Dashboard**
- Monitor congested stations
- Identify maintenance needs
- Track performance metrics

### 3. **Business Intelligence**
- Capacity planning reports
- ROI analysis by location
- Network performance comparison

### 4. **Predictive Analytics**
- Extract data for ML models
- Historical pattern analysis
- Demand forecasting

---

## Troubleshooting

### Common Issues

**1. ClassNotFoundException: org.apache.hadoop.hbase.HBaseConfiguration**
- **Solution**: Ensure HBase classpath is set correctly
- Run: `export HBASE_CP=$(hbase classpath)`

**2. Connection Refused**
- **Solution**: Start HBase
- Run: `start-hbase.sh`

**3. TableNotFoundException: ev_charging_stations**
- **Solution**: Create and load table
- Run: `bash setup_hbase.sh`

**4. No results returned**
- **Solution**: Check if data is loaded
- Run: `echo "count 'ev_charging_stations'" | hbase shell`

**5. OutOfMemoryError**
- **Solution**: Increase heap size
- Run with: `java -Xmx2g -cp ...`

---

## Extending the Program

### Add New Analysis Methods

```java
// Example: Find stations with maintenance issues
private static void findMaintenanceIssues(Connection connection) throws IOException {
    SingleColumnValueFilter filter = new SingleColumnValueFilter(
        CF_METRICS,
        COL_STATION_STATUS,
        CompareFilter.CompareOp.EQUAL,
        Bytes.toBytes("under_maintenance")
    );
    // ... rest of implementation
}
```

### Add More Filters

```java
// Example: Weather impact analysis
SingleColumnValueFilter weatherFilter = new SingleColumnValueFilter(
    Bytes.toBytes("cf_weather"),
    Bytes.toBytes("weather_condition"),
    CompareFilter.CompareOp.EQUAL,
    Bytes.toBytes("extreme_heat")
);
```

---

## Performance Considerations

1. **Caching**: Set appropriate scan caching value
   ```java
   scan.setCaching(100); // Fetch 100 rows at a time
   ```

2. **Column Selection**: Only retrieve needed column families
   ```java
   scan.addFamily(CF_METRICS); // Don't fetch all families
   ```

3. **Result Limit**: Limit results for better performance
   ```java
   int maxResults = 100;
   ```

4. **Connection Pooling**: Reuse connections in production
   ```java
   // Use ConnectionFactory with configuration
   ```

---

## Conclusion

This Java program demonstrates comprehensive HBase API usage for real-world analytics on the EV Charging Station dataset. It showcases:

✓ Connection management  
✓ Filter usage (single and combined)  
✓ Data scanning and retrieval  
✓ Result parsing and type conversion  
✓ Statistical analysis  
✓ Business insights generation  

The program fulfills the project requirement of implementing at least one meaningful HBase operation using the Java API, while providing practical business value through high-utilization station identification and analysis.
