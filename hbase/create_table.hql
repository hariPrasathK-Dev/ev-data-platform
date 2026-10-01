# HBase Table Creation Script for EV Charging Station Analytics
# This script creates the ev_charging_stations table with optimized column families

# Drop table if exists (for clean setup)
disable 'ev_charging_stations'
drop 'ev_charging_stations'

# Create table with 6 column families
# Syntax: create 'table_name', {NAME => 'cf_name', VERSIONS => versions, TTL => seconds, COMPRESSION => 'type'}

create 'ev_charging_stations',
  {NAME => 'cf_station', VERSIONS => 1, COMPRESSION => 'SNAPPY', BLOOMFILTER => 'ROW'},
  {NAME => 'cf_metrics', VERSIONS => 1, COMPRESSION => 'SNAPPY', BLOOMFILTER => 'ROW'},
  {NAME => 'cf_pricing', VERSIONS => 1, COMPRESSION => 'SNAPPY', BLOOMFILTER => 'ROW'},
  {NAME => 'cf_weather', VERSIONS => 1, COMPRESSION => 'SNAPPY', BLOOMFILTER => 'ROW'},
  {NAME => 'cf_context', VERSIONS => 1, COMPRESSION => 'SNAPPY', BLOOMFILTER => 'ROW'},
  {NAME => 'cf_temporal', VERSIONS => 1, COMPRESSION => 'SNAPPY', BLOOMFILTER => 'ROW'}

# Display table description
describe 'ev_charging_stations'

# List all tables to confirm creation
list

# Note: Table is pre-split to avoid hotspotting
# Pre-split by station_id ranges for better distribution
# This can be added to create command with SPLITS option if needed
