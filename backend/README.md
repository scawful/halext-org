# Halext Org Backend

FastAPI-based backend for the Halext Org productivity suite.

## Quick Start

### Development Setup

1. **Create Virtual Environment**
   ```bash
   python3 -m venv env
   source env/bin/activate  # On Windows: env\Scripts\activate
   ```

2. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

4. **Create Development User**
   ```bash
   python create_dev_user.py
   ```
   Default credentials:
   - Username: `dev`
   - Password: `dev123`

5. **Run Server**
   ```bash
   uvicorn main:app --host 127.0.0.1 --port 8000 --reload
   ```

### Or Use Root Dev Script

From the project root:
```bash
./dev-reload.sh  # Starts both frontend and backend
```

## API Documentation

Once running, visit:
- **Swagger UI**: http://127.0.0.1:8000/docs
- **ReDoc**: http://127.0.0.1:8000/redoc

## Development User

A default development user has been created:
- **Username**: `dev`
- **Password**: `dev123`
- **Email**: `dev@halext.org`

You can create additional users:
```bash
python create_dev_user.py --username alice --password secret --email alice@example.com
```
