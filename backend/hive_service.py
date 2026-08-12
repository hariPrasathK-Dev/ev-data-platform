"""
Hive Service Module

Handles Hive query execution via beeline or Hive CLI.
Provides Python interface to Hive analytics operations.
"""

import subprocess
import json
import time
from typing import List, Dict, Optional, Any
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

class HiveService:
    """Service class for Hive operations"""
    
    def __init__(self):
        import os
        
        # Set up Hive command with full path
        hive_home = os.getenv('HIVE_HOME', '/usr/local/hive')
        self.hive_command = f"{hive_home}/bin/hive"
        self.beeline_command = f"{hive_home}/bin/beeline -u jdbc:hive2://localhost:10000"
        self.use_beeline = False  # Set to True if HiveServer2 is running
        self.query_history = []
        self.initialized = False
        
        # Check if hive command exists
        if not os.path.exists(self.hive_command):
            logger.warning(f"Hive CLI not found at {self.hive_command}")
            # Try to find in PATH
            import shutil
            hive_in_path = shutil.which('hive')
            if hive_in_path:
                self.hive_command = hive_in_path
                logger.info(f"Using Hive from PATH: {hive_in_path}")
            else:
                logger.error("Hive not found. Please install Hive or set HIVE_HOME environment variable")

        
    def initialize(self):
        """Initialize Hive service"""
        try:
            # Test Hive connection with a simple query
            result = self._execute_query("SHOW DATABASES", test_only=True, timeout=30)
            self.initialized = True
            logger.info("Hive service initialized successfully")
        except Exception as e:
            logger.warning(f"Hive service not available: {e}")
            logger.info("Hive features will be disabled. To enable: initialize Hive metastore")
            self.initialized = False
            
    def cleanup(self):
        """Cleanup on shutdown"""
        logger.info("Hive service cleanup complete")
        
    def check_connection(self) -> bool:
        """Check if Hive is accessible"""
        try:
            self._execute_query("SHOW DATABASES", test_only=True)
            return True
        except:
            return False
            
    def _execute_query(self, query: str, test_only: bool = False, timeout: int = 300) -> Dict[str, Any]:
        """
        Execute Hive query and return results
        
        Args:
            query: SQL query to execute
            test_only: If True, only test connectivity
            timeout: Query timeout in seconds
            
        Returns:
            Query results dictionary with data and metadata
        """
        try:
            start_time = time.time()
            
            # Choose execution method
            if self.use_beeline:
                cmd = f'{self.beeline_command} -e "{query}"'
            else:
                cmd = f'{self.hive_command} -e "{query}"'
                
            logger.debug(f"Executing Hive query: {query[:100]}...")
            
            # Execute query
            result = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            
            execution_time = time.time() - start_time
            
            if result.returncode != 0:
                error_msg = result.stderr.strip()
                logger.error(f"Hive query failed: {error_msg}")
                raise Exception(f"Hive query failed: {error_msg}")
                
            # Parse output
            output = result.stdout.strip()
            
            if test_only:
                return {"success": True}
                
            # Parse tabular results
            data_rows, columns = self._parse_query_output(output)
            
            return {
                "success": True,
                "data": data_rows,
                "columns": columns,
                "row_count": len(data_rows),
                "execution_time": execution_time
            }
            
        except subprocess.TimeoutExpired:
            raise Exception(f"Query timed out after {timeout} seconds")
        except Exception as e:
            logger.error(f"Error executing Hive query: {e}")
            raise
            
    def _parse_query_output(self, output: str) -> tuple[List[Dict[str, Any]], List[str]]:
        """
        Parse Hive query output into structured data
        
        Args:
            output: Raw query output
            
        Returns:
            Tuple of (data_rows, column_names)
        """
        lines = output.split('\n')
        
        # Filter out log/warning lines
        data_lines = []
        for line in lines:
            stripped = line.strip()
            # Skip empty lines, logs, warnings
            if (stripped and 
                not stripped.startswith('Time taken:') and
                not stripped.startswith('OK') and
                not stripped.startswith('SLF4J:') and
                not stripped.startswith('WARNING:') and
                not stripped.startswith('Hive Session ID:') and
                not stripped.startswith('Logging initialized') and
                '---' not in stripped):
                data_lines.append(stripped)
                
        if not data_lines:
            return [], []
            
        # First line is often column headers
        columns = []
        data_rows = []
        
        # Check if first line looks like headers (contains periods or underscores)
        first_line = data_lines[0]
        if '.' in first_line or '_' in first_line or first_line.isupper():
            # Parse as headers
            columns = [col.strip() for col in first_line.split('\t')]
            data_start_idx = 1
        else:
            # No headers, use generic column names
            num_cols = len(first_line.split('\t'))
            columns = [f"col{i}" for i in range(num_cols)]
            data_start_idx = 0
            
        # Parse data rows
        for line in data_lines[data_start_idx:]:
            values = [val.strip() for val in line.split('\t')]
            
            # Create row dictionary
            if len(values) == len(columns):
                row = {columns[i]: values[i] for i in range(len(columns))}
                data_rows.append(row)
            elif len(values) > 0:
                # Handle mismatched columns
                row = {f"col{i}": val for i, val in enumerate(values)}
                data_rows.append(row)
                
        return data_rows, columns
        
    def list_tables(self) -> List[str]:
        """
        List all Hive tables
        
        Returns:
            List of table names
        """
        try:
            result = self._execute_query("SHOW TABLES")
            
            # Extract table names from results
            tables = [row.get("tab_name", row.get("col0", "")) 
                     for row in result.get("data", [])]
            
            return [t for t in tables if t]  # Filter empty strings
            
        except Exception as e:
            logger.error(f"Error listing tables: {e}")
            return []
            
    def get_table_schema(self, table_name: str) -> List[Dict[str, str]]:
        """
        Get schema of Hive table
        
        Args:
            table_name: Name of the table
            
        Returns:
            List of column definitions
        """
        try:
            result = self._execute_query(f"DESCRIBE {table_name}")
            
            schema = []
            for row in result.get("data", []):
                # Column format: col_name, data_type, comment
                col_name = row.get("col_name", row.get("col0", ""))
                data_type = row.get("data_type", row.get("col1", ""))
                comment = row.get("comment", row.get("col2", ""))
                
                if col_name and not col_name.startswith('#'):
                    schema.append({
                        "name": col_name,
                        "type": data_type,
                        "comment": comment
                    })
                    
            return schema
            
        except Exception as e:
            logger.error(f"Error getting table schema for {table_name}: {e}")
            raise
            
    def execute_query(self, query: str, query_name: Optional[str] = None) -> Dict[str, Any]:
        """
        Execute Hive query and return results
        
        Args:
            query: SQL query to execute
            query_name: Optional name for the query
            
        Returns:
            Query results
        """
        try:
            result = self._execute_query(query)
            
            # Add to query history
            history_entry = {
                "query": query,
                "query_name": query_name or f"Query_{len(self.query_history) + 1}",
                "timestamp": datetime.now().isoformat(),
                "execution_time": result.get("execution_time", 0),
                "row_count": result.get("row_count", 0),
                "status": "success"
            }
            self.query_history.append(history_entry)
            
            return result
            
        except Exception as e:
            # Add failed query to history
            history_entry = {
                "query": query,
                "query_name": query_name or f"Query_{len(self.query_history) + 1}",
                "timestamp": datetime.now().isoformat(),
                "status": "failed",
                "error": str(e)
            }
            self.query_history.append(history_entry)
            raise
            
    def get_predefined_queries(self) -> List[Dict[str, str]]:
        """
        Get list of predefined analytical queries
        
        Returns:
            List of query templates
        """
        queries = [
            {
                "id": "q1",
                "name": "Peak Utilization Hours",
                "description": "Find hours with highest average utilization",
                "query": """SELECT 
    hour_of_day,
    AVG(utilization_rate) AS avg_utilization,
    AVG(estimated_wait_time_mins) AS avg_wait_time,
    COUNT(*) AS observations
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY hour_of_day
ORDER BY avg_utilization DESC
LIMIT 10"""
            },
            {
                "id": "q2",
                "name": "Network Performance Comparison",
                "description": "Compare operational uptime across networks",
                "query": """SELECT 
    network,
    COUNT(*) AS total_observations,
    ROUND(SUM(CASE WHEN station_status = 'operational' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS uptime_percentage,
    AVG(utilization_rate) AS avg_utilization
FROM ev_charging_stations
GROUP BY network
ORDER BY uptime_percentage DESC"""
            },
            {
                "id": "q3",
                "name": "High-Demand Stations",
                "description": "Identify stations needing capacity expansion",
                "query": """SELECT 
    station_id,
    station_name,
    city,
    state,
    AVG(utilization_rate) AS avg_utilization,
    AVG(estimated_wait_time_mins) AS avg_wait_time
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY station_id, station_name, city, state
HAVING AVG(utilization_rate) > 0.70
ORDER BY avg_utilization DESC
LIMIT 20"""
            },
            {
                "id": "q4",
                "name": "Weekend vs Weekday Demand",
                "description": "Compare charging patterns between weekends and weekdays",
                "query": """SELECT 
    CASE WHEN is_weekend = TRUE THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    AVG(utilization_rate) AS avg_utilization,
    AVG(estimated_wait_time_mins) AS avg_wait_time,
    COUNT(*) AS total_observations
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY is_weekend
ORDER BY avg_utilization DESC"""
            },
            {
                "id": "q5",
                "name": "Weather Impact Analysis",
                "description": "Analyze how weather affects charging demand",
                "query": """SELECT 
    weather_condition,
    COUNT(*) AS observations,
    AVG(utilization_rate) AS avg_utilization,
    AVG(temperature_f) AS avg_temperature
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY weather_condition
ORDER BY avg_utilization DESC"""
            },
            {
                "id": "q6",
                "name": "State-Level Demand",
                "description": "Geographic analysis of EV charging demand",
                "query": """SELECT 
    state,
    COUNT(DISTINCT station_id) AS num_stations,
    AVG(utilization_rate) AS avg_utilization,
    AVG(estimated_wait_time_mins) AS avg_wait_time
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY state
ORDER BY avg_utilization DESC
LIMIT 15"""
            },
            {
                "id": "q7",
                "name": "Pricing Model Analysis",
                "description": "Compare effectiveness of different pricing models",
                "query": """SELECT 
    pricing_type,
    COUNT(*) AS observations,
    AVG(utilization_rate) AS avg_utilization,
    AVG(current_price) AS avg_price
FROM ev_charging_stations
WHERE station_status = 'operational'
GROUP BY pricing_type
ORDER BY avg_utilization DESC"""
            },
            {
                "id": "q8",
                "name": "System Performance Summary",
                "description": "Overall KPIs for executive dashboard",
                "query": """SELECT 
    COUNT(DISTINCT station_id) AS total_stations,
    COUNT(DISTINCT network) AS total_networks,
    AVG(utilization_rate) AS avg_system_utilization,
    AVG(estimated_wait_time_mins) AS avg_system_wait_time,
    ROUND(SUM(CASE WHEN station_status = 'operational' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS system_uptime_percentage
FROM ev_charging_stations"""
            }
        ]
        
        return queries
        
    def get_query_history(self, limit: int = 20) -> List[Dict[str, Any]]:
        """
        Get query execution history
        
        Args:
            limit: Maximum number of queries to return
            
        Returns:
            List of recent queries
        """
        # Return most recent queries
        return self.query_history[-limit:] if self.query_history else []
