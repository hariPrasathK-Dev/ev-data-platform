"""
FastAPI Backend for EV Charging Station Analytics Dashboard

Provides REST API endpoints for:
- HDFS file operations (browse, upload, download)
- MapReduce job submission and monitoring
- Hive query execution and results
- Real-time job status via WebSocket

Author: Big Data Analytics Project Team
Course: 23CSE352
"""

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import logging
import json

# Import service modules
from hdfs_service import HDFSService
from mapreduce_service import MapReduceService
from hive_service import HiveService

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="EV Charging Analytics API",
    description="Backend API for Big Data Analytics Dashboard - Hadoop MapReduce + Hive",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc"
)

# Configure CORS for SvelteKit frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",  # SvelteKit dev server
        "http://localhost:4173",  # SvelteKit preview
        "http://localhost:3000",  # Alternative frontend port
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
hdfs_service = HDFSService()
mapreduce_service = MapReduceService()
hive_service = HiveService()

# ============================================================================
# Pydantic Models for Request/Response
# ============================================================================

class HDFSPath(BaseModel):
    path: str

class MapReduceJobRequest(BaseModel):
    jar_path: str
    main_class: str
    input_path: str
    output_path: str
    args: Optional[List[str]] = []

class HiveQueryRequest(BaseModel):
    query: str
    query_name: Optional[str] = None

class JobStatusResponse(BaseModel):
    job_id: str
    status: str
    progress: float
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    output_path: Optional[str] = None
    error: Optional[str] = None

# ============================================================================
# Health Check & Info
# ============================================================================

@app.get("/")
async def root():
    """Root endpoint - API information"""
    return {
        "name": "EV Charging Analytics API",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "docs": "/api/docs",
            "hdfs": "/api/hdfs",
            "mapreduce": "/api/mapreduce",
            "hive": "/api/hive"
        }
    }

