from fastapi import FastAPI, File, UploadFile, HTTPException, Depends, status, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import base64
import json
import logging
from typing import Optional, Union, Dict, Any
from dotenv import load_dotenv
from baml_client import b
import baml_py
from supabase import Client

# Import our authentication modules
from auth import (
    get_current_user, 
    get_current_user_optional, 
    get_supabase_client, 
    get_supabase_admin_client,
    get_authenticated_client,
    require_admin
)
from supabase_config import supabase_config

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Promise Keeper API",
    description="Backend API for Promise Keeper application",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models
class HealthResponse(BaseModel):
    status: str
    message: str

class PromiseCreate(BaseModel):
    title: str
    description: str
    due_date: str

class PromiseResponse(BaseModel):
    id: int
    title: str
    description: str
    due_date: str
    status: str

class BasicPromiseResponse(BaseModel):
    promise: str

class ImageBase64Request(BaseModel):
    image_data: str  # base64 encoded image

class PromiseListResponse(BaseModel):
    promises: list

# Authentication models
class UserResponse(BaseModel):
    id: str
    email: str
    created_at: str

class AuthTestResponse(BaseModel):
    message: str
    user_id: str
    email: str

class PromiseCreateAuth(BaseModel):
    title: str
    description: str
    due_date: str
    user_id: Optional[str] = None

# Routes
@app.get("/")
async def root():
    return {"message": "Promise Keeper API is running!"}

@app.get("/health", response_model=HealthResponse)
async def health_check():
    return HealthResponse(
        status="healthy",
        message="API is running successfully"
    )

@app.post('/extract_promises_file', response_model=PromiseListResponse)
async def extract_promises_from_file(file: UploadFile = File(...)):
    """Extract promises from an uploaded image file"""
    try:
        # Read the uploaded file
        image_bytes = await file.read()
        
        # Convert bytes to base64 and create baml_py.Image
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')
        
        # Get media type from file content type, default to image/png
        media_type = file.content_type or "image/png"
        baml_image = baml_py.Image.from_base64(media_type, image_base64)
        
        # Extract promises using BAML
        promises = b.ExtractPromises(baml_image)
        
        # Log reasoning information
        if promises.reason_for_no_promises:
            logger.info(f"Reason for no promises: {promises.reason_for_no_promises}")
        
        for i, promise in enumerate(promises.promises):
            if promise.reasoning:
                logger.info(f"Promise {i+1} reasoning: {promise.reasoning}")
        
        return PromiseListResponse(promises=[
            {"content": p.content, "to_whom": p.to_whom, "deadline": p.deadline} 
            for p in promises.promises
        ])
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")

@app.post('/extract_promises_base64', response_model=PromiseListResponse)
async def extract_promises_from_base64(request: ImageBase64Request):
    """Extract promises from a base64 encoded image"""
    try:
        # Get base64 image data
        image_data = request.image_data
        
        # Extract media type and base64 data from data URL if present
        media_type = "image/png"  # default
        if image_data.startswith('data:'):
            parts = image_data.split(',')
            if len(parts) == 2:
                header = parts[0]
                image_data = parts[1]
                # Extract media type from data URL (e.g., "data:image/jpeg;base64")
                if ':' in header and ';' in header:
                    media_type = header.split(':')[1].split(';')[0]
        
        # Create baml_py.Image from base64
        baml_image = baml_py.Image.from_base64(media_type, image_data)
        
        # Extract promises using BAML
        promises = b.ExtractPromises(baml_image)
        
        # Log reasoning information
        if promises.reason_for_no_promises:
            logger.info(f"Reason for no promises: {promises.reason_for_no_promises}")
        
        for i, promise in enumerate(promises.promises):
            if promise.reasoning:
                logger.info(f"Promise {i+1} reasoning: {promise.reasoning}")
        
        return PromiseListResponse(promises=[
            {"content": p.content, "to_whom": p.to_whom, "deadline": p.deadline} 
            for p in promises.promises
        ])
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")

# Legacy endpoint for backward compatibility (with basic response)
@app.post('/map_request_to_promise', response_model=BasicPromiseResponse)
async def map_request_to_promise(file: UploadFile = File(...)):
    """Legacy endpoint - extract first promise from uploaded image"""
    try:
        # Read the uploaded file
        image_bytes = await file.read()
        
        # Convert bytes to base64 and create baml_py.Image
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')
        
        # Get media type from file content type, default to image/png
        media_type = file.content_type or "image/png"
        baml_image = baml_py.Image.from_base64(media_type, image_base64)
        
        # Extract promises using BAML
        promises = b.ExtractPromises(baml_image)
        
        # Log reasoning information
        if promises.reason_for_no_promises:
            logger.info(f"Legacy endpoint - Reason for no promises: {promises.reason_for_no_promises}")
        
        if promises.promises:
            if promises.promises[0].reasoning:
                logger.info(f"Legacy endpoint - Promise reasoning: {promises.promises[0].reasoning}")
            return BasicPromiseResponse(promise=promises.promises[0].content)
        else:
            return BasicPromiseResponse(promise="No promises found in the image")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")

