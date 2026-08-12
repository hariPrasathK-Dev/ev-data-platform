"""
MapReduce Service Module

Handles MapReduce job submission, monitoring, and result retrieval.
Interfaces with Hadoop via subprocess and YARN REST API.
"""

import subprocess
import requests
import json
import time
import re
from typing import List, Dict, Optional, Any
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

class MapReduceService:
    """Service class for MapReduce operations"""
    
    def __init__(self):
        import os
        
        # Set up Hadoop environment with full paths
        hadoop_home = os.getenv('HADOOP_HOME', '/usr/local/hadoop')
        os.environ['HADOOP_HOME'] = hadoop_home
        
        # Add Hadoop binaries to PATH
        current_path = os.environ.get('PATH', '')
        os.environ['PATH'] = f"{hadoop_home}/bin:{hadoop_home}/sbin:{current_path}"
        
        # Use full path to hadoop command
        self.hadoop_command = f"{hadoop_home}/bin/hadoop jar"
        self.yarn_api_base = "http://localhost:8088/ws/v1/cluster"
        self.jobs_cache = {}  # Cache job information
        
        logger.info(f"MapReduce service configured: HADOOP_HOME={hadoop_home}")
        
    def submit_job(self, jar_path: str, main_class: str, input_path: str, 
                   output_path: str, args: List[str] = []) -> str:
        """
        Submit MapReduce job to Hadoop
        
        Args:
            jar_path: Path to JAR file
            main_class: Main class name
            input_path: HDFS input path
            output_path: HDFS output path
            args: Additional arguments
            
        Returns:
            Job ID
        """
        try:
            # Construct command
            cmd_parts = [
                self.hadoop_command,
                jar_path,
                main_class,
                input_path,
                output_path
            ] + args
            
            cmd = " ".join(cmd_parts)
            logger.info(f"Submitting MapReduce job: {cmd}")
            
            # Execute command in background
            process = subprocess.Popen(
                cmd,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            # Wait briefly and check for job submission
            time.sleep(2)
            
            # Try to extract job ID from output
            job_id = None
            for line in iter(process.stdout.readline, ''):
                if 'Running job:' in line or 'Submitted application' in line:
                    # Extract job ID (format: job_xxxxxxxxxx_xxxx or application_xxxxxxxxxx_xxxx)
                    match = re.search(r'(job|application)_\d+_\d+', line)
                    if match:
                        job_id = match.group(0)
                        break
                        
            if not job_id:
                # Generate placeholder job ID
                job_id = f"job_{int(time.time())}_{int(time.time() * 1000) % 10000}"
                
            # Store job info in cache
            self.jobs_cache[job_id] = {
                "job_id": job_id,
                "jar_path": jar_path,
                "main_class": main_class,
                "input_path": input_path,
                "output_path": output_path,
                "submit_time": datetime.now().isoformat(),
                "process": process,
                "status": "RUNNING"
            }
            
            logger.info(f"Job submitted with ID: {job_id}")
            return job_id
            
        except Exception as e:
            logger.error(f"Error submitting MapReduce job: {e}")
            raise
            
    def get_job_status(self, job_id: str) -> Dict[str, Any]:
        """
        Get status of MapReduce job
        
        Args:
            job_id: Hadoop job ID
            
        Returns:
            Job status dictionary
        """
        try:
            # Check cache first
            if job_id in self.jobs_cache:
                cached_job = self.jobs_cache[job_id]
                
                # Check if process is still running
                if cached_job.get("process"):
                    poll_result = cached_job["process"].poll()
                    if poll_result is not None:
                        # Process finished
                        if poll_result == 0:
                            cached_job["status"] = "SUCCEEDED"
                        else:
                            cached_job["status"] = "FAILED"
                        cached_job["end_time"] = datetime.now().isoformat()
                        
            # Try to get status from YARN REST API
            try:
                # Convert job_id format if needed (job_xxx to application_xxx)
                app_id = job_id.replace("job_", "application_")
                
                response = requests.get(
                    f"{self.yarn_api_base}/apps/{app_id}",
                    timeout=5
                )
                
                if response.status_code == 200:
                    app_data = response.json().get("app", {})
                    return {
                        "job_id": job_id,
                        "status": app_data.get("state", "UNKNOWN"),
                        "progress": app_data.get("progress", 0.0),
                        "start_time": app_data.get("startedTime"),
                        "end_time": app_data.get("finishedTime"),
                        "elapsed_time": app_data.get("elapsedTime"),
                        "tracking_url": app_data.get("trackingUrl"),
                        "queue": app_data.get("queue", "default"),
                        "user": app_data.get("user", "hduser")
                    }
            except:
                pass  # Fall back to cached data
                
            # Return cached data if YARN API fails
            if job_id in self.jobs_cache:
                cached = self.jobs_cache[job_id]
                return {
                    "job_id": job_id,
                    "status": cached.get("status", "UNKNOWN"),
                    "progress": 0.0 if cached.get("status") == "RUNNING" else 100.0,
                    "start_time": cached.get("submit_time"),
                    "end_time": cached.get("end_time"),
                    "output_path": cached.get("output_path")
                }
                
            # Job not found
            return {
                "job_id": job_id,
                "status": "NOT_FOUND",
                "progress": 0.0,
                "error": "Job not found in cache or YARN"
            }
            
        except Exception as e:
            logger.error(f"Error getting job status for {job_id}: {e}")
            return {
                "job_id": job_id,
                "status": "ERROR",
                "error": str(e)
            }
            
    def list_jobs(self, limit: int = 20) -> List[Dict[str, Any]]:
        """
        List recent MapReduce jobs
        
        Args:
            limit: Maximum number of jobs to return
            
        Returns:
            List of job summaries
        """
        try:
            jobs = []
            
            # Get jobs from YARN REST API
            try:
                response = requests.get(
                    f"{self.yarn_api_base}/apps",
                    params={"limit": limit, "applicationTypes": "MAPREDUCE"},
                    timeout=5
                )
                
                if response.status_code == 200:
                    apps_data = response.json().get("apps", {}).get("app", [])
                    
                    for app in apps_data[:limit]:
                        jobs.append({
                            "job_id": app.get("id"),
                            "name": app.get("name"),
                            "status": app.get("state"),
                            "progress": app.get("progress", 0.0),
                            "start_time": app.get("startedTime"),
                            "end_time": app.get("finishedTime"),
                            "user": app.get("user"),
                            "queue": app.get("queue")
                        })
            except:
                pass  # Fall back to cached jobs
                
            # Add cached jobs if YARN API failed
            if not jobs:
                for job_id, job_data in list(self.jobs_cache.items())[:limit]:
                    jobs.append({
                        "job_id": job_id,
                        "name": job_data.get("main_class"),
                        "status": job_data.get("status"),
                        "start_time": job_data.get("submit_time"),
                        "output_path": job_data.get("output_path")
                    })
                    
            return jobs
            
        except Exception as e:
            logger.error(f"Error listing jobs: {e}")
            return []
            
    def get_job_results(self, job_id: str, lines: int = 100) -> List[str]:
        """
        Get results from completed MapReduce job
        
        Args:
            job_id: Hadoop job ID
            lines: Number of result lines to return
            
        Returns:
            List of result lines
        """
        try:
            # Get output path from cache
            if job_id not in self.jobs_cache:
                raise Exception(f"Job {job_id} not found in cache")
                
            output_path = self.jobs_cache[job_id].get("output_path")
            if not output_path:
                raise Exception("Output path not found for job")
                
            # Read results from HDFS
            result_file = f"{output_path}/part-r-00000"
            
            cmd = f"hdfs dfs -cat {result_file} | head -{lines}"
            result = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode != 0:
                raise Exception(f"Failed to read results: {result.stderr}")
                
            # Split into lines
            lines_list = result.stdout.strip().split('\n')
            return lines_list
            
        except Exception as e:
            logger.error(f"Error getting job results for {job_id}: {e}")
            raise
            
    def kill_job(self, job_id: str) -> bool:
        """
        Kill running MapReduce job
        
        Args:
            job_id: Hadoop job ID
            
        Returns:
            True if killed successfully
        """
        try:
            # Convert to application ID if needed
            app_id = job_id.replace("job_", "application_")
            
            cmd = f"yarn application -kill {app_id}"
            result = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                # Update cache
                if job_id in self.jobs_cache:
                    self.jobs_cache[job_id]["status"] = "KILLED"
                return True
            else:
                logger.error(f"Failed to kill job: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Error killing job {job_id}: {e}")
            return False
