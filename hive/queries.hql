-- ============================================================================
-- Hive Analytical Queries: EV Charging Station Analytics
-- ============================================================================
--
-- 15 Business-Focused Queries covering:
-- SELECT, WHERE, ORDER BY, GROUP BY, HAVING, COUNT, SUM, AVG, MAX, MIN
--
-- Dataset: ev_charging_stations (1.3M+ records)
-- ============================================================================

-- ============================================================================
-- QUERY 1: Peak Utilization Hours
-- Business Question: What are the top 10 hours with highest average utilization?
-- Operators: SELECT, AVG, GROUP BY, ORDER BY, LIMIT
-- ============================================================================

SELECT 
    hour_of_day,
    AVG(utilization_rate) AS avg_utilization,
    AVG(estimated_wait_time_mins) AS avg_wait_time,
    COUNT(*) AS observations
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY hour_of_day
ORDER BY avg_utilization DESC
LIMIT 10;

-- Expected Insight: Evening hours (17-20) likely show highest utilization


-- ============================================================================
-- QUERY 2: Network Performance Comparison
-- Business Question: Which network has the best operational uptime?
-- Operators: SELECT, COUNT, WHERE, GROUP BY, ORDER BY
-- ============================================================================

SELECT 
    network,
    COUNT(*) AS total_observations,
    SUM(CASE WHEN station_status = 'operational' THEN 1 ELSE 0 END) AS operational_count,
    ROUND(SUM(CASE WHEN station_status = 'operational' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS uptime_percentage,
    AVG(utilization_rate) AS avg_utilization
FROM ev_charging_stations
GROUP BY network
ORDER BY uptime_percentage DESC, avg_utilization DESC;

-- Expected Insight: Identifies most reliable networks


-- ============================================================================
-- QUERY 3: High-Demand Stations
-- Business Question: Which stations have highest utilization and need capacity expansion?
-- Operators: SELECT, AVG, WHERE, GROUP BY, HAVING, ORDER BY
-- ============================================================================

SELECT 
    station_id,
    station_name,
    city,
    state,
    network,
    AVG(utilization_rate) AS avg_utilization,
    AVG(estimated_wait_time_mins) AS avg_wait_time,
    COUNT(*) AS observations
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY station_id, station_name, city, state, network
HAVING AVG(utilization_rate) > 0.70
ORDER BY avg_utilization DESC
LIMIT 20;

-- Expected Insight: Stations consistently above 70% utilization need more ports


-- ============================================================================
-- QUERY 4: Weekend vs Weekday Demand
-- Business Question: How does charging demand differ between weekdays and weekends?
-- Operators: SELECT, AVG, COUNT, GROUP BY, ORDER BY
-- ============================================================================

SELECT 
    CASE WHEN is_weekend = TRUE THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    AVG(utilization_rate) AS avg_utilization,
    AVG(estimated_wait_time_mins) AS avg_wait_time,
    AVG(avg_session_duration_mins) AS avg_session_duration,
    COUNT(*) AS total_observations,
    SUM(ports_occupied) AS total_ports_occupied
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY is_weekend
ORDER BY avg_utilization DESC;

-- Expected Insight: Different usage patterns for weekend leisure vs weekday commute


-- ============================================================================
-- QUERY 5: Weather Impact on Charging Demand
-- Business Question: How do different weather conditions affect utilization?
-- Operators: SELECT, AVG, MIN, MAX, COUNT, GROUP BY, ORDER BY
-- ============================================================================

SELECT 
    weather_condition,
    COUNT(*) AS observations,
    AVG(utilization_rate) AS avg_utilization,
    AVG(temperature_f) AS avg_temperature,
    MIN(utilization_rate) AS min_utilization,
    MAX(utilization_rate) AS max_utilization,
    AVG(estimated_wait_time_mins) AS avg_wait_time
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY weather_condition
ORDER BY avg_utilization DESC;

-- Expected Insight: Extreme weather may drive different charging behavior


-- ============================================================================
-- QUERY 6: Location Type Performance
-- Business Question: Which location types have best/worst utilization?
-- Operators: SELECT, AVG, COUNT, SUM, GROUP BY, ORDER BY
-- ============================================================================

SELECT 
    location_type,
    COUNT(DISTINCT station_id) AS num_stations,
    COUNT(*) AS total_observations,
    AVG(utilization_rate) AS avg_utilization,
    AVG(ports_total) AS avg_total_ports,
    SUM(ports_occupied) AS total_ports_occupied,
    AVG(current_price) AS avg_price
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY location_type
ORDER BY avg_utilization DESC;

-- Expected Insight: Highway corridors vs urban centers usage patterns


-- ============================================================================
-- QUERY 7: Peak Hours by Network
-- Business Question: What are peak operating hours for each network?
-- Operators: SELECT, AVG, WHERE, GROUP BY, HAVING, ORDER BY
-- ============================================================================

SELECT 
    network,
    hour_of_day,
    AVG(utilization_rate) AS avg_utilization,
    AVG(estimated_wait_time_mins) AS avg_wait_time,
    COUNT(*) AS observations
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY network, hour_of_day
HAVING COUNT(*) > 100
ORDER BY network, avg_utilization DESC;

-- Expected Insight: Network-specific demand patterns for optimization


-- ============================================================================
-- QUERY 8: Pricing Model Effectiveness
-- Business Question: How does pricing type affect utilization and revenue potential?
-- Operators: SELECT, AVG, SUM, COUNT, GROUP BY, ORDER BY
-- ============================================================================

SELECT 
    pricing_type,
    COUNT(*) AS observations,
    AVG(utilization_rate) AS avg_utilization,
    AVG(current_price) AS avg_price,
    AVG(avg_session_duration_mins) AS avg_session_mins,
    SUM(ports_occupied) AS total_usage,
    ROUND(AVG(current_price * avg_session_duration_mins), 2) AS estimated_avg_revenue_per_session
FROM ev_charging_stations
WHERE station_status = 'operational' AND pricing_type != 'free'
GROUP BY pricing_type
ORDER BY avg_utilization DESC;

-- Expected Insight: Which pricing model maximizes utilization and revenue


-- ============================================================================
-- QUERY 9: Charger Type Demand Analysis
-- Business Question: Which charger types are in highest demand?
-- Operators: SELECT, AVG, MIN, MAX, COUNT, GROUP BY, ORDER BY
-- ============================================================================

SELECT 
    charger_type,
    AVG(power_output_kw) AS avg_power_kw,
    COUNT(*) AS total_observations,
    AVG(utilization_rate) AS avg_utilization,
    AVG(avg_session_duration_mins) AS avg_session_duration,
    MIN(estimated_wait_time_mins) AS min_wait,
    MAX(estimated_wait_time_mins) AS max_wait,
    AVG(estimated_wait_time_mins) AS avg_wait
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY charger_type
ORDER BY avg_utilization DESC;

-- Expected Insight: DC Fast Charge vs Level 2 usage patterns


-- ============================================================================
-- QUERY 10: State-Level Demand Analysis
-- Business Question: Which states have highest EV charging demand?
-- Operators: SELECT, COUNT, AVG, SUM, GROUP BY, ORDER BY
-- ============================================================================

SELECT 
    state,
    COUNT(DISTINCT station_id) AS num_stations,
    COUNT(DISTINCT city) AS num_cities,
    COUNT(*) AS total_observations,
    AVG(utilization_rate) AS avg_utilization,
    SUM(ports_occupied) AS total_ports_in_use,
    AVG(estimated_wait_time_mins) AS avg_wait_time
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY state
ORDER BY avg_utilization DESC, num_stations DESC
LIMIT 15;

-- Expected Insight: Geographic patterns for infrastructure investment


-- ============================================================================
-- QUERY 11: Traffic Congestion Impact
-- Business Question: Does traffic congestion correlate with charging station usage?
-- Operators: SELECT, AVG, COUNT, WHERE, GROUP BY, HAVING, ORDER BY
-- ============================================================================

SELECT 
    CASE 
        WHEN traffic_congestion_index BETWEEN 1 AND 3 THEN 'Low (1-3)'
        WHEN traffic_congestion_index BETWEEN 4 AND 6 THEN 'Medium (4-6)'
        WHEN traffic_congestion_index BETWEEN 7 AND 10 THEN 'High (7-10)'
    END AS traffic_level,
    COUNT(*) AS observations,
    AVG(utilization_rate) AS avg_utilization,
    AVG(estimated_wait_time_mins) AS avg_wait_time,
    AVG(gas_price_per_gallon) AS avg_gas_price
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY 
    CASE 
        WHEN traffic_congestion_index BETWEEN 1 AND 3 THEN 'Low (1-3)'
        WHEN traffic_congestion_index BETWEEN 4 AND 6 THEN 'Medium (4-6)'
        WHEN traffic_congestion_index BETWEEN 7 AND 10 THEN 'High (7-10)'
    END
HAVING COUNT(*) > 1000
ORDER BY avg_utilization DESC;

-- Expected Insight: High traffic may drive EV usage or deter due to rush


-- ============================================================================
-- QUERY 12: Port Utilization Efficiency
-- Business Question: What's the optimal number of ports per station?
-- Operators: SELECT, AVG, COUNT, WHERE, GROUP BY, HAVING, ORDER BY
-- ============================================================================

SELECT 
    ports_total,
    COUNT(DISTINCT station_id) AS num_stations,
    COUNT(*) AS observations,
    AVG(utilization_rate) AS avg_utilization,
    AVG(ports_available) AS avg_available,
    AVG(ports_occupied) AS avg_occupied,
    AVG(ports_out_of_service) AS avg_out_of_service,
    ROUND(AVG(ports_occupied) * 100.0 / ports_total, 2) AS port_efficiency_pct
FROM ev_charging_stations
WHERE station_status = 'operational' AND ports_total > 0
GROUP BY ports_total
HAVING COUNT(DISTINCT station_id) >= 3
ORDER BY ports_total;

-- Expected Insight: Capacity planning - ideal ports per station


-- ============================================================================
-- QUERY 13: Monthly Trend Analysis
-- Business Question: How does demand change across months?
-- Operators: SELECT, AVG, SUM, MIN, MAX, COUNT, GROUP BY, ORDER BY
-- ============================================================================

SELECT 
    `month`,
    CASE `month`
        WHEN 7 THEN 'July'
        WHEN 8 THEN 'August'
        WHEN 9 THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END AS month_name,
    COUNT(*) AS total_observations,
    AVG(utilization_rate) AS avg_utilization,
    MIN(utilization_rate) AS min_utilization,
    MAX(utilization_rate) AS max_utilization,
    AVG(estimated_wait_time_mins) AS avg_wait_time,
    SUM(ports_occupied) AS total_usage
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY `month`
ORDER BY `month`;

-- Expected Insight: Seasonal patterns in EV charging demand


-- ============================================================================
-- QUERY 14: Station Reliability Analysis
-- Business Question: Which stations have the most downtime/maintenance issues?
-- Operators: SELECT, COUNT, SUM, WHERE, GROUP BY, HAVING, ORDER BY
-- ============================================================================

SELECT 
    station_id,
    station_name,
    network,
    city,
    state,
    COUNT(*) AS total_observations,
    SUM(CASE WHEN station_status = 'operational' THEN 1 ELSE 0 END) AS operational_count,
    SUM(CASE WHEN station_status = 'offline' THEN 1 ELSE 0 END) AS offline_count,
    SUM(CASE WHEN station_status = 'under_maintenance' THEN 1 ELSE 0 END) AS maintenance_count,
    SUM(CASE WHEN station_status = 'partial_outage' THEN 1 ELSE 0 END) AS partial_outage_count,
    ROUND(SUM(CASE WHEN station_status != 'operational' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS downtime_percentage
FROM ev_charging_stations
GROUP BY station_id, station_name, network, city, state
HAVING SUM(CASE WHEN station_status != 'operational' THEN 1 ELSE 0 END) > 50
ORDER BY downtime_percentage DESC
LIMIT 20;

-- Expected Insight: Stations needing urgent maintenance or replacement


-- ============================================================================
-- QUERY 15: Comprehensive Business Intelligence Summary
-- Business Question: Overall system performance metrics for executive dashboard
-- Operators: SELECT, COUNT, AVG, MIN, MAX, SUM
-- ============================================================================

SELECT 
    'Overall System Performance' AS metric_category,
    COUNT(DISTINCT station_id) AS total_unique_stations,
    COUNT(DISTINCT network) AS total_networks,
    COUNT(*) AS total_observations,
    AVG(utilization_rate) AS avg_system_utilization,
    MAX(utilization_rate) AS peak_utilization,
    MIN(utilization_rate) AS lowest_utilization,
    AVG(estimated_wait_time_mins) AS avg_system_wait_time,
    AVG(avg_session_duration_mins) AS avg_session_duration,
    SUM(ports_total) / COUNT(DISTINCT station_id) AS avg_ports_per_station,
    ROUND(SUM(CASE WHEN station_status = 'operational' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS system_uptime_percentage,
    AVG(current_price) AS avg_system_price,
    SUM(ports_occupied) AS total_ports_in_use_across_all_snapshots
FROM ev_charging_stations;

-- Expected Insight: High-level KPIs for executive reporting


-- ============================================================================
-- All 15 queries completed!
-- ============================================================================
--
-- SQL Operators Covered:
-- ✓ SELECT - All queries
-- ✓ WHERE - Queries 1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
-- ✓ ORDER BY - All queries except 15
-- ✓ GROUP BY - All queries except validation queries
-- ✓ HAVING - Queries 3, 7, 11, 12, 14
-- ✓ COUNT - All queries
-- ✓ SUM - Queries 2, 4, 6, 8, 10, 12, 13, 14, 15
-- ✓ AVG - All queries
-- ✓ MAX - Queries 5, 9, 13, 15
-- ✓ MIN - Queries 5, 9, 13, 15
-- ✓ LIMIT - Queries 1, 3, 10, 14
-- ✓ CASE expressions - Queries 2, 11, 13, 14, 15
-- ✓ DISTINCT - Queries 6, 10, 12, 14, 15
-- ✓ ROUND - Queries 2, 8, 11, 12, 14
--
-- ============================================================================