@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    try:
        # Check HDFS connectivity
        hdfs_status = hdfs_service.check_connection()
        
        # Check Hive connectivity
        hive_status = hive_service.check_connection()
        
        return {
            "status": "healthy" if (hdfs_status and hive_status) else "degraded",
            "services": {
                "hdfs": "connected" if hdfs_status else "disconnected",
                "hive": "connected" if hive_status else "disconnected",
                "mapreduce": "available"
            },
            "timestamp": hdfs_service.get_current_time()
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return JSONResponse(
            status_code=503,
            content={"status": "unhealthy", "error": str(e)}
        )

# ============================================================================
# HDFS Endpoints
# ============================================================================

@app.get("/api/hdfs/list")
async def list_hdfs_directory(path: str = "/home/hduser/Hive_Assignment"):
    """
    List contents of HDFS directory
    
    Query Parameters:
    - path: HDFS path to list (default: /home/hduser/Hive_Assignment)
    
    Returns:
    - List of files/directories with metadata
    """
    try:
        logger.info(f"Listing HDFS directory: {path}")
        contents = hdfs_service.list_directory(path)
        return {
            "path": path,
            "contents": contents,
            "count": len(contents)
        }
    except Exception as e:
        logger.error(f"Error listing HDFS directory {path}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/hdfs/info")
async def get_hdfs_file_info(path: str):
    """
    Get detailed information about an HDFS file or directory
    
    Query Parameters:
    - path: HDFS path
    
    Returns:
    - File/directory metadata (size, permissions, modification time, etc.)
    """
    try:
        logger.info(f"Getting HDFS file info: {path}")
        info = hdfs_service.get_file_info(path)
        return info
    except Exception as e:
        logger.error(f"Error getting HDFS file info {path}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/hdfs/read")
async def read_hdfs_file(path: str, lines: int = 100):
    """
    Read contents of HDFS file (preview)
    
    Query Parameters:
    - path: HDFS file path
    - lines: Number of lines to read (default: 100)
    
    Returns:
    - File content as text
    """
    try:
        logger.info(f"Reading HDFS file: {path} (lines: {lines})")
        content = hdfs_service.read_file(path, lines)
        return {
            "path": path,
            "lines_requested": lines,
            "content": content
        }
    except Exception as e:
        logger.error(f"Error reading HDFS file {path}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/hdfs/download")
async def download_hdfs_file(path: str):
    """
    Download file from HDFS
    
    Query Parameters:
    - path: HDFS file path
    
    Returns:
    - File as streaming response
    """
    try:
        logger.info(f"Downloading HDFS file: {path}")
        file_stream = hdfs_service.download_file(path)
        filename = path.split('/')[-1]
        
        return StreamingResponse(
            file_stream,
            media_type="application/octet-stream",
            headers={"Content-Disposition": f"attachment; filename={filename}"}
        )
    except Exception as e:
        logger.error(f"Error downloading HDFS file {path}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/hdfs/upload")
async def upload_to_hdfs(file: UploadFile = File(...), destination: str = "/home/hduser/Hive_Assignment/uploads"):
    """
    Upload file to HDFS
    
    Form Data:
    - file: File to upload
    - destination: HDFS destination directory
    
    Returns:
    - Upload confirmation with path
    """
    try:
        logger.info(f"Uploading file {file.filename} to HDFS: {destination}")
        
        # Read file content
        content = await file.read()
        
        # Upload to HDFS
        result = hdfs_service.upload_file(content, file.filename, destination)
        
        return {
            "success": True,
            "filename": file.filename,
            "destination": result["path"],
            "size": result["size"]
        }
    except Exception as e:
        logger.error(f"Error uploading file to HDFS: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/hdfs/delete")
async def delete_from_hdfs(path: str):
    """
    Delete file or directory from HDFS
    
    Query Parameters:
    - path: HDFS path to delete
    
    Returns:
    - Deletion confirmation
    """
    try:
        logger.info(f"Deleting from HDFS: {path}")
        result = hdfs_service.delete_path(path)
        return {
            "success": True,
            "path": path,
            "deleted": result
        }
    except Exception as e:
        logger.error(f"Error deleting from HDFS {path}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================================================
# MapReduce Endpoints
# ============================================================================

@app.post("/api/mapreduce/submit")
async def submit_mapreduce_job(job_request: MapReduceJobRequest):
    """
    Submit MapReduce job to Hadoop
    
    Request Body:
    - jar_path: Path to JAR file
    - main_class: Main class name
    - input_path: HDFS input path
    - output_path: HDFS output path
    - args: Additional arguments (optional)
    
    Returns:
    - Job ID and initial status
    """
    try:
        logger.info(f"Submitting MapReduce job: {job_request.main_class}")
        
        job_id = mapreduce_service.submit_job(
            jar_path=job_request.jar_path,
            main_class=job_request.main_class,
            input_path=job_request.input_path,
            output_path=job_request.output_path,
            args=job_request.args
        )
        
        return {
            "success": True,
            "job_id": job_id,
            "status": "submitted",
            "message": "MapReduce job submitted successfully"
        }
    except Exception as e:
        logger.error(f"Error submitting MapReduce job: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/mapreduce/status/{job_id}")
async def get_mapreduce_job_status(job_id: str):
    """
    Get status of MapReduce job
    
    Path Parameters:
    - job_id: Hadoop job ID
    
    Returns:
    - Job status, progress, and details
    """
    try:
        logger.info(f"Getting MapReduce job status: {job_id}")
        status = mapreduce_service.get_job_status(job_id)
        return status
    except Exception as e:
        logger.error(f"Error getting MapReduce job status {job_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/mapreduce/jobs")
async def list_mapreduce_jobs(limit: int = 20):
    """
    List recent MapReduce jobs
    
    Query Parameters:
    - limit: Maximum number of jobs to return (default: 20)
    
    Returns:
    - List of recent jobs with status
    """
    try:
        logger.info(f"Listing MapReduce jobs (limit: {limit})")
        jobs = mapreduce_service.list_jobs(limit)
        return {
            "jobs": jobs,
            "count": len(jobs)
        }
    except Exception as e:
        logger.error(f"Error listing MapReduce jobs: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/mapreduce/results/{job_id}")
async def get_mapreduce_results(job_id: str, lines: int = 100):
    """
    Get results from completed MapReduce job
    
    Path Parameters:
    - job_id: Hadoop job ID
    
    Query Parameters:
    - lines: Number of result lines to return (default: 100)
    
    Returns:
    - Job output
    """
    try:
        logger.info(f"Getting MapReduce job results: {job_id}")
        results = mapreduce_service.get_job_results(job_id, lines)
        return {
            "job_id": job_id,
            "results": results
        }
    except Exception as e:
        logger.error(f"Error getting MapReduce job results {job_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/mapreduce/kill/{job_id}")
async def kill_mapreduce_job(job_id: str):
    """
    Kill running MapReduce job
    
    Path Parameters:
    - job_id: Hadoop job ID
    
    Returns:
    - Kill confirmation
    """
    try:
        logger.info(f"Killing MapReduce job: {job_id}")
        result = mapreduce_service.kill_job(job_id)
        return {
            "success": True,
            "job_id": job_id,
            "message": "Job killed successfully" if result else "Failed to kill job"
        }
    except Exception as e:
        logger.error(f"Error killing MapReduce job {job_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================================================
# Hive Endpoints
# ============================================================================

@app.get("/api/hive/tables")
async def list_hive_tables():
    """
    List all Hive tables
    
    Returns:
    - List of table names
    """
    try:
        if not hive_service.initialized:
            return {
                "tables": [],
                "count": 0,
                "warning": "Hive service not initialized. Run 'schematool -dbType derby -initSchema' to enable."
            }
        
        logger.info("Listing Hive tables")
        tables = hive_service.list_tables()
        return {
            "tables": tables,
            "count": len(tables)
        }
    except Exception as e:
        logger.error(f"Error listing Hive tables: {e}")
        return {
            "tables": [],
            "count": 0,
            "error": str(e)
        }

@app.get("/api/hive/table/{table_name}")
async def get_hive_table_schema(table_name: str):
    """
    Get schema of Hive table
    
    Path Parameters:
    - table_name: Name of the table
    
    Returns:
    - Table schema (columns, types, comments)
    """
    try:
        logger.info(f"Getting Hive table schema: {table_name}")
        schema = hive_service.get_table_schema(table_name)
        return {
            "table_name": table_name,
            "schema": schema
        }
    except Exception as e:
        logger.error(f"Error getting Hive table schema {table_name}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/hive/query")
async def execute_hive_query(query_request: HiveQueryRequest):
    """
    Execute Hive query
    
    Request Body:
    - query: SQL query to execute
    - query_name: Optional name for the query
    
    Returns:
    - Query results
    """
    try:
        if not hive_service.initialized:
            raise HTTPException(
                status_code=503, 
                detail="Hive service not initialized. Run 'schematool -dbType derby -initSchema' to enable."
            )
        
        logger.info(f"Executing Hive query: {query_request.query_name or 'unnamed'}")
        
        results = hive_service.execute_query(
            query=query_request.query,
            query_name=query_request.query_name
        )
        
        return {
            "success": True,
            "query_name": query_request.query_name,
            "results": results["data"],
            "columns": results["columns"],
            "row_count": len(results["data"]),
            "execution_time": results.get("execution_time", 0)
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error executing Hive query: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/hive/queries/predefined")
async def get_predefined_queries():
    """
    Get list of predefined analytical queries
    
    Returns:
    - List of query templates
    """
    try:
        logger.info("Getting predefined Hive queries")
        queries = hive_service.get_predefined_queries()
        return {
            "queries": queries,
            "count": len(queries)
        }
    except Exception as e:
        logger.error(f"Error getting predefined queries: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/hive/predefined/{query_id}")
async def execute_predefined_query(query_id: str):
    """
    Execute a predefined query by ID
    
    Path Parameters:
    - query_id: Query ID (e.g., 'q1', 'q2', etc.)
    
    Returns:
    - Query results
    """
    try:
        if not hive_service.initialized:
            raise HTTPException(
                status_code=503, 
                detail="Hive service not initialized. Run 'schematool -dbType derby -initSchema' to enable."
            )
        
        logger.info(f"Executing predefined Hive query: {query_id}")
        
        # Get predefined queries
        predefined_queries = hive_service.get_predefined_queries()
        
        # Find the requested query
        query_template = None
        for q in predefined_queries:
            if q["id"] == query_id:
                query_template = q
                break
        
        if not query_template:
            raise HTTPException(status_code=404, detail=f"Query '{query_id}' not found")
        
        # Execute the query
        results = hive_service.execute_query(
            query=query_template["query"],
            query_name=query_template["name"]
        )
        
        return {
            "success": True,
            "query_id": query_id,
            "query_name": query_template["name"],
            "description": query_template["description"],
            "results": results["data"],
            "columns": results["columns"],
            "row_count": len(results["data"]),
            "execution_time": results.get("execution_time", 0)
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error executing predefined query {query_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/hive/query/history")
async def get_query_history(limit: int = 20):
    """
    Get query execution history
    
    Query Parameters:
    - limit: Maximum number of queries to return (default: 20)
    
    Returns:
    - List of recent queries with execution details
    """
    try:
        logger.info(f"Getting Hive query history (limit: {limit})")
        history = hive_service.get_query_history(limit)
        return {
            "history": history,
            "count": len(history)
        }
    except Exception as e:
        logger.error(f"Error getting query history: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================================================
# WebSocket for Real-time Job Updates
# ============================================================================

@app.websocket("/ws/mapreduce/{job_id}")
async def mapreduce_job_websocket(websocket: WebSocket, job_id: str):
    """
    WebSocket endpoint for real-time MapReduce job status updates
    
    Path Parameters:
    - job_id: Hadoop job ID to monitor
    
    Sends:
    - Periodic job status updates (every 2 seconds)
    """
    await websocket.accept()
    logger.info(f"WebSocket connected for job {job_id}")
    
    try:
        while True:
            # Get current job status
            status = mapreduce_service.get_job_status(job_id)
            
            # Send status update
            await websocket.send_json(status)
            
            # If job is complete or failed, close connection
            if status.get("status") in ["SUCCEEDED", "FAILED", "KILLED"]:
                logger.info(f"Job {job_id} finished, closing WebSocket")
                break
            
            # Wait before next update
            import asyncio
            await asyncio.sleep(2)
            
    except WebSocketDisconnect:
        logger.info(f"WebSocket disconnected for job {job_id}")
    except Exception as e:
        logger.error(f"WebSocket error for job {job_id}: {e}")
        await websocket.close()

# ============================================================================
# Application Startup/Shutdown
# ============================================================================

@app.on_event("startup")
async def startup_event():
    """Initialize services on application startup"""
    logger.info("Starting EV Charging Analytics API...")
    logger.info("Initializing HDFS service...")
    hdfs_service.initialize()
    logger.info("Initializing Hive service...")
    hive_service.initialize()
    logger.info("API ready!")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on application shutdown"""
    logger.info("Shutting down EV Charging Analytics API...")
    hive_service.cleanup()
    logger.info("API shutdown complete")

# ============================================================================
# Run Application
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
