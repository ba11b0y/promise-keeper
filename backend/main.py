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
    resolved_promises: Optional[list] = []
    resolved_count: Optional[int] = 0

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
            {
                "content": p.content,
                "to_whom": p.to_whom,
                "deadline": p.deadline,
                "action": getattr(p, 'action', '') or ''
            }
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

        final_promises = []
        
        for i, promise in enumerate(promises.promises):
            if promise.reasoning:
                logger.info(f"Promise {i+1} content: {promise.content}")
                logger.info(f"Promise {i+1} how sure you are that this is a real promise: {promise.how_sure}")
                logger.info(f"Promise {i+1} reasoning: {promise.reasoning}")
                if promise.how_sure == baml_py.HowSureYouAreThisIsARealPromise.COMPLETLEY_SURE_A_PROMISE or promise.how_sure == baml_py.HowSureYouAreThisIsARealPromise.PROBABLY_A_PROMISE:
                    final_promises.append(promise)
        
        return PromiseListResponse(promises=[
            {
                "content": p.content,
                "to_whom": p.to_whom,
                "deadline": p.deadline,
                "action": getattr(p, 'action', '') or ''
            }
            for p in final_promises
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

        print('rawPromiseOutput', rawPromiseOutput.model_dump_json())
        
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

        final_promises = []
        
        for i, promise in enumerate(promises.promises):
            if promise.reasoning:
                logger.info(f"Promise {i+1} content: {promise.content}")
                logger.info(f"Promise {i+1} how sure you are that this is a real promise: {promise.how_sure}")
                logger.info(f"Promise {i+1} reasoning: {promise.reasoning}")
                if promise.how_sure:
                    final_promises.append(promise)

        promises.promises = final_promises
        
        # Initialize existing_promises_baml outside the if block
        existing_promises_baml = []
        
        # Always fetch existing promises for this user (for both new promise checking and resolved promise checking)
        try:
            existing_promises_response = admin_client.table("promises").select("*").eq("owner_id", user_id).execute()
            existing_promises_raw = existing_promises_response.data or []

            print('existing_promises_raw', existing_promises_raw)
            
            # Convert existing promises to BAML Promise format
            from baml_client.types import Promise as BAMLPromise
            for existing in existing_promises_raw:
                # Parse extraction_data to get original promise details
                extraction_data = json.loads(existing.get("extraction_data", "{}"))
                
                # Parse action column (JSON string/object) into BAML Action
                action_raw = existing.get("action")
                baml_action_obj = None
                if action_raw:
                    try:
                        if isinstance(action_raw, str):
                            action_dict = json.loads(action_raw)
                        else:
                            action_dict = action_raw
                        from baml_client.types import Action as BAMLAction
                        baml_action_obj = BAMLAction(**action_dict)
                    except Exception:
                        baml_action_obj = None
                
                existing_promises_baml.append(BAMLPromise(
                    content=existing["content"],
                    reasoning=None,  # Don't need reasoning for existing promises
                    to_whom=extraction_data.get("to_whom"),
                    deadline=extraction_data.get("deadline"),
                    action=baml_action_obj,
                    how_sure=True
                ))
        except Exception as db_error:
            logger.error(f"Error fetching existing promises: {db_error}")
            # Continue with empty list if database fetch fails
            existing_promises_baml = []
        
        # If we found promises, check against existing ones in the database
        new_promises_to_save = []
        if promises.promises:
            try:
                # Use BAML to evaluate each promise individually
                logger.info(f"Auth endpoint - User {user_id} - Checking {len(promises.promises)} new promises against {len(existing_promises_baml)} existing promises")
                
                from baml_client.types import ShouldSaveNewPromiseEnum
                
                new_promises_to_save = []
                possibly_save_promises = []
                definitely_not_save_promises = []
                
                for promise in promises.promises:
                    try:
                        should_save_result = b.ShouldSaveNewPromise(existing_promises_baml, promise)
                        
                        if should_save_result == ShouldSaveNewPromiseEnum.DEFINITELY_SAVE:
                            new_promises_to_save.append(promise)
                            logger.info(f"Auth endpoint - User {user_id} - DEFINITELY_SAVE: {promise.content}")
                        elif should_save_result == ShouldSaveNewPromiseEnum.POSSIBLY_SAVE:
                            possibly_save_promises.append(promise)
                            logger.info(f"Auth endpoint - User {user_id} - POSSIBLY_SAVE: {promise.content}")
                        else:  # DEFINITELY_NOT_SAVE
                            definitely_not_save_promises.append(promise)
                            logger.info(f"Auth endpoint - User {user_id} - DEFINITELY_NOT_SAVE: {promise.content}")
                            
                    except Exception as eval_error:
                        logger.error(f"Auth endpoint - User {user_id} - Error evaluating promise '{promise.content}': {eval_error}")
                        # On error, don't save to be safe
                        continue
                
                logger.info(f"Auth endpoint - User {user_id} - Results: {len(new_promises_to_save)} to save, {len(possibly_save_promises)} possibly save, {len(definitely_not_save_promises)} not save")
                
                # Add POSSIBLY_SAVE promises to the save list (they represent updates/clarifications)
                new_promises_to_save.extend(possibly_save_promises)
                logger.info(f"Auth endpoint - User {user_id} - Total promises to save after including possibly_save: {len(new_promises_to_save)}")
                
            except Exception as filter_error:
                logger.error(f"Error filtering promises: {filter_error}")
                # Fall back to saving all promises if filtering fails
                new_promises_to_save = promises.promises
        
        # Save only the new promises to database
        saved_promises = []
        
        for promise in new_promises_to_save:
            try:
                # Debug: Let's see what we're working with
                print(f"Promise object: {promise}")
                print(f"Promise action: {promise.action}")
                print(f"Promise reasoning: {promise.reasoning}")

                promise_data = {
                    "content": promise.content,
                    "owner_id": user_id,
                    "extracted_from_screenshot": True,
                    "screenshot_id": screenshot_id,
                    "screenshot_timestamp": screenshot_timestamp,
                    "extraction_data": json.dumps({
                        "to_whom": promise.to_whom,
                        "deadline": promise.deadline,
                        "platform": promise.platform,
                        "raw_promise": promise.content
                    }),
                    "action": json.dumps(promise.action.model_dump()) if getattr(promise, 'action', None) else None,
                    # Store as separate columns for easier querying
                    "person": promise.to_whom if promise.to_whom else "myself",
                    "due_date": promise.deadline,  # This will be stored as text, frontend can parse
                    "platform": promise.platform
                }
                
                print(f"Final promise_data being sent to Supabase: {json.dumps(promise_data, indent=2)}")
                
                response = admin_client.table("promises").insert(promise_data).execute()
                if response.data:
                    saved_promises.append(response.data[0])
            except Exception as save_error:
                # Continue even if individual promise save fails
                print(f"Failed to save promise: {save_error}")
        
        # Check for resolved promises using the same image
        resolved_promises_count = 0
        if existing_promises_baml:
            try:
                from baml_client.types import ResolvedPromisesResponse, NoPromisesResolvedResponse
                
                logger.info(f"Auth endpoint - User {user_id} - Checking for resolved promises against {len(existing_promises_baml)} existing promises")
                
                resolved_check_result = b.CheckResolvedPromises(baml_image, existing_promises_baml)
                
                if isinstance(resolved_check_result, ResolvedPromisesResponse):
                    logger.info(f"Auth endpoint - User {user_id} - Found {len(resolved_check_result.resolved_promises)} resolved promises")
                    
                    # Update each resolved promise in the database - trust the LLM completely
                    for resolved_promise in resolved_check_result.resolved_promises:
                        try:
                            logger.info(f"Auth endpoint - User {user_id} - LLM says this promise is resolved: '{resolved_promise.original_promise.content}'")
                            
                            # Simply find the promise by content - trust the LLM's decision completely
                            # First, get the existing promise to preserve metadata
                            existing_promise_response = admin_client.table("promises").select("metadata").eq("owner_id", user_id).eq("content", resolved_promise.original_promise.content).eq("resolved", False).execute()
                            
                            existing_metadata = {}
                            if existing_promise_response.data and existing_promise_response.data[0].get("metadata"):
                                try:
                                    existing_metadata = json.loads(existing_promise_response.data[0]["metadata"])
                                except json.JSONDecodeError:
                                    existing_metadata = {}
                            
                            # Merge resolution info with existing metadata
                            updated_metadata = {**existing_metadata}
                            updated_metadata["resolution_evidence"] = resolved_promise.resolution_evidence
                            updated_metadata["resolution_reasoning"] = resolved_promise.resolution_reasoning
                            
                            update_response = admin_client.table("promises").update({
                                "resolved": True,
                                "resolved_screenshot_id": screenshot_id,
                                "resolved_screenshot_time": screenshot_timestamp,
                                "resolved_reason": resolved_promise.resolution_reasoning,
                                "updated_at": "now()",
                                "metadata": json.dumps(updated_metadata) if updated_metadata else None
                            }).eq("owner_id", user_id).eq("content", resolved_promise.original_promise.content).eq("resolved", False).execute()
                            
                            if update_response.data:
                                resolved_promises_count += len(update_response.data)
                                logger.info(f"Auth endpoint - User {user_id} - ✅ Marked promise as resolved: {resolved_promise.original_promise.content}")
                                logger.info(f"Auth endpoint - User {user_id} - Resolution reason: {resolved_promise.resolution_reasoning}")
                            else:
                                logger.warning(f"Auth endpoint - User {user_id} - No matching unresolved promise found for: {resolved_promise.original_promise.content}")
                                
                        except Exception as resolve_error:
                            logger.error(f"Auth endpoint - User {user_id} - Error updating resolved promise: {resolve_error}")
                            continue
                
                elif isinstance(resolved_check_result, NoPromisesResolvedResponse):
                    logger.info(f"Auth endpoint - User {user_id} - No promises resolved. Reason: {resolved_check_result.reason}")
                    
            except Exception as resolve_check_error:
                logger.error(f"Auth endpoint - User {user_id} - Error checking for resolved promises: {resolve_check_error}")
        
        logger.info(f"Auth endpoint - User {user_id} - Summary: {len(new_promises_to_save)} new promises saved, {resolved_promises_count} promises marked as resolved")
        
        # Prepare resolved promises info for response
        resolved_promises_info = []
        if existing_promises_baml and resolved_promises_count > 0:
            try:
                if isinstance(resolved_check_result, ResolvedPromisesResponse):
                    for resolved_promise in resolved_check_result.resolved_promises:
                        resolved_promises_info.append({
                            "content": resolved_promise.original_promise.content,
                            "to_whom": resolved_promise.original_promise.to_whom,
                            "deadline": resolved_promise.original_promise.deadline,
                            "resolution_reasoning": resolved_promise.resolution_reasoning,
                            "resolution_evidence": resolved_promise.resolution_evidence
                        })
            except Exception as resolved_info_error:
                logger.error(f"Error preparing resolved promises info: {resolved_info_error}")
        
        # Format promises for notifications
        formatted_promises = []
        for p in new_promises_to_save:
            try:
                # Format the promise for notification using BAML
                formatted = b.FormatPromiseForNotification(p)
                formatted_promises.append({
                    "content": p.content,
                    "to_whom": p.to_whom,
                    "deadline": p.deadline,
                    "platform": p.platform,
                    "person": p.to_whom if p.to_whom else "myself",
                    "due_date": p.deadline,
                    "action": p.action.model_dump() if getattr(p, 'action', None) else None,
                    "formatted": {
                        "title": formatted.title,
                        "body": formatted.body,
                        "details": formatted.details
                    }
                })
            except Exception as format_error:
                # Fallback if formatting fails
                formatted_promises.append({
                    "content": p.content,
                    "to_whom": p.to_whom,
                    "deadline": p.deadline,
                    "platform": p.platform,
                    "person": p.to_whom if p.to_whom else "myself",
                    "due_date": p.deadline,
                    "action": p.action.model_dump() if getattr(p, 'action', None) else None,
                    "formatted": {
                        "title": p.content[:50],
                        "body": p.content[:150],
                        "details": f"To: {p.to_whom or 'myself'} • Due: {p.deadline or 'No deadline'} • Via: {p.platform or 'Unknown'}"
                    }
                })
        
        return PromiseListResponse(
            promises=formatted_promises,
            resolved_promises=resolved_promises_info,
            resolved_count=resolved_promises_count
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port) 