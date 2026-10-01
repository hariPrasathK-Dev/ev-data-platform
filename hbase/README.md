# HBase Project: EV Charging Station Availability Analytics

> A comprehensive HBase implementation for managing and analyzing electric vehicle charging station data

[![HBase](https://img.shields.io/badge/HBase-Standalone-blue)]()
[![Java](https://img.shields.io/badge/Java-8%2B-orange)]()
[![Python](https://img.shields.io/badge/Python-3.x-green)]()
[![Dataset](https://img.shields.io/badge/Records-1.3M%2B-brightgreen)]()

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Dataset](#dataset)
- [HBase Design](#hbase-design)
- [Usage Guide](#usage-guide)
- [Documentation](#documentation)
- [Requirements](#requirements)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This project implements a production-ready HBase solution for **Electric Vehicle (EV) Charging Station Availability Analytics**. It demonstrates comprehensive HBase capabilities including schema design, shell operations, filters, and Java API integration.

### Real-World Application

- **EV Drivers**: Find available charging stations in real-time
- **Station Operators**: Monitor performance and optimize capacity
- **Infrastructure Planners**: Make data-driven expansion decisions
- **Business Analysts**: Analyze usage patterns and revenue

### Why HBase?

- ✅ **Scalability**: Handles 1.3M+ records with horizontal scaling
- ✅ **Performance**: Sub-second queries on large datasets
- ✅ **Flexibility**: Schema evolution without downtime
- ✅ **Time-Series Optimized**: Efficient temporal queries

---

## ✨ Features

### Core Implementation

- ✅ **6 Column Families**: Logical data organization (station, metrics, pricing, weather, context, temporal)
- ✅ **Optimized Row Key**: `station_id#reverse_timestamp` for fast queries
- ✅ **10+ Filters**: Comprehensive filter demonstrations with business use cases
- ✅ **Java API**: 450+ lines of production-grade code
- ✅ **Full CRUD**: GET, SCAN, DELETE, DELETEALL, COUNT operations
- ✅ **Real Dataset**: 1.3M+ records of EV charging station data

### Advanced Features

- 🔍 **Complex Filtering**: FilterList with AND/OR logic
- 📊 **Statistical Analysis**: Automated insights generation
- 🚀 **Bulk Loading**: Python-based data import pipeline
- 🧪 **Test Suite**: Comprehensive validation and testing
- 📝 **Documentation**: Complete guides and examples

---

## 🚀 Quick Start

### Prerequisites

```bash
# Check prerequisites
hbase version     # HBase installed
java -version     # Java 8+
python3 --version # Python 3.x
```

### 1. Complete Setup (Recommended)

```bash
cd hbase
bash setup_hbase.sh
```

This will:
- Create HBase table with 6 column families
- Load 5,000 sample records
- Verify installation

### 2. Run Full Demonstration

```bash
bash run_all_demos.sh
```

Demonstrates:
- Table creation and schema
- Data loading
- Basic operations (GET, SCAN, COUNT, DELETE)
- Analysis queries (12 business scenarios)
- Filter demonstrations (10+ filters)
- Java API execution

### 3. Quick Validation

```bash
bash quick_demo.sh
```

Fast validation without pauses.

---

## 📁 Project Structure

```
hbase/
│
├── 📚 Documentation
│   ├── README.md                      # This file
│   ├── PROJECT_REPORT.md              # Comprehensive report
│   ├── DESIGN.md                      # Design documentation
│   ├── README_JAVA_API.md             # Java guide
│   └── table_schema.txt               # Schema reference
│
├── 🗄️ HBase Scripts
│   ├── create_table.hql               # Table creation
│   ├── queries_basic.hql              # Basic operations
│   ├── queries_analysis.hql           # Business analytics
│   ├── queries_operations.hql         # GET/DELETE demos
│   └── filters.hql                    # Filter demonstrations
│
├── 🔧 Setup & Data Loading
│   ├── setup_hbase.sh                 # Master setup script
│   ├── generate_hbase_puts.py         # Data import generator
│   └── load_sample_data.sh            # Data loading
│
├── ☕ Java Implementation
│   ├── HighUtilizationStationFinder.java  # Main program
│   └── compile_and_run_java.sh        # Compilation script
│
└── 🧪 Testing & Demos
    ├── run_all_demos.sh               # Full demonstration
    ├── run_tests.sh                   # Test suite
    └── quick_demo.sh                  # Quick validation
```

---

## 📊 Dataset

### Overview

- **Records**: 1,317,750 time-series observations
- **Stations**: 150 charging stations
- **Networks**: 8 major networks (Tesla, ChargePoint, EVgo, etc.)
- **Cities**: 15 US metropolitan areas
- **Period**: 6 months (July - December 2025)
- **Interval**: 30-minute granularity

### Attributes (33 columns)

- **Station Info** (11): ID, name, network, location, charger type, etc.
- **Metrics** (8): Ports available, utilization, wait times, status
- **Pricing** (2): Current price, pricing type
- **Weather** (3): Temperature, precipitation, conditions
- **Context** (3): Gas prices, traffic, local events
- **Temporal** (6): Timestamp, hour, day, peak hour flags

### Sample Data

```csv
timestamp,station_id,station_name,network,city,utilization_rate,...
2025-07-01 00:00:00,EV00001,ChargePoint - Los Angeles #1,ChargePoint,Los Angeles,0.131,...
```

---

## 🏗️ HBase Design

### Table Name
`ev_charging_stations`

### Row Key Design

```
{station_id}#{reverse_timestamp}
Example: EV00001#9223370511254775807
```

**Benefits**:
- ✅ Co-locates all data for same station
- ✅ Most recent data appears first (reverse timestamp)
- ✅ Efficient station-specific queries
- ✅ Good load distribution (150 station prefixes)

### Column Families

| Family | Purpose | Columns | Use Case |
|--------|---------|---------|----------|
| `cf_station` | Static metadata | name, city, charger_type, etc. | Station lookup |
| `cf_metrics` | Availability data | ports, utilization, status | Real-time monitoring |
| `cf_pricing` | Pricing info | price, type | Revenue analysis |
| `cf_weather` | Weather data | temp, precipitation | Weather impact |
| `cf_context` | External factors | gas price, traffic | Correlation analysis |
| `cf_temporal` | Time features | hour, day, peak flags | Pattern analysis |

### Schema Rationale

- **Logical Grouping**: Related attributes together
- **Access Patterns**: Aligned with query patterns
- **Update Frequency**: Static vs. dynamic separation
- **Compression**: Similar types compress better

---

## 📖 Usage Guide

### Individual Components

#### 1. Table Operations

```bash
# Create table
hbase shell create_table.hql

# Basic operations
hbase shell queries_basic.hql

# Business analytics
hbase shell queries_analysis.hql
```

#### 2. Data Loading

```bash
# Generate PUT commands from CSV
python3 generate_hbase_puts.py ../ev_charging_station_data.csv 1000 > puts.hql

# Load into HBase
hbase shell puts.hql
```

#### 3. Filter Demonstrations

```bash
# Run all filters
hbase shell filters.hql
```

**Filter Examples**:
- High utilization (>80%)
- Weather impact (extreme heat)
- Station-specific (PrefixFilter)
- Peak hour congestion (FilterList)
- Operational issues (OR logic)

#### 4. Java API

```bash
# Compile and run
bash compile_and_run_java.sh

# Or manually
javac -cp $(hbase classpath) HighUtilizationStationFinder.java
java -cp $(hbase classpath):. HighUtilizationStationFinder
```

**Java Program Features**:
- Connection management
- SingleColumnValueFilter usage
- FilterList combinations
- Result parsing
- Statistical analysis

---

## 📚 Documentation

### Main Documents

1. **[PROJECT_REPORT.md](PROJECT_REPORT.md)**: Comprehensive project report
   - Problem statement and objectives
   - Complete dataset description
   - Detailed design rationale
   - All operations explained
   - Results and analysis
   - Full reference guide

2. **[DESIGN.md](DESIGN.md)**: Technical design document
   - Architecture overview
   - Row key design rationale
   - Column family design
   - Query patterns
   - Performance considerations

3. **[README_JAVA_API.md](README_JAVA_API.md)**: Java implementation guide
   - Code structure
   - API usage examples
   - Compilation instructions
   - Troubleshooting

4. **[table_schema.txt](table_schema.txt)**: Schema reference
   - Column family definitions
   - Qualifier descriptions
   - Data types
   - Sample data

### Quick References

**HBase Shell Commands**:
```bash
# List tables
list

# Describe table
describe 'ev_charging_stations'

# Count rows
count 'ev_charging_stations'

# Scan with limit
scan 'ev_charging_stations', {LIMIT => 10}

# Get specific row
get 'ev_charging_stations', 'EV00001#9223370511254775807'

# Delete cell
delete 'ev_charging_stations', 'row_key', 'cf:column'

# Delete row
deleteall 'ev_charging_stations', 'row_key'
```

**Common Queries**:
```bash
# Latest status for station
scan 'ev_charging_stations', {STARTROW => 'EV00001#', LIMIT => 1}

# High utilization stations
scan 'ev_charging_stations', {
  FILTER => "SingleColumnValueFilter('cf_metrics', 'utilization_rate', >, 'binary:0.8')",
  LIMIT => 10
}

# Station-specific history
scan 'ev_charging_stations', {
  STARTROW => 'EV00001#',
  STOPROW => 'EV00001~',
  LIMIT => 20
}
```

---

## ⚙️ Requirements

### System Requirements

- **Operating System**: Linux/Unix (tested on Ubuntu)
- **HBase**: Standalone or Distributed mode
- **Java**: JDK 8 or higher
- **Python**: 3.x
- **Memory**: Minimum 2GB RAM (4GB recommended)
- **Storage**: 1GB for sample data

### Software Dependencies

```bash
# Check installations
hbase version      # Apache HBase
java -version      # Java Development Kit
javac -version     # Java Compiler
python3 --version  # Python 3
```

### Environment Variables

```bash
# Required
export HBASE_HOME=/path/to/hbase

# Optional (HBase will auto-detect)
export JAVA_HOME=/path/to/java
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Table Not Found

**Error**: `ERROR: Table 'ev_charging_stations' does not exist`

**Solution**:
```bash
bash setup_hbase.sh
# or
hbase shell create_table.hql
```

#### 2. No Data in Table

**Error**: `0 row(s) in 0.0000 seconds`

**Solution**:
```bash
bash load_sample_data.sh
```

#### 3. Java Compilation Error

**Error**: `ClassNotFoundException: org.apache.hadoop.hbase.HBaseConfiguration`

**Solution**:
```bash
export HBASE_CP=$(hbase classpath)
javac -cp "$HBASE_CP" HighUtilizationStationFinder.java
```

#### 4. HBase Not Running

**Error**: `Connection refused`

**Solution**:
```bash
start-hbase.sh
# Check status
hbase shell
> status
```

#### 5. Permission Denied

**Error**: `Permission denied: compile_and_run_java.sh`

**Solution**:
```bash
chmod +x *.sh
```

### Getting Help

1. **Run Test Suite**: `bash run_tests.sh` - validates entire setup
2. **Check Logs**: Review `demo_output/` directory
3. **HBase Shell**: `hbase shell` - interactive testing
4. **Documentation**: Refer to PROJECT_REPORT.md for details

---

## 🎓 Learning Outcomes

### HBase Concepts Mastered

- ✅ Schema design for time-series data
- ✅ Row key optimization strategies
- ✅ Column family organization
- ✅ Server-side filtering techniques
- ✅ Java API integration
- ✅ Bulk data loading
- ✅ Query optimization

### Skills Demonstrated

- 🎯 Real-world problem solving
- 🎯 NoSQL database design
- 🎯 Big data architecture
- 🎯 Performance optimization
- 🎯 Business analytics
- 🎯 Technical documentation

---

## 📈 Performance Metrics

### Query Performance

- **Latest Status Lookup**: <50ms
- **Station-Specific Scan**: <100ms
- **Filtered Scan (1000 rows)**: <2 seconds
- **Count Operation**: <5 seconds (5000 rows)

### Scalability

- **Current**: 5,000 records (demo dataset)
- **Full Dataset**: 1.3M records supported
- **Projected**: 88M records (1000 stations, 5 years)
- **Storage**: ~500MB compressed (full dataset)

---

## 🔄 Next Steps

### After Setup

1. **Explore Data**: Run `bash quick_demo.sh`
2. **Full Demo**: Run `bash run_all_demos.sh`
3. **Custom Queries**: Modify `.hql` files
4. **Java Development**: Extend `HighUtilizationStationFinder.java`
5. **Load More Data**: Adjust limit in `load_sample_data.sh`

### Extensions

- 📊 Add Phoenix for SQL queries
- 🔄 Implement Kafka streaming
- 🤖 Build ML prediction models
- 🌐 Create REST API
- 📱 Develop mobile app backend

---

## 📄 License

This is an educational project demonstrating HBase capabilities for real-world applications.

---

## 👥 Contributing

This project serves as a comprehensive example for learning HBase. Feel free to:

- Extend the Java program
- Add new analysis queries
- Implement additional filters
- Optimize performance
- Enhance documentation

---

## 🎉 Project Highlights

### What Makes This Special

- ✨ **Real-World Dataset**: Actual charging station patterns
- ✨ **Production-Ready**: Professional code quality
- ✨ **Comprehensive**: Covers all HBase features
- ✨ **Well-Documented**: Extensive guides and examples
- ✨ **Business-Focused**: Real insights, not just demos
- ✨ **Fully Automated**: One-command setup and demos

### Project Statistics

- **Files**: 16 implementation files
- **Documentation**: 4 comprehensive guides
- **Code**: 1500+ lines (Java, Python, Shell)
- **Queries**: 30+ analytical queries
- **Filters**: 14 different filter types
- **Test Cases**: 25+ validation tests

---

## 📞 Support

For questions or issues:

1. Review [PROJECT_REPORT.md](PROJECT_REPORT.md)
2. Check [Troubleshooting](#troubleshooting) section
3. Run `bash run_tests.sh` for diagnostics
4. Examine `demo_output/` logs

---

## 🙏 Acknowledgments

This project demonstrates practical HBase application for the rapidly growing electric vehicle infrastructure space, showcasing how NoSQL databases solve real-world big data challenges.

---

**Built with ❤️ for HBase learning and EV infrastructure analytics**

*Last Updated: 2026*

---

## Quick Command Reference

```bash
# Setup & Testing
bash setup_hbase.sh          # Complete setup
bash run_tests.sh            # Run all tests
bash quick_demo.sh           # Quick validation
bash run_all_demos.sh        # Full demonstration

# HBase Operations
hbase shell queries_basic.hql     # Basic operations
hbase shell queries_analysis.hql  # Business queries
hbase shell filters.hql           # Filter demos

# Java API
bash compile_and_run_java.sh     # Compile and run

# Data Management
python3 generate_hbase_puts.py ../ev_charging_station_data.csv 1000
bash load_sample_data.sh
```

---

**🚀 Ready to explore? Start with:** `bash setup_hbase.sh`
