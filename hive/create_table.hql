-- ============================================================================
-- Hive Table Creation: EV Charging Station Availability Analytics
-- ============================================================================
-- 
-- Purpose: Create external table for EV charging dataset in HDFS
-- Dataset: 1.3M+ records, 33 columns, 323 MB
-- Location: /home/hduser/ev-charging-station-availability-analytics/ev_charging_station_data_cleaned.csv
--
-- ============================================================================

-- Drop table if exists (for clean re-creation)
DROP TABLE IF EXISTS ev_charging_stations;

-- Create external table
CREATE EXTERNAL TABLE IF NOT EXISTS ev_charging_stations (
    -- Temporal fields
    `timestamp` STRING COMMENT 'Observation timestamp (YYYY-MM-DD HH:MM:SS)',
    
    -- Station identifiers
    station_id STRING COMMENT 'Unique station identifier (e.g., EV00001)',
    station_name STRING COMMENT 'Human-readable station name',
    network STRING COMMENT 'Charging network operator (8 networks)',
    
    -- Location attributes
    city STRING COMMENT 'City name',
    state STRING COMMENT 'US state code (2 letters)',
    latitude DOUBLE COMMENT 'Latitude coordinate',
    longitude DOUBLE COMMENT 'Longitude coordinate',
    location_type STRING COMMENT 'Type of location (Airport, Urban, Highway, etc.)',
    
    -- Station characteristics
    charger_type STRING COMMENT 'Charging technology (DC Fast, Level 2, etc.)',
    power_output_kw DOUBLE COMMENT 'Maximum power output in kilowatts',
    amenities_nearby STRING COMMENT 'Nearby amenities (Restaurant, Hotel, etc.)',
    
    -- Port availability metrics (CORE BUSINESS METRICS)
    ports_total INT COMMENT 'Total number of charging ports',
    ports_available INT COMMENT 'Currently available ports',
    ports_occupied INT COMMENT 'Currently occupied ports',
    ports_out_of_service INT COMMENT 'Ports under maintenance',
    utilization_rate DOUBLE COMMENT 'Fraction of ports in use (0-1)',
    
    -- Station status
    station_status STRING COMMENT 'operational | offline | under_maintenance | partial_outage',
    
    -- Wait time and duration
    estimated_wait_time_mins INT COMMENT 'Expected wait time in minutes',
    avg_session_duration_mins INT COMMENT 'Average charging session duration',
    
    -- Pricing
    current_price DOUBLE COMMENT 'Current charging price ($/kWh or $/min)',
    pricing_type STRING COMMENT 'per_kwh | free | per_minute',
    
    -- Environmental context
    temperature_f DOUBLE COMMENT 'Temperature in Fahrenheit',
    precipitation_mm DOUBLE COMMENT 'Precipitation in millimeters',
    weather_condition STRING COMMENT 'clear | cloudy | rain | extreme_heat | freezing',
    
    -- Economic and traffic context
    gas_price_per_gallon DOUBLE COMMENT 'Local gasoline price per gallon',
    traffic_congestion_index INT COMMENT 'Traffic congestion level (1-10)',
    local_event STRING COMMENT 'Local event (concert, sports_game, festival, etc.)',
    
    -- Time categorization
    is_weekend BOOLEAN COMMENT 'Weekend indicator (True/False)',
    is_peak_hour BOOLEAN COMMENT 'Peak hour indicator (7-9am, 5-8pm)',
    hour_of_day INT COMMENT 'Hour of day (0-23)',
    day_of_week INT COMMENT 'Day of week (0=Monday, 6=Sunday)',
    `month` INT COMMENT 'Month (1-12)'
)
COMMENT 'EV Charging Station Availability Analytics Dataset - 1.3M+ records covering Jul-Dec 2025'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/home/hduser/ev-charging-station-availability-analytics/'
TBLPROPERTIES (
    'skip.header.line.count'='1',
    'creator'='hduser',
    'created_date'='2026-08-12',
    'dataset_version'='1.0',
    'record_count'='1317750',
    'data_size_mb'='323'
);

-- ============================================================================
-- Verify table creation
-- ============================================================================

-- Show table structure
DESCRIBE ev_charging_stations;

-- Show extended table information
DESCRIBE EXTENDED ev_charging_stations;

-- Count total records
SELECT COUNT(*) AS total_records FROM ev_charging_stations;

-- Preview first 10 records
SELECT * FROM ev_charging_stations LIMIT 10;

-- ============================================================================
-- Basic validation queries
-- ============================================================================

-- Check unique stations
SELECT COUNT(DISTINCT station_id) AS unique_stations FROM ev_charging_stations;

-- Check networks
SELECT network, COUNT(*) AS record_count 
FROM ev_charging_stations 
GROUP BY network 
ORDER BY record_count DESC;

-- Check date range
SELECT 
    MIN(`timestamp`) AS earliest_date,
    MAX(`timestamp`) AS latest_date
FROM ev_charging_stations;

-- ============================================================================
-- Table created successfully!
-- Next: Execute analytical queries from queries.hql
-- ============================================================================
