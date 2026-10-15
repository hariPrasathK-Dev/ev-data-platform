"""
CSV Data Analyzer for EV Charging Station Dataset
Provides efficient statistical analysis without loading entire CSV into memory
"""

import csv
import os
from collections import defaultdict
from typing import Dict, List, Any
import logging

logger = logging.getLogger(__name__)

class EVDatasetAnalyzer:
    """Analyzes EV charging dataset efficiently"""
    
    def __init__(self, csv_path: str):
        self.csv_path = csv_path
        self.total_records = 0
        self.unique_stations = set()
        self.unique_networks = set()
        self.unique_cities = set()
        self.unique_states = set()
        self.status_counts = defaultdict(int)
        self.network_stats = defaultdict(lambda: {'count': 0, 'utilization_sum': 0})
        self.hourly_stats = defaultdict(lambda: {'count': 0, 'utilization_sum': 0})
        self.weather_stats = defaultdict(lambda: {'count': 0, 'utilization_sum': 0})
        
    def analyze(self, max_rows: int = None) -> Dict[str, Any]:
        """
        Analyze CSV file efficiently
        
        Args:
            max_rows: Maximum number of rows to analyze (None = all)
            
        Returns:
            Dictionary with statistics
        """
        logger.info(f"Analyzing CSV: {self.csv_path}")
        
        if not os.path.exists(self.csv_path):
            raise FileNotFoundError(f"CSV file not found: {self.csv_path}")
        
        try:
            with open(self.csv_path, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                
                for i, row in enumerate(reader):
                    if max_rows and i >= max_rows:
                        break
                    
                    self._process_row(row)
                    self.total_records = i + 1
                    
                    if self.total_records % 100000 == 0:
                        logger.info(f"Processed {self.total_records:,} records...")
            
            logger.info(f"Analysis complete: {self.total_records:,} records processed")
            return self._generate_summary()
            
        except Exception as e:
            logger.error(f"Error analyzing CSV: {e}")
            raise
    
    def _process_row(self, row: Dict[str, str]):
        """Process a single CSV row"""
        try:
            # Basic counts
            self.unique_stations.add(row['station_id'])
            self.unique_networks.add(row['network'])
            self.unique_cities.add(row['city'])
            self.unique_states.add(row['state'])
            
            # Status distribution
            status = row['station_status']
            self.status_counts[status] += 1
            
            # Network stats
            network = row['network']
            utilization = float(row['utilization_rate']) if row['utilization_rate'] else 0
            self.network_stats[network]['count'] += 1
            self.network_stats[network]['utilization_sum'] += utilization
            
            # Hourly stats
            hour = row['hour_of_day']
            self.hourly_stats[hour]['count'] += 1
            self.hourly_stats[hour]['utilization_sum'] += utilization
            
            # Weather stats
            weather = row['weather_condition']
            self.weather_stats[weather]['count'] += 1
            self.weather_stats[weather]['utilization_sum'] += utilization
            
        except (KeyError, ValueError) as e:
            logger.warning(f"Error processing row: {e}")
    
    def _generate_summary(self) -> Dict[str, Any]:
        """Generate summary statistics"""
        
        # Calculate averages
        network_summary = []
        for network, stats in self.network_stats.items():
            avg_util = stats['utilization_sum'] / stats['count'] if stats['count'] > 0 else 0
            network_summary.append({
                'network': network,
                'observations': stats['count'],
                'avg_utilization': round(avg_util, 3)
            })
        network_summary.sort(key=lambda x: x['observations'], reverse=True)
        
        hourly_summary = []
        for hour, stats in self.hourly_stats.items():
            avg_util = stats['utilization_sum'] / stats['count'] if stats['count'] > 0 else 0
            hourly_summary.append({
                'hour': int(hour),
                'observations': stats['count'],
                'avg_utilization': round(avg_util, 3)
            })
        hourly_summary.sort(key=lambda x: x['hour'])
        
        weather_summary = []
        for weather, stats in self.weather_stats.items():
            avg_util = stats['utilization_sum'] / stats['count'] if stats['count'] > 0 else 0
            weather_summary.append({
                'weather': weather,
                'observations': stats['count'],
                'avg_utilization': round(avg_util, 3)
            })
        weather_summary.sort(key=lambda x: x['observations'], reverse=True)
        
        # Calculate overall utilization
        total_util_sum = sum(stats['utilization_sum'] for stats in self.network_stats.values())
        avg_utilization = total_util_sum / self.total_records if self.total_records > 0 else 0
        
        return {
            'dataset': {
                'total_records': self.total_records,
                'total_stations': len(self.unique_stations),
                'total_networks': len(self.unique_networks),
                'total_cities': len(self.unique_cities),
                'total_states': len(self.unique_states),
                'avg_utilization': round(avg_utilization, 3)
            },
            'status_distribution': dict(self.status_counts),
            'top_networks': network_summary[:10],
            'hourly_patterns': hourly_summary,
            'weather_impact': weather_summary[:10],
            'networks': sorted(list(self.unique_networks)),
            'cities': sorted(list(self.unique_cities))[:50],  # Limit for API response size
            'states': sorted(list(self.unique_states))
        }
    
    def get_sample_stations(self, limit: int = 100) -> List[Dict[str, Any]]:
        """Get sample station records"""
        stations = []
        
        try:
            with open(self.csv_path, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                
                station_ids_seen = set()
                for row in reader:
                    station_id = row['station_id']
                    
                    # Get first observation of each unique station
                    if station_id not in station_ids_seen:
                        station_ids_seen.add(station_id)
                        
                        stations.append({
                            'station_id': station_id,
                            'station_name': row['station_name'],
                            'network': row['network'],
                            'city': row['city'],
                            'state': row['state'],
                            'latitude': float(row['latitude']) if row['latitude'] else None,
                            'longitude': float(row['longitude']) if row['longitude'] else None,
                            'charger_type': row['charger_type'],
                            'ports_total': int(row['ports_total']) if row['ports_total'] else 0,
                            'station_status': row['station_status'],
                            'last_observation': row['timestamp']
                        })
                        
                        if len(stations) >= limit:
                            break
            
            return stations
            
        except Exception as e:
            logger.error(f"Error getting sample stations: {e}")
            return []


# Singleton instance for caching
_analyzer_cache = {}

def get_analyzer(csv_path: str, force_refresh: bool = False) -> EVDatasetAnalyzer:
    """Get or create analyzer instance with caching"""
    if force_refresh or csv_path not in _analyzer_cache:
        analyzer = EVDatasetAnalyzer(csv_path)
        _analyzer_cache[csv_path] = analyzer
    return _analyzer_cache[csv_path]
