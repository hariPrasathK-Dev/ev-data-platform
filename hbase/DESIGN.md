# HBase Table Design for EV Charging Station Availability Analytics

## Application Overview

### Problem Statement
Electric vehicle (EV) adoption is rapidly growing, but charging infrastructure management remains a challenge. Users need real-time information about charging station availability, while operators need to analyze usage patterns, optimize pricing, and plan infrastructure expansion. Traditional relational databases struggle with the high-volume, time-series nature of this data.

### Real-World Application
This HBase implementation provides a scalable solution for:
- **Real-time availability queries**: Quick lookups of station status
- **Historical analysis**: Time-series queries for usage patterns
- **Predictive analytics**: Data foundation for ML models to predict availability
- **Infrastructure planning**: Identify underutilized/overutilized stations
- **Dynamic pricing optimization**: Analyze demand patterns for pricing strategies

### Motivation
- **Volume**: 1.3M+ records with 30-minute granularity over 6 months
- **Scalability**: HBase's distributed architecture handles growing data
- **Fast lookups**: Row key design enables quick station + time queries
- **Flexible schema**: Column families accommodate evolving requirements
- **Real-time access**: Low-latency reads for user-facing applications

---

## Dataset Description

**Source**: EV Charging Station Availability Dataset  
**Records**: 1,317,750 time-series observations  
**Stations**: 150 charging stations  
**Networks**: 8 charging networks (Tesla, ChargePoint, EVgo, etc.)  
**Locations**: 15 US metropolitan areas  
**Time Range**: July 1 - December 31, 2025  
**Sampling Interval**: Every 30 minutes  
**Attributes**: 33 columns covering station info, availability metrics, pricing, weather, and temporal features

---

## HBase Table Design

### Table Name
`ev_charging_stations`

### Row Key Design

**Format**: `{station_id}#{reverse_timestamp}`

**Example**: `EV00001#9223370511254775807`

**Components**:
1. **station_id**: Unique station identifier (e.g., EV00001)
2. **#**: Delimiter
3. **reverse_timestamp**: `Long.MAX_VALUE - epoch_millis`

**Rationale**:
1. **Station co-location**: All records for a station are stored together
2. **Reverse timestamp**: Most recent data appears first (common query pattern)
3. **Efficient scans**: Time-range queries within a station are sequential
4. **Hotspot avoidance**: 150 different station_id prefixes distribute load
5. **Lexicographic ordering**: Natural sorting by station, then reverse time

**Query Patterns Supported**:
- Get latest status for a station: `scan 'ev_charging_stations', {STARTROW => 'EV00001#', LIMIT => 1}`
- Time-range query: `scan 'ev_charging_stations', {STARTROW => 'EV00001#rev_time_end', STOPROW => 'EV00001#rev_time_start'}`
- All stations at a point in time: Requires multiple gets (acceptable tradeoff)

---

## Column Families

### 1. **cf_station** (Station Information)
**Attributes**: Relatively static station metadata  
**Columns**:
- `name`: Station name
- `network`: Charging network operator
- `city`: City location
- `state`: State abbreviation
- `latitude`: Geographic latitude
- `longitude`: Geographic longitude
- `location_type`: Venue type (Highway, Urban, Shopping, etc.)
- `charger_type`: Charging technology (Level 2, DC Fast, etc.)
- `power_kw`: Power output in kilowatts
- `amenities`: Nearby facilities

**TTL**: None (static data)  
**Versions**: 1 (rarely changes)

### 2. **cf_metrics** (Availability Metrics)
**Attributes**: High-change operational data  
**Columns**:
- `ports_total`: Total charging ports
- `ports_available`: Currently free ports
- `ports_occupied`: Ports in use
- `ports_out_of_service`: Offline ports
- `utilization_rate`: Percentage occupied (0.0-1.0)
- `station_status`: operational/partial_outage/under_maintenance/offline
- `wait_time_mins`: Estimated wait time
- `avg_session_mins`: Average charging duration

**TTL**: Configurable (e.g., 2 years for historical analysis)  
**Versions**: 1 (time-series via row key)

### 3. **cf_pricing** (Pricing Information)
**Attributes**: Dynamic pricing data  
**Columns**:
- `current_price`: Real-time price
- `pricing_type`: per_kwh/per_minute/free

**TTL**: Same as cf_metrics  
**Versions**: 1

### 4. **cf_weather** (Weather Conditions)
**Attributes**: Environmental factors  
**Columns**:
- `temperature_f`: Temperature in Fahrenheit
- `precipitation_mm`: Rainfall amount
- `weather_condition`: clear/cloudy/rain/extreme_heat/freezing

**TTL**: Same as cf_metrics  
**Versions**: 1

### 5. **cf_context** (External Context)
**Attributes**: External influencing factors  
**Columns**:
- `gas_price`: Local gas price per gallon
- `traffic_index`: Traffic congestion (1-10)
- `local_event`: Nearby events (concert/sports/festival/none)

**TTL**: Same as cf_metrics  
**Versions**: 1

### 6. **cf_temporal** (Time Features)
**Attributes**: Pre-computed temporal features  
**Columns**:
- `timestamp`: Original timestamp string
- `hour`: Hour of day (0-23)
- `day_of_week`: Day (0=Monday, 6=Sunday)
- `month`: Month (7-12)
- `is_weekend`: true/false
- `is_peak_hour`: true/false

**TTL**: Same as cf_metrics  
**Versions**: 1

---

## Column Family Design Rationale

1. **Separation by access pattern**: Station info (rarely queried alone) vs metrics (frequently queried)
2. **Update frequency**: Static data (cf_station) separate from time-series (cf_metrics)
3. **Logical grouping**: Related attributes together (pricing, weather, temporal)
4. **Query optimization**: Can select specific column families to reduce data transfer
5. **Compression**: Similar data types in column families compress better

---

## Indexing Strategy

**Primary Access**: Row key (station_id + reverse_timestamp)

**Secondary Index Patterns** (if needed):
- City-based lookup: Secondary index table or Coprocessors
- Network-based queries: Application-level filtering or secondary index
- High-utilization alerts: Scan with filters

---

## Data Operations

### Key Operations to Demonstrate

1. **CREATE**: Table with 6 column families
2. **PUT**: Bulk insert from CSV dataset
3. **GET**: Retrieve specific station at specific time
4. **SCAN**: Time-range queries, filtered scans
5. **DELETE**: Remove specific records
6. **DELETEALL**: Remove all records for a station
7. **COUNT**: Count total records

### Filters to Implement

1. **SingleColumnValueFilter**: Find high-utilization stations (utilization_rate > 0.8)
2. **PrefixFilter**: Get all records for stations in a city (requires station grouping)
3. **ColumnPaginationFilter**: Retrieve limited columns per row
4. **RowFilter with RegexStringComparator**: Pattern matching on row keys
5. **FilterList**: Combine multiple filters (e.g., city + high utilization + peak hours)

### Analysis Queries

1. **Current Station Status**: Get latest availability for a station
2. **Peak Hour Analysis**: Scan records during peak hours (5-8 PM)
3. **High Utilization Stations**: Find stations with utilization > 80%
4. **Weather Impact**: Analyze availability during extreme weather
5. **Station Comparison**: Compare utilization across networks/cities
6. **Time-series Analysis**: Retrieve all records for a station in date range

---

## Java API Implementation

**Program**: High Utilization Station Finder

**Functionality**:
- Connect to HBase
- Scan `ev_charging_stations` table
- Apply SingleColumnValueFilter for `cf_metrics:utilization_rate > 0.8`
- Retrieve and display high-utilization stations with details
- Calculate statistics (average utilization, busiest times)

**Operations Demonstrated**:
- HBase connection management
- Table scanning with filters
- Result processing
- Column family and qualifier access

---

## Performance Considerations

1. **Row key distribution**: 150 stations provide reasonable distribution
2. **Block cache**: Hot data (recent timestamps) benefit from caching
3. **Bloom filters**: Enable for row-level lookups
4. **Compression**: Enable Snappy/LZ4 for column families
5. **Region sizing**: Configure appropriate region size for data volume
6. **Batch operations**: Use batch puts for bulk loading

---

## Scalability

- **Horizontal scaling**: Add region servers as data grows
- **Time-based splits**: Pre-split table by station_id ranges
- **Data retention**: TTL policies for old data
- **Future growth**: Schema accommodates new stations/attributes

---

## Real-World Benefits

1. **User Experience**: Fast queries for mobile app "find available charger"
2. **Operations**: Identify failing stations via status monitoring
3. **Business Intelligence**: Analyze ROI by location_type and network
4. **Predictive Maintenance**: Historical patterns indicate maintenance needs
5. **Infrastructure Planning**: Data-driven decisions for new station placement