# Authentication and protected routes
@app.get("/auth/me", response_model=UserResponse)
async def get_current_user_info(current_user: Dict[str, Any] = Depends(get_current_user)):
    """Get current authenticated user information"""
    return UserResponse(
        id=current_user.get("user_id", current_user.get("sub", "")),
        email=current_user.get("email", ""),
        created_at=current_user.get("created_at", "")
    )

@app.get("/auth/test", response_model=AuthTestResponse)
async def test_auth(current_user: Dict[str, Any] = Depends(get_current_user)):
    """Test route to verify authentication works"""
    return AuthTestResponse(
        message="Authentication successful!",
        user_id=current_user.get("user_id", current_user.get("sub", "")),
        email=current_user.get("email", "")
    )

# Enhanced promise extraction with user association
@app.post('/extract_promises_file_auth', response_model=PromiseListResponse)
async def extract_promises_from_file_authenticated(
    file: UploadFile = File(...),
    screenshot_id: Optional[str] = Form(None),
    screenshot_timestamp: Optional[str] = Form(None),
    current_user: Dict[str, Any] = Depends(get_current_user),
    admin_client: Client = Depends(get_supabase_admin_client)
):
    """Extract promises from an uploaded image file and optionally save to database"""
    try:
        # Read the uploaded file
        image_bytes = await file.read()
        
        # Convert bytes to base64 and create baml_py.Image
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')
        
        # Get media type from file content type, default to image/png
        media_type = file.content_type or "image/png"
        baml_image = baml_py.Image.from_base64(media_type, image_base64)
        
        # Extract promises using BAML
        from baml_client.types import PromiseListResponse as BAMLPromiseListResponse, NoPromisesFoundResponse
        
        rawPromiseOutput = b.ExtractPromises(baml_image)
        
        user_id = current_user.get("user_id", current_user.get("sub", ""))
        
        # Handle both response types
        if isinstance(rawPromiseOutput, NoPromisesFoundResponse):
            logger.info(f"Auth endpoint - User {user_id} - No promises found. Reason: {rawPromiseOutput.reason}")
            return PromiseListResponse(promises=[])
        
        # Handle PromiseListResponse
        if isinstance(rawPromiseOutput, BAMLPromiseListResponse):
            logger.info(f"Auth endpoint - User {user_id} - Found {len(rawPromiseOutput.promises)} promises")
            
            # Log reasoning information for each promise
            for i, promise in enumerate(rawPromiseOutput.promises):
                if promise.reasoning:
                    logger.info(f"Auth endpoint - User {user_id} - Promise {i+1} reasoning: {promise.reasoning}")
        
        promises = rawPromiseOutput
        
        # If we found promises, check against existing ones in the database
        new_promises_to_save = []
        if promises.promises:
            try:
                # Fetch all existing promises for this user
                existing_promises_response = admin_client.table("promises").select("*").eq("owner_id", user_id).execute()
                existing_promises_raw = existing_promises_response.data or []

                print('existing_promises_raw', existing_promises_raw)
                
                # Convert existing promises to BAML Promise format
                from baml_client.types import Promise as BAMLPromise
                existing_promises_baml = []
                for existing in existing_promises_raw:
                    # Parse extraction_data to get original promise details
                    extraction_data = json.loads(existing.get("extraction_data", "{}"))
                    existing_promises_baml.append(BAMLPromise(
                        content=existing["content"],
                        reasoning=None,  # Don't need reasoning for existing promises
                        to_whom=extraction_data.get("to_whom"),
                        deadline=extraction_data.get("deadline")
                    ))
                
                # Use BAML to filter out duplicates
                logger.info(f"Auth endpoint - User {user_id} - Checking {len(promises.promises)} new promises against {len(existing_promises_baml)} existing promises")
                filtered_promises: list[BAMLPromise] | None = b.CheckExistingPromises(promises.promises, existing_promises_baml)
                if filtered_promises is None:
                    filtered_promises = []
                new_promises_to_save = filtered_promises
                
                logger.info(f"Auth endpoint - User {user_id} - After filtering: {len(new_promises_to_save)} new promises to save")
                
            except Exception as filter_error:
                logger.error(f"Error filtering promises: {filter_error}")
                # Fall back to saving all promises if filtering fails
                new_promises_to_save = promises.promises
        
        # Save only the new promises to database
        saved_promises = []
        
        for promise in new_promises_to_save:
            try:
                promise_data = {
                    "content": promise.content,
                    "owner_id": user_id,
                    "extracted_from_screenshot": True,
                    "screenshot_id": screenshot_id,
                    "screenshot_timestamp": screenshot_timestamp,
                    "extraction_data": json.dumps({
                        "to_whom": promise.to_whom,
                        "deadline": promise.deadline,
                        "raw_promise": promise.content
                    })
                }
                
                response = admin_client.table("promises").insert(promise_data).execute()
                if response.data:
                    saved_promises.append(response.data[0])
            except Exception as save_error:
                # Continue even if individual promise save fails
                print(f"Failed to save promise: {save_error}")
        
        return PromiseListResponse(promises=[
            {"content": p.content, "to_whom": p.to_whom, "deadline": p.deadline} 
            for p in new_promises_to_save
        ])
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port) 