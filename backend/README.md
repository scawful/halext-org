# Halext Org Backend

This directory contains the backend server for the Halext Org project, built with FastAPI and PostgreSQL.

## Setup and Installation

### Prerequisites

- Python 3.8+
- PostgreSQL

### Installation

1.  **Create a virtual environment:**

    ```bash
    python3 -m venv env
    source env/bin/activate
    ```

2.  **Install dependencies:**

    ```bash
    pip install -r requirements.txt
    ```

3.  **Configure your database:**

    Make sure you have a PostgreSQL server running and create a new database for this project. You will need to set the database connection URL as an environment variable.

    ```bash
    export DATABASE_URL="postgresql://user:password@host:port/dbname"
    ```

## Running the Server

To run the development server, use `uvicorn`:

```bash
uvicorn main:app --reload
```

The API will be available at `http://127.0.0.1:8000`.
