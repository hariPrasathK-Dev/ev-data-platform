"""
HDFS Service Module

Handles all HDFS operations via subprocess calls to hdfs dfs commands.
Provides Python interface to HDFS file system operations.
"""

import subprocess
import json
import re
from datetime import datetime
from typing import List, Dict, Optional, Any
import io
import logging

logger = logging.getLogger(__name__)

class HDFSService:
    """Service class for HDFS operations"""
    
    def __init__(self):
        import os
        
        # Set up Hadoop environment with full paths
        hadoop_home = os.getenv('HADOOP_HOME', '/usr/local/hadoop')
        os.environ['HADOOP_HOME'] = hadoop_home
        
        # Add Hadoop binaries to PATH
        current_path = os.environ.get('PATH', '')
        os.environ['PATH'] = f"{hadoop_home}/bin:{hadoop_home}/sbin:{current_path}"
        
        # Use full path to hdfs command
        self.hdfs_command = f"{hadoop_home}/bin/hdfs dfs"
        self.initialized = False
        
        logger.info(f"HDFS service configured: HADOOP_HOME={hadoop_home}")
        
    def initialize(self):
        """Initialize HDFS service and verify connectivity"""
        try:
            # Test HDFS connection
            result = self._run_command("-ls /")
            self.initialized = True
            logger.info("HDFS service initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize HDFS service: {e}")
            self.initialized = False
            
    def check_connection(self) -> bool:
        """Check if HDFS is accessible"""
        try:
            self._run_command("-ls /", timeout=5)
            return True
        except:
            return False
            
    def _run_command(self, cmd: str, timeout: int = 30) -> str:
        """
        Execute HDFS command and return output
        
        Args:
            cmd: HDFS dfs command (e.g., "-ls /path")
            timeout: Command timeout in seconds
            
        Returns:
            Command output as string
        """
        import os
        
        full_cmd = f"{self.hdfs_command} {cmd}"
        logger.debug(f"Executing: {full_cmd}")
        
        # Ensure environment variables are set
        env = os.environ.copy()
        hadoop_home = env.get('HADOOP_HOME', '/usr/local/hadoop')
        env['HADOOP_HOME'] = hadoop_home
        env['PATH'] = f"{hadoop_home}/bin:{hadoop_home}/sbin:{env.get('PATH', '')}"
        
        try:
            result = subprocess.run(
                full_cmd,
                shell=True,
                capture_output=True,
                text=True,
                timeout=timeout,
                env=env  # Pass environment variables
            )
            
            if result.returncode != 0:
                error_msg = result.stderr.strip()
                logger.error(f"HDFS command failed: {error_msg}")
                raise Exception(f"HDFS command failed: {error_msg}")
                
            return result.stdout.strip()
            
        except subprocess.TimeoutExpired:
            raise Exception(f"HDFS command timed out after {timeout} seconds")
        except Exception as e:
            raise Exception(f"Error executing HDFS command: {str(e)}")
            
    def list_directory(self, path: str) -> List[Dict[str, Any]]:
        """
        List contents of HDFS directory
        
        Args:
            path: HDFS directory path
            
        Returns:
            List of file/directory metadata dictionaries
        """
        try:
            output = self._run_command(f"-ls {path}")
            
            if not output:
                return []
                
            entries = []
            lines = output.split('\n')
            
            for line in lines:
                # Skip "Found X items" line
                if line.startswith('Found'):
                    continue
                    
                # Parse ls output
                # Format: permissions replication owner group size date time path
                parts = line.split()
                if len(parts) >= 8:
                    entry = {
                        "permissions": parts[0],
                        "replication": parts[1],
                        "owner": parts[2],
                        "group": parts[3],
                        "size": int(parts[4]),
                        "size_human": self._format_size(int(parts[4])),
                        "modified_date": parts[5],
                        "modified_time": parts[6],
                        "path": parts[7],
                        "name": parts[7].split('/')[-1],
                        "is_directory": parts[0].startswith('d'),
                        "is_file": not parts[0].startswith('d')
                    }
                    entries.append(entry)
                    
            return entries
            
        except Exception as e:
            logger.error(f"Error listing directory {path}: {e}")
            raise
            
    def get_file_info(self, path: str) -> Dict[str, Any]:
        """
        Get detailed information about HDFS file or directory
        
        Args:
            path: HDFS path
            
        Returns:
            File/directory metadata
        """
        try:
            # Use -stat command for detailed info
            stat_output = self._run_command(f"-stat '%n,%F,%b,%y,%r,%u,%g,%a' {path}")
            
            # Parse stat output
            # Format: name,type,size,modification_time,replication,user,group,permissions
            parts = stat_output.split(',')
            
            if len(parts) >= 8:
                info = {
                    "path": parts[0],
                    "name": parts[0].split('/')[-1],
                    "type": parts[1],
                    "size": int(parts[2]),
                    "size_human": self._format_size(int(parts[2])),
                    "modified": parts[3],
                    "replication": parts[4],
                    "owner": parts[5],
                    "group": parts[6],
                    "permissions": parts[7],
                    "is_directory": parts[1] == "directory",
                    "is_file": parts[1] == "regular file"
                }
                
                # Add line count for text files
                if info["is_file"] and info["size"] < 100 * 1024 * 1024:  # < 100MB
                    try:
                        line_count = self._run_command(f"-cat {path} | wc -l")
                        info["line_count"] = int(line_count)
                    except:
                        info["line_count"] = None
                        
                return info
            else:
                raise Exception("Invalid stat output format")
                
        except Exception as e:
            logger.error(f"Error getting file info for {path}: {e}")
            raise
            
    def read_file(self, path: str, lines: int = 100) -> str:
        """
        Read contents of HDFS file
        
        Args:
            path: HDFS file path
            lines: Number of lines to read
            
        Returns:
            File content as string
        """
        try:
            output = self._run_command(f"-cat {path} | head -{lines}")
            return output
        except Exception as e:
            logger.error(f"Error reading file {path}: {e}")
            raise
            
    def download_file(self, path: str):
        """
        Download file from HDFS as stream
        
        Args:
            path: HDFS file path
            
        Returns:
            BytesIO stream of file content
        """
        try:
            # Read file content
            content = self._run_command(f"-cat {path}")
            
            # Return as BytesIO stream
            return io.BytesIO(content.encode('utf-8'))
            
        except Exception as e:
            logger.error(f"Error downloading file {path}: {e}")
            raise
            
    def upload_file(self, content: bytes, filename: str, destination: str) -> Dict[str, Any]:
        """
        Upload file to HDFS
        
        Args:
            content: File content as bytes
            filename: Name of file
            destination: HDFS destination directory
            
        Returns:
            Upload result with path and size
        """
        try:
            # Create temporary local file
            import tempfile
            with tempfile.NamedTemporaryFile(delete=False, mode='wb') as tmp_file:
                tmp_file.write(content)
                tmp_path = tmp_file.name
                
            # Ensure destination directory exists
            self._run_command(f"-mkdir -p {destination}")
            
            # Upload to HDFS
            hdfs_path = f"{destination}/{filename}"
            self._run_command(f"-put -f {tmp_path} {hdfs_path}")
            
            # Clean up temp file
            import os
            os.remove(tmp_path)
            
            # Get file info
            info = self.get_file_info(hdfs_path)
            
            return {
                "success": True,
                "path": hdfs_path,
                "size": info["size"],
                "size_human": info["size_human"]
            }
            
        except Exception as e:
            logger.error(f"Error uploading file {filename}: {e}")
            raise
            
    def delete_path(self, path: str) -> bool:
        """
        Delete file or directory from HDFS
        
        Args:
            path: HDFS path to delete
            
        Returns:
            True if deleted successfully
        """
        try:
            self._run_command(f"-rm -r {path}")
            return True
        except Exception as e:
            logger.error(f"Error deleting {path}: {e}")
            raise
            
    def _format_size(self, size_bytes: int) -> str:
        """Format byte size to human-readable string"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if size_bytes < 1024.0:
                return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024.0
        return f"{size_bytes:.2f} PB"
        
    def get_current_time(self) -> str:
        """Get current timestamp"""
        return datetime.now().isoformat()
