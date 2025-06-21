# Promise Keeper API

A FastAPI backend for the Promise Keeper application.

## Setup

1. Create a virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Copy environment file:
```bash
cp .env.example .env
```

4. Run the development server:
```bash
uvicorn main:app --reload
```

The API will be available at `http://localhost:8000`

## API Documentation

Once running, you can access:
- Interactive API docs: `http://localhost:8000/docs`
- Alternative docs: `http://localhost:8000/redoc`

## Available Endpoints

- `GET /` - Root endpoint
- `GET /health` - Health check
- `GET /api/promises` - Get all promises
- `POST /api/promises` - Create a new promise
- `GET /api/promises/{id}` - Get a specific promise
- `PUT /api/promises/{id}` - Update a promise
- `DELETE /api/promises/{id}` - Delete a promise

## Deployment to Fly.io

1. Install Fly CLI:
```bash
curl -L https://fly.io/install.sh | sh
```

2. Login to Fly:
```bash
fly auth login
```

3. Create and deploy the app:
```bash
fly launch
```

4. For subsequent deployments:
```bash
fly deploy
```

## Environment Variables

Set environment variables in Fly.io:
```bash
fly secrets set DATABASE_URL=your_database_url
fly secrets set DEBUG=False
```

## Notes

- The app is configured to run on port 8000
- CORS is currently set to allow all origins (configure for production)
- Database integration is not implemented yet (placeholder endpoints) 