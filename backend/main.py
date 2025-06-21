from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

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

@app.get("/api/promises")
async def get_promises():
    # Placeholder - replace with actual database logic
    return {
        "promises": [
            {
                "id": 1,
                "title": "Complete project",
                "description": "Finish the Promise Keeper app",
                "due_date": "2024-01-15",
                "status": "pending"
            }
        ]
    }

@app.post("/api/promises", response_model=PromiseResponse)
async def create_promise(promise: PromiseCreate):
    # Placeholder - replace with actual database logic
    return PromiseResponse(
        id=1,
        title=promise.title,
        description=promise.description,
        due_date=promise.due_date,
        status="pending"
    )

@app.get("/api/promises/{promise_id}")
async def get_promise(promise_id: int):
    # Placeholder - replace with actual database logic
    return {
        "id": promise_id,
        "title": "Sample Promise",
        "description": "This is a sample promise",
        "due_date": "2024-01-15",
        "status": "pending"
    }

@app.put("/api/promises/{promise_id}")
async def update_promise(promise_id: int, promise: PromiseCreate):
    # Placeholder - replace with actual database logic
    return {
        "id": promise_id,
        "title": promise.title,
        "description": promise.description,
        "due_date": promise.due_date,
        "status": "pending"
    }

@app.delete("/api/promises/{promise_id}")
async def delete_promise(promise_id: int):
    # Placeholder - replace with actual database logic
    return {"message": f"Promise {promise_id} deleted successfully"}

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port) 