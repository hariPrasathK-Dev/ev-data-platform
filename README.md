# EV Charging Station Availability Analytics

**Big Data Analytics Project - Course: 23CSE352**  
**Project Review 1**

A comprehensive big data analytics system for analyzing EV charging station availability patterns using Hadoop MapReduce, Apache Hive, and a modern web dashboard.

---

## 📊 Project Overview

- **Dataset:** 1,317,750 records (323 MB)
- **Time Period:** July - December 2025
- **Stations:** 150 charging stations across 13 US states
- **Networks:** 8 major EV charging networks
- **Features:** 33 attributes including utilization rates, weather conditions, pricing, and availability metrics

---

## 🏗️ System Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                         DATA SOURCE                              │
│          EV Charging Station Dataset (323 MB, 1.3M records)      │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                   HADOOP DISTRIBUTED FILE SYSTEM (HDFS)          │
│                          Port: 9000                              │
│  ┌────────────┐         ┌──────────────────────────────────┐     │
│  │  NameNode  │───────▶│  DataNode (Block Storage)        │     │
│  │ (Metadata) │         │  - Block Size: 128 MB            │     │
│  └────────────┘         │  - Replication Factor: 1         │     │
│                         └──────────────────────────────────┘     │
│  Storage Location: /input/ev_charging_station_data_cleaned.csv   │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
                ▼                         ▼
┌───────────────────────────┐  ┌──────────────────────────────┐
│    HADOOP MAPREDUCE       │  │      APACHE HIVE             │
│    (Batch Processing)     │  │   (Data Warehousing)         │
│                           │  │                              │
│  ┌─────────────────────┐  │  │  ┌────────────────────────┐  │
│  │   YARN Resource     │  │  │  │   Hive Metastore       │  │
│  │   Manager :8088     │  │  │  │   (Derby DB)           │  │
│  └──────────┬──────────┘  │  │  └───────────┬────────────┘  │
│             │             │  │              │               │
│  ┌──────────▼──────────┐  │  │  ┌───────────▼────────────┐  │
│  │   Node Manager      │  │  │  │   HiveQL Query         │  │
│  │   (Task Executor)   │  │  │  │   Engine               │  │
│  └──────────┬──────────┘  │  │  └───────────┬────────────┘  │
│             │             │  │              │               │
│  ┌──────────▼──────────┐  │  │  ┌───────────▼────────────┐  │
│  │   Map Tasks         │  │  │  │   External Table:      │  │
│  │   - Data Parsing    │  │  │  │   ev_charging_stations │  │
│  │   - Filtering       │  │  │  │   (1,317,750 rows)     │  │
│  └─────────────────────┘  │  │  └────────────────────────┘  │
│                           │  │                              │
│  ┌─────────────────────┐  │  │  Analytical Queries:         │
│  │   Reduce Tasks      │  │  │  - Aggregations (15+)        │
│  │   - Aggregation     │  │  │  - GROUP BY, HAVING          │
│  │   - Sorting         │  │  │  - JOIN operations           │
│  └─────────────────────┘  │  │  - Statistical functions     │
│                           │  │                              │
│  Programs Implemented:    │  └──────────────────────────────┘
│  1. Station Utilization   │
│  2. Weather Impact        │
│  3. Station Reliability   │
└───────────────────────────┘

                OUTPUT LAYER
