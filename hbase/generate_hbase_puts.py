#!/usr/bin/env python3
"""
HBase Data Import Script for EV Charging Station Analytics
Reads CSV data and generates HBase put commands
"""

import csv
import sys
from datetime import datetime

def timestamp_to_reverse(timestamp_str):
    """
    Convert timestamp string to reverse timestamp for row key
    Format: YYYY-MM-DD HH:MM:SS -> reverse epoch millis
    """
    dt = datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S')
    epoch_millis = int(dt.timestamp() * 1000)
    reverse_timestamp = 9223372036854775807 - epoch_millis  # Long.MAX_VALUE - epoch
    return reverse_timestamp

def escape_value(value):
    """Escape special characters for HBase shell"""
    if value is None or value == '':
        return ''
    # Handle quotes and special characters
    value = str(value).replace("'", "\\'")
    return value

def generate_put_command(row_data):
    """
    Generate HBase put command from CSV row
    """
    station_id = row_data['station_id']
    timestamp_str = row_data['timestamp']
    
    # Create row key: station_id#reverse_timestamp
    reverse_ts = timestamp_to_reverse(timestamp_str)
    row_key = f"{station_id}#{reverse_ts}"
    
    # Build put command with all column families
    put_parts = [f"put 'ev_charging_stations', '{row_key}'"]
    
    # cf_station columns
    put_parts.append(f", 'cf_station:name', '{escape_value(row_data['station_name'])}'")
    put_parts.append(f", 'cf_station:network', '{escape_value(row_data['network'])}'")
    put_parts.append(f", 'cf_station:city', '{escape_value(row_data['city'])}'")
    put_parts.append(f", 'cf_station:state', '{escape_value(row_data['state'])}'")
    put_parts.append(f", 'cf_station:latitude', '{escape_value(row_data['latitude'])}'")
    put_parts.append(f", 'cf_station:longitude', '{escape_value(row_data['longitude'])}'")
    put_parts.append(f", 'cf_station:location_type', '{escape_value(row_data['location_type'])}'")
    put_parts.append(f", 'cf_station:charger_type', '{escape_value(row_data['charger_type'])}'")
    put_parts.append(f", 'cf_station:power_kw', '{escape_value(row_data['power_output_kw'])}'")
    put_parts.append(f", 'cf_station:amenities', '{escape_value(row_data['amenities_nearby'])}'")
    
    # cf_metrics columns
    put_parts.append(f", 'cf_metrics:ports_total', '{escape_value(row_data['ports_total'])}'")
    put_parts.append(f", 'cf_metrics:ports_available', '{escape_value(row_data['ports_available'])}'")
    put_parts.append(f", 'cf_metrics:ports_occupied', '{escape_value(row_data['ports_occupied'])}'")
    put_parts.append(f", 'cf_metrics:ports_out_of_service', '{escape_value(row_data['ports_out_of_service'])}'")
    put_parts.append(f", 'cf_metrics:utilization_rate', '{escape_value(row_data['utilization_rate'])}'")
    put_parts.append(f", 'cf_metrics:station_status', '{escape_value(row_data['station_status'])}'")
    put_parts.append(f", 'cf_metrics:wait_time_mins', '{escape_value(row_data['estimated_wait_time_mins'])}'")
    put_parts.append(f", 'cf_metrics:avg_session_mins', '{escape_value(row_data['avg_session_duration_mins'])}'")
    
    # cf_pricing columns
    put_parts.append(f", 'cf_pricing:current_price', '{escape_value(row_data['current_price'])}'")
    put_parts.append(f", 'cf_pricing:pricing_type', '{escape_value(row_data['pricing_type'])}'")
    
    # cf_weather columns
    put_parts.append(f", 'cf_weather:temperature_f', '{escape_value(row_data['temperature_f'])}'")
    put_parts.append(f", 'cf_weather:precipitation_mm', '{escape_value(row_data['precipitation_mm'])}'")
    put_parts.append(f", 'cf_weather:weather_condition', '{escape_value(row_data['weather_condition'])}'")
    
    # cf_context columns
    put_parts.append(f", 'cf_context:gas_price', '{escape_value(row_data['gas_price_per_gallon'])}'")
    put_parts.append(f", 'cf_context:traffic_index', '{escape_value(row_data['traffic_congestion_index'])}'")
    put_parts.append(f", 'cf_context:local_event', '{escape_value(row_data['local_event'])}'")
    
    # cf_temporal columns
    put_parts.append(f", 'cf_temporal:timestamp', '{escape_value(row_data['timestamp'])}'")
    put_parts.append(f", 'cf_temporal:hour', '{escape_value(row_data['hour_of_day'])}'")
    put_parts.append(f", 'cf_temporal:day_of_week', '{escape_value(row_data['day_of_week'])}'")
    put_parts.append(f", 'cf_temporal:month', '{escape_value(row_data['month'])}'")
    put_parts.append(f", 'cf_temporal:is_weekend', '{escape_value(row_data['is_weekend'])}'")
    put_parts.append(f", 'cf_temporal:is_peak_hour', '{escape_value(row_data['is_peak_hour'])}'")
    
    return ''.join(put_parts)

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 generate_hbase_puts.py <csv_file> [limit]")
        print("Example: python3 generate_hbase_puts.py ../ev_charging_station_data.csv 1000")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    limit = int(sys.argv[2]) if len(sys.argv) > 2 else None
    
    print("# HBase PUT commands generated from CSV", file=sys.stderr)
    print(f"# Source: {csv_file}", file=sys.stderr)
    if limit:
        print(f"# Limit: {limit} records", file=sys.stderr)
    print("# Row Key Format: station_id#reverse_timestamp", file=sys.stderr)
    print("", file=sys.stderr)
    
    count = 0
    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                put_cmd = generate_put_command(row)
                print(put_cmd)
                count += 1
                
                if count % 1000 == 0:
                    print(f"# Processed {count} records...", file=sys.stderr)
                
                if limit and count >= limit:
                    break
            except Exception as e:
                print(f"# Error processing row {count}: {e}", file=sys.stderr)
                continue
    
    print(f"# Total records processed: {count}", file=sys.stderr)
    print("# Data import complete", file=sys.stderr)

if __name__ == "__main__":
    main()
