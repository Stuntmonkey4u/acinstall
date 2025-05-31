# HomeDash - Self-Hosted Start Page

HomeDash is a responsive, visually polished Start Page dashboard designed for home network environments. It provides quick access to your local services, monitors their status, and includes secure editing capabilities.

## Features

- **Service Listing:** Displays configured local services with names, links, and categories.
- **Status Monitoring:** Shows real-time up/down status for each service (via HTTP checks).
- **Responsive Design:** Mobile-friendly layout for access on any device.
- **Secure Login:** Public viewing is allowed, but editing services and accessing admin functions requires login.
- **Admin Dashboard:** Secure area for adding, editing, and deleting services.
- **Service Grouping:** Services are grouped by category on the main dashboard.
- **Custom Icons:** Support for custom icons per service (place in `frontend/public/icons/`).
- **Dark/Light Mode:** Toggle between dark and light themes, with preference saved.
- **Dockerized:** Easy deployment using Docker and Docker Compose.
- **Persistent Configuration:** Service definitions are stored persistently.

## Tech Stack

- **Frontend:** Vue.js 3 (with Vite), Tailwind CSS, Axios
- **Backend:** Node.js with Express.js
- **Data Storage:** `services.json` file for service configurations.
- **Authentication:** Session-based authentication with `bcrypt` for password hashing.
- **Containerization:** Docker & Docker Compose

## Prerequisites

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/install/) (usually included with Docker Desktop)

## Getting Started

1.  **Clone the Repository:**
    \`\`\`bash
    git clone <repository_url>
    cd homedash
    \`\`\`
    *(Replace \`<repository_url>\` with the actual URL of the repository)*

2.  **Configure Environment Variables:**
    The primary configuration is done via the `docker-compose.yml` file. Open it and **critically review and change the following environment variables** for the `backend` service, especially the defaults for `SESSION_SECRET` and admin credentials:
    - `SESSION_SECRET`: A long, random string used to secure sessions. **Change this from the default!**
    - `ADMIN_USERNAME`: The username for the admin account (default: `admin`).
    - `ADMIN_PASSWORD`: The password for the admin account (default: `changeme`). **Change this immediately!**
    - `FRONTEND_URL`: The URL where the frontend will be accessible (default: `http://localhost:8080`), used for CORS configuration.

3.  **Build and Run with Docker Compose:**
    \`\`\`bash
    docker-compose up --build -d
    \`\`\`
    The `-d` flag runs the containers in detached mode.

4.  **Access HomeDash:**
    - Frontend (Main Application): [http://localhost:8080](http://localhost:8080)
    - Backend API (if needed for direct access/testing): [http://localhost:3001](http://localhost:3001)

## Default Admin Credentials

Upon first launch, the default admin credentials are (as set in `docker-compose.yml`):
- **Username:** `admin`
- **Password:** `changeme`

**IMPORTANT:** Log in immediately after starting the application for the first time and change these credentials. (Currently, changing credentials via the UI is not implemented; you must change them in `docker-compose.yml` and restart the backend container: `docker-compose restart backend`).

## Data Persistence

Service configurations are stored in `./data/services.json` on your host machine, which is mounted into the backend container. This ensures your service list persists across container restarts.

## Custom Service Icons

- To use custom icons for your services:
    1. Add your icon file (e.g., `myservice.png`) to the `frontend/public/icons/` directory.
    2. When adding or editing a service in the Admin Dashboard, set the "Icon Filename" field to the name of your file (e.g., `myservice.png`).
- The dashboard includes some placeholder icons (`router.png`, `nas.png`) that you can replace or use as examples.

## Dark/Light Mode

The application supports a dark/light mode toggle. Your preference is saved in your browser's local storage.

## Development (Optional)

If you wish to run the frontend and backend separately for development:

**Backend:**
\`\`\`bash
cd backend
# Create a .env file from .env.example and fill in your values
cp .env.example .env
# (edit .env with your settings for SESSION_SECRET, ADMIN_PASSWORD etc.)
npm install
npm run dev # Or your development script, e.g., using nodemon
\`\`\`
The backend will typically run on `http://localhost:3001`.

**Frontend:**
\`\`\`bash
cd frontend
npm install
npm run dev
\`\`\`
The frontend development server will typically run on `http://localhost:5173` (Vite's default). Ensure the `FRONTEND_URL` in the backend's `.env` (or equivalent config) matches this for CORS during development. The frontend API calls currently point to `http://localhost:3001`.

## HTTPS Support

The default Docker Compose setup serves the application over HTTP. For HTTPS, it's recommended to use a reverse proxy (like Nginx, Traefik, or Caddy) in front of the HomeDash frontend container. The reverse proxy would handle SSL termination and forward requests to HomeDash.

## Contributing

Contributions are welcome! Please feel free to fork the repository, make changes, and submit pull requests.