┌──────────────────────┐        ┌─────────────────────────┐
│  MapReduce Results   │        │   Hive Query Results    │
│  /output/            │        │   Console Output        │
│  - utilization/*     │        │   - Tabular format      │
│  - weather/*         │        │   - Real-time results   │
│  - reliability/*     │        │                         │
└──────────────────────┘        └─────────────────────────┘
```

### Architecture Components:

**1. HDFS (Storage Layer)**
- Distributed file system for storing large datasets
- NameNode: Manages file system namespace and metadata
- DataNode: Stores actual data blocks
- Fault-tolerant with configurable replication

**2. YARN (Resource Management)**
- ResourceManager: Allocates cluster resources
- NodeManager: Manages resources on individual nodes
- Coordinates MapReduce job execution

**3. MapReduce (Processing Engine)**
- Distributed parallel processing framework
- Map phase: Filters and transforms data
- Reduce phase: Aggregates results
- Three custom Java programs implemented

**4. Hive (Query Interface)**
- SQL-like interface (HiveQL) for big data
- Metastore: Stores table schemas and metadata
- Translates SQL queries to MapReduce jobs
- Suitable for ad-hoc analysis and reporting

---

## 🚀 Quick Start

### Prerequisites
- Hadoop 3.3.1
- Hive 3.1.3
- Java 8
- Python 3.12
- Node.js 20.20.2

### 1. Start Hadoop Services
```bash
start-dfs.sh
start-yarn.sh
jps  # Verify services running
```

### 2. Upload Data to HDFS
```bash
hdfs dfs -put ev_charging_station_data_cleaned.csv /input/
```

### 3. Initialize Hive Metastore
```bash
rm -rf ~/metastore_db
cd /usr/local/hive
schematool -dbType derby -initSchema
```

### 4. Create Hive Table
```bash
cd hive
hive -f create_table.hql
```

### 5. Start Backend API
```bash
cd backend
python3 main.py
```

### 6. Start Frontend (New Terminal)
```bash
cd frontend
npm run dev
```

### 7. Access Applications
- **Frontend Dashboard:** http://localhost:5173
- **Backend API:** http://localhost:8000
- **API Documentation:** http://localhost:8000/docs
- **YARN Resource Manager:** http://localhost:8088

---

## 📁 Project Structure

```
ev-charging-station-availability-analytics/
├── backend/                      # FastAPI backend
│   ├── main.py                   # API endpoints
│   ├── hdfs_service.py           # HDFS operations
│   ├── mapreduce_service.py      # MapReduce job management
│   ├── hive_service.py           # Hive query execution
│   └── requirements.txt          # Python dependencies
│
├── frontend/                     # SvelteKit frontend
│   ├── src/
│   │   ├── routes/
│   │   │   ├── +page.svelte             # Dashboard
│   │   │   ├── hdfs/+page.svelte        # HDFS browser
│   │   │   ├── mapreduce/+page.svelte   # MapReduce jobs
│   │   │   └── hive/+page.svelte        # Hive queries
│   │   └── lib/
│   │       └── api.js            # API client
│   └── package.json
│
├── mapreduce/                    # MapReduce programs
│   ├── StationUtilizationAnalysis.java
│   ├── WeatherImpactAnalysis.java
│   ├── StationReliabilityAnalysis.java
│   ├── *.jar                     # Compiled JAR files
│   └── compile.sh                # Compilation script
│
├── hive/                         # Hive setup and queries
│   ├── create_table.hql          # Table DDL
│   ├── queries.hql               # 15 analytical queries
│   └── run_hive_setup.sh         # Setup script
│
├── ev_charging_station_data_cleaned.csv  # Cleaned dataset (323 MB)
└── README.md                     # This file
```

---

## 🔧 MapReduce Programs

### Program 1: Station Utilization Analysis
Analyzes charging station utilization patterns by network and hour.

**Run:**
```bash
cd mapreduce
hadoop jar StationUtilizationAnalysis.jar StationUtilizationAnalysis /input/ev_charging_station_data_cleaned.csv /output/utilization
```

**View Results:**
```bash
hdfs dfs -cat /output/utilization/part-r-00000 | head -20
```

**Output:** Network-hour combinations with average utilization rates, total sessions, and wait times.

---

### Program 2: Weather Impact Analysis
Analyzes how weather conditions affect charging demand.

**Run:**
```bash
hadoop jar WeatherImpactAnalysis.jar WeatherImpactAnalysis /input/ev_charging_station_data_cleaned.csv /output/weather
```

**View Results:**
```bash
hdfs dfs -cat /output/weather/part-r-00000
```

**Output:** Average utilization and session counts for each weather condition (clear, rain, extreme_heat, etc.).

---

### Program 3: Station Reliability Analysis
Identifies stations with highest operational uptime and reliability.

**Run:**
```bash
hadoop jar StationReliabilityAnalysis.jar StationReliabilityAnalysis /input/ev_charging_station_data_cleaned.csv /output/reliability
```

**View Results:**
```bash
hdfs dfs -cat /output/reliability/part-r-00000 | head -20
```

**Output:** Station IDs with operational percentage, average utilization, and downtime statistics.

---

## 🗄️ Hive Queries

### Sample Queries

**Query 1: Peak Utilization Hours**
```sql
SELECT hour_of_day, AVG(utilization_rate) AS avg_utilization, COUNT(*) AS observations
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY hour_of_day
ORDER BY avg_utilization DESC
LIMIT 10;
```

**Query 2: Network Performance Comparison**
```sql
SELECT network, 
       COUNT(*) AS total_observations,
       ROUND(SUM(CASE WHEN station_status = 'operational' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS uptime_percentage
FROM ev_charging_stations
GROUP BY network
ORDER BY uptime_percentage DESC;
```

**Query 3: Weather Impact on Demand**
```sql
SELECT weather_condition, 
       COUNT(*) AS observations, 
       AVG(utilization_rate) AS avg_utilization
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY weather_condition
ORDER BY avg_utilization DESC;
```

**Run All Queries:**
```bash
cd hive
hive -f queries.hql
```

---

## 🎯 Key Features

### Frontend Dashboard
- Real-time system health monitoring
- HDFS file browser with preview and download
- MapReduce job monitoring with live progress
- Hive query editor with predefined queries
- Professional, responsive UI design

### Backend API
- RESTful endpoints for HDFS, MapReduce, and Hive
- Real-time job status tracking
- Pagination and search support
- Comprehensive error handling
- Structured logging

### Big Data Processing
- 3 distinct MapReduce analytics programs
- 15+ predefined Hive analytical queries
- HDFS distributed storage (323 MB dataset)
- YARN resource management
- Scalable architecture for large datasets

---

## 📈 Performance Metrics

| Metric | Value |
|--------|-------|
| Dataset Size | 323 MB |
| Total Records | 1,317,750 |
| Unique Stations | 150 |
| MapReduce Job 1 Duration | ~155 seconds |
| MapReduce Job 2 Duration | ~123 seconds |
| MapReduce Job 3 Duration | ~97 seconds |
| Hive Table Load Time | ~88 seconds |

---

## 🎓 Demo Commands for Presentation

### Show HDFS Data
```bash
hdfs dfs -ls /input/
hdfs dfs -du -h /input/ev_charging_station_data_cleaned.csv
```

### Run MapReduce Job
```bash
cd mapreduce
hadoop jar WeatherImpactAnalysis.jar WeatherImpactAnalysis /input/ev_charging_station_data_cleaned.csv /output/demo_weather
hdfs dfs -cat /output/demo_weather/part-r-00000
```

### Execute Hive Query
```bash
hive -e "SELECT weather_condition, AVG(utilization_rate) AS avg_util FROM ev_charging_stations GROUP BY weather_condition ORDER BY avg_util DESC;"
```

### View Results in Web UI
- Open browser: http://localhost:5173
- Navigate to MapReduce page for job monitoring
- Navigate to Hive page for query execution

---

## 🛠️ Troubleshooting

### HDFS Safe Mode
```bash
hdfs dfsadmin -safemode leave
```

### Hive Metastore Issues
```bash
rm -rf ~/metastore_db
cd /usr/local/hive
schematool -dbType derby -initSchema
```

### Check Service Status
```bash
jps  # Should show: NameNode, DataNode, ResourceManager, NodeManager
```

### View Logs
```bash
# Backend logs
cd backend
tail -f backend.log

# Frontend logs
cd frontend
# Check terminal output

# Hadoop logs
cd /usr/local/hadoop/logs
tail -f hadoop-hduser-namenode-*.log
```

---

## 📊 Dataset Schema

| Column | Type | Description |
|--------|------|-------------|
| timestamp | STRING | Observation timestamp |
| station_id | STRING | Unique station identifier |
| station_name | STRING | Human-readable station name |
| network | STRING | Charging network operator |
| city | STRING | City name |
| state | STRING | US state code |
| latitude | DOUBLE | Latitude coordinate |
| longitude | DOUBLE | Longitude coordinate |
| utilization_rate | DOUBLE | Fraction of ports in use (0-1) |
| ports_total | INT | Total charging ports |
| ports_available | INT | Available ports |
| ports_occupied | INT | Occupied ports |
| station_status | STRING | operational/offline/maintenance |
| weather_condition | STRING | clear/rain/extreme_heat/etc |
| temperature_f | DOUBLE | Temperature in Fahrenheit |
| is_weekend | BOOLEAN | Weekend indicator |
| hour_of_day | INT | Hour (0-23) |
| ... | ... | 33 columns total |

---

## 🤝 Team Information

**Course:** 23CSE352 Big Data Analytics  
**Project Type:** Review 1  
**Technology Stack:** Hadoop 3.3.1, Hive 3.1.3, FastAPI, SvelteKit, Python, Java

---

## 📝 Technical Details

### Technologies Used
- **Big Data:** Hadoop MapReduce, Apache Hive, HDFS, YARN
- **Backend:** FastAPI (Python 3.12), asyncio, subprocess
- **Frontend:** SvelteKit, JavaScript (ES6+), CSS3
- **Build Tools:** Maven (Java), npm (JavaScript)
- **Data Processing:** Java 8, Python pandas (preprocessing)

### API Endpoints
- `GET /` - API health check
- `GET /api/hdfs/list` - List HDFS directory
- `GET /api/hdfs/read` - Read HDFS file
- `POST /api/mapreduce/submit` - Submit MapReduce job
- `GET /api/mapreduce/status/{job_id}` - Get job status
- `GET /api/mapreduce/list` - List all jobs
- `GET /api/hive/tables` - List Hive tables
- `POST /api/hive/query` - Execute custom query
- `GET /api/hive/predefined/{query_id}` - Execute predefined query

---

## 🎯 Project Objectives Achieved

- ✅ Data preprocessing and cleaning (1.3M+ records)
- ✅ HDFS distributed storage implementation
- ✅ Three distinct MapReduce analytical programs
- ✅ Apache Hive data warehousing with 15+ queries
- ✅ RESTful backend API with comprehensive services
- ✅ Modern web dashboard with real-time monitoring
- ✅ Professional UI/UX design
- ✅ Complete documentation and demo scripts

---

## 📚 References

- [Apache Hadoop Documentation](https://hadoop.apache.org/docs/stable/)
- [Apache Hive Documentation](https://hive.apache.org/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SvelteKit Documentation](https://kit.svelte.dev/)

---

**Project Status:** ✅ Complete and Operational  
**Last Updated:** August 12, 2026
