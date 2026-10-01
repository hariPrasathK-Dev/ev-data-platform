# ==============================================================================
# HBase Analysis Queries - EV Charging Station Analytics
# Application-specific queries for real-world use cases
# ==============================================================================

# -----------------------------------------------------------------------------
# Analysis Query 1: Get Current Station Status
# Use Case: Mobile app showing real-time availability
# -----------------------------------------------------------------------------
echo "=== Analysis 1: Current Station Status ==="
echo "Getting latest status for station EV00001..."
scan 'ev_charging_stations', {STARTROW => 'EV00001#', STOPROW => 'EV00001~', LIMIT => 1, COLUMNS => ['cf_station:name', 'cf_station:city', 'cf_metrics:ports_available', 'cf_metrics:ports_total', 'cf_metrics:utilization_rate', 'cf_metrics:station_status', 'cf_pricing:current_price']}

# -----------------------------------------------------------------------------
# Analysis Query 2: Station Information Lookup
# Use Case: Get complete station details for a specific location
# -----------------------------------------------------------------------------
echo ""
echo "=== Analysis 2: Complete Station Information ==="
scan 'ev_charging_stations', {STARTROW => 'EV00010#', STOPROW => 'EV00010~', LIMIT => 1, COLUMNS => 'cf_station'}

# -----------------------------------------------------------------------------
# Analysis Query 3: Historical Availability Pattern
# Use Case: Analyze usage patterns over time for a station
# -----------------------------------------------------------------------------
echo ""
echo "=== Analysis 3: Historical Availability (Last 20 readings) ==="
echo "Station: EV00001"
scan 'ev_charging_stations', {STARTROW => 'EV00001#', STOPROW => 'EV00001~', LIMIT => 20, COLUMNS => ['cf_temporal:timestamp', 'cf_metrics:ports_available', 'cf_metrics:utilization_rate', 'cf_temporal:hour', 'cf_temporal:is_peak_hour']}

# -----------------------------------------------------------------------------
# Analysis Query 4: Pricing Analysis
# Use Case: Compare pricing across time for dynamic pricing analysis
# -----------------------------------------------------------------------------
echo ""
echo "=== Analysis 4: Pricing Patterns ==="
scan 'ev_charging_stations', {STARTROW => 'EV00005#', STOPROW => 'EV00005~', LIMIT => 15, COLUMNS => ['cf_temporal:timestamp', 'cf_temporal:hour', 'cf_pricing:current_price', 'cf_pricing:pricing_type', 'cf_metrics:utilization_rate']}

# -----------------------------------------------------------------------------
# Analysis Query 5: Weather Impact Analysis
# Use Case: Correlate weather conditions with station usage
# -----------------------------------------------------------------------------
echo ""
echo "=== Analysis 5: Weather Impact on Usage ==="
scan 'ev_charging_stations', {LIMIT => 10, COLUMNS => ['cf_station:station_id', 'cf_weather:weather_condition', 'cf_weather:temperature_f', 'cf_metrics:utilization_rate', 'cf_metrics:ports_occupied']}

# -----------------------------------------------------------------------------
# Analysis Query 6: Peak Hour Utilization
# Use Case: Identify station load during peak hours
# -----------------------------------------------------------------------------
echo ""
echo "=== Analysis 6: Peak Hour Records ==="
echo "Showing records during peak hours for analysis..."
scan 'ev_charging_stations', {LIMIT => 15, COLUMNS => ['cf_station:name', 'cf_temporal:hour', 'cf_temporal:is_peak_hour', 'cf_metrics:utilization_rate', 'cf_metrics:wait_time_mins']}

# -----------------------------------------------------------------------------
# Analysis Query 7: Station Status Monitoring
# Use Case: Identify stations under maintenance or offline
# -----------------------------------------------------------------------------
echo ""
echo "=== Analysis 7: Station Status Distribution ==="
scan 'ev_charging_stations', {LIMIT => 20, COLUMNS => ['cf_station:station_id', 'cf_station:name', 'cf_metrics:station_status', 'cf_metrics:ports_out_of_service', 'cf_temporal:timestamp']}

# -----------------------------------------------------------------------------
# Analysis Query 8: Network Comparison
# Use Case: Compare different charging networks
# -----------------------------------------------------------------------------
echo ""
echo "=== Analysis 8: Network Analysis ==="
scan 'ev_charging_stations', {LIMIT => 10, COLUMNS => ['cf_station:network', 'cf_station:city', 'cf_station:charger_type', 'cf_station:power_kw', 'cf_metrics:utilization_rate']}

# -----------------------------------------------------------------------------
# Analysis Query 9: Location-Based Analysis
# Use Case: Analyze stations by location type (Highway, Urban, Shopping, etc.)
# -----------------------------------------------------------------------------
echo ""
echo "=== Analysis 9: Location Type Analysis ==="
scan 'ev_charging_stations', {LIMIT => 15, COLUMNS => ['cf_station:name', 'cf_station:location_type', 'cf_station:city', 'cf_metrics:utilization_rate', 'cf_temporal:is_weekend']}

# -----------------------------------------------------------------------------
# Analysis Query 10: External Factors Impact
# Use Case: Analyze how external factors affect charging demand
# -----------------------------------------------------------------------------
echo ""
echo "=== Analysis 10: External Factors Analysis ==="
scan 'ev_charging_stations', {LIMIT => 10, COLUMNS => ['cf_station:station_id', 'cf_context:gas_price', 'cf_context:traffic_index', 'cf_context:local_event', 'cf_metrics:utilization_rate']}

# -----------------------------------------------------------------------------
# Analysis Query 11: High-Power Charger Analysis
# Use Case: Find fast-charging stations and their utilization
# -----------------------------------------------------------------------------
echo ""
echo "=== Analysis 11: Fast Charging Stations ==="
scan 'ev_charging_stations', {LIMIT => 10, COLUMNS => ['cf_station:name', 'cf_station:charger_type', 'cf_station:power_kw', 'cf_metrics:avg_session_mins', 'cf_metrics:utilization_rate']}

# -----------------------------------------------------------------------------
# Analysis Query 12: Time-Series Data for ML Preparation
# Use Case: Extract features for machine learning models
# -----------------------------------------------------------------------------
echo ""
echo "=== Analysis 12: ML Feature Extraction ==="
scan 'ev_charging_stations', {STARTROW => 'EV00020#', STOPROW => 'EV00020~', LIMIT => 10, COLUMNS => ['cf_temporal:timestamp', 'cf_temporal:hour', 'cf_temporal:day_of_week', 'cf_temporal:is_weekend', 'cf_metrics:utilization_rate', 'cf_weather:temperature_f', 'cf_context:traffic_index']}

# ==============================================================================
# Summary: These queries demonstrate real-world analytical use cases for
# EV charging station management, user applications, and business intelligence
# ==============================================================================
