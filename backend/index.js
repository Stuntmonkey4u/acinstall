const express = require('express');
const cors = require('cors');
const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');
const bcrypt = require('bcrypt');
const session = require('express-session');
const axios = require('axios'); // Added axios

// Load environment variables if using a .env file (optional, for local dev)
// require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;
const SERVICES_FILE_PATH = path.join(__dirname, 'services.json');

// --- Environment Variables & Configuration ---
const SESSION_SECRET = process.env.SESSION_SECRET || 'default_secret_key';
const ADMIN_USERNAME = process.env.ADMIN_USERNAME || 'admin';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'adminpass';
let ADMIN_PASSWORD_HASH = '';

// --- Middleware ---
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:5173', // Adjusted for Vite
  credentials: true
}));
app.use(express.json());
app.use(session({
  secret: SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000
  }
}));

// --- Authentication Middleware ---
const isAuthenticated = (req, res, next) => {
  if (req.session && req.session.userId) {
    return next();
  }
  res.status(401).json({ message: 'Unauthorized. Please log in.' });
};

// --- Helper Functions for services.json ---
async function readServices() {
  try {
    const data = await fs.readFile(SERVICES_FILE_PATH, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    if (error.code === 'ENOENT') return [];
    console.error("Error reading services file:", error);
    throw new Error('Could not read services data.');
  }
}

async function writeServices(services) {
  try {
    await fs.writeFile(SERVICES_FILE_PATH, JSON.stringify(services, null, 2), 'utf8');
  } catch (error) {
    console.error("Error writing services file:", error);
    throw new Error('Could not save services data.');
  }
}

// --- Service Health Check Function ---
async function checkServiceHealth(service) {
  let urlToCheck = service.url;
  if (!urlToCheck.startsWith('http://') && !urlToCheck.startsWith('https://')) {
    urlToCheck = 'http://' + urlToCheck; // Default to HTTP if no scheme
  }

  try {
    // Setting a timeout is important to prevent hanging requests
    const response = await axios.get(urlToCheck, { timeout: 5000 });
    // Consider any 2xx or 3xx status as 'up'. Some services might redirect.
    if (response.status >= 200 && response.status < 400) {
      return { ...service, status: 'up', lastChecked: new Date().toISOString() };
    } else {
      return { ...service, status: 'down', statusCode: response.status, lastChecked: new Date().toISOString() };
    }
  } catch (error) {
    let errorMessage = 'Error connecting';
    if (error.code) { // Axios error code (e.g., ENOTFOUND, ECONNREFUSED)
        errorMessage = error.code;
    } else if (error.response && error.response.status) { // HTTP status from error response
        errorMessage = `Status ${error.response.status}`;
    }
    return { ...service, status: 'down', error: errorMessage, lastChecked: new Date().toISOString() };
  }
}


// --- API Endpoints ---

// Health check for the backend itself
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'UP', message: 'Backend is running' });
});

// --- Authentication Endpoints ---
app.post('/api/auth/login', async (req, res) => {
  const { username, password } = req.body;
  if (username === ADMIN_USERNAME && await bcrypt.compare(password, ADMIN_PASSWORD_HASH)) {
    req.session.userId = ADMIN_USERNAME;
    req.session.isAdmin = true;
    res.json({ message: 'Login successful', user: { username: ADMIN_USERNAME, isAdmin: true } });
  } else {
    res.status(401).json({ message: 'Invalid username or password.' });
  }
});

app.post('/api/auth/logout', (req, res) => {
  req.session.destroy(err => {
    if (err) {
      return res.status(500).json({ message: 'Could not log out, please try again.' });
    }
    res.clearCookie('connect.sid');
    res.status(200).json({ message: 'Logout successful.' });
  });
});

app.get('/api/auth/status', (req, res) => {
  if (req.session && req.session.userId) {
    res.json({ isLoggedIn: true, user: { username: req.session.userId, isAdmin: req.session.isAdmin } });
  } else {
    res.json({ isLoggedIn: false });
  }
});

// --- Service Management Endpoints ---

// GET /api/services - List all services (public)
app.get('/api/services', async (req, res, next) => {
  try {
    const services = await readServices();
    res.json(services);
  } catch (error) {
    next(error);
  }
});

// GET /api/services/statuses - Get all services with their health status
app.get('/api/services/statuses', async (req, res, next) => {
  try {
    const services = await readServices();
    const servicesWithStatus = await Promise.all(services.map(service => checkServiceHealth(service)));
    res.json(servicesWithStatus);
  } catch (error) {
    next(error);
  }
});

// POST /api/services - Add a new service (admin only)
app.post('/api/services', isAuthenticated, async (req, res, next) => {
  try {
    const { name, url, category, icon } = req.body;
    if (!name || !url) {
      return res.status(400).json({ message: 'Name and URL are required.' });
    }
    const services = await readServices();
    const newService = {
      id: crypto.randomBytes(16).toString('hex'),
      name,
      url,
      category: category || 'General',
      icon: icon || ''
    };
    services.push(newService);
    await writeServices(services);
    res.status(201).json(newService);
  } catch (error) {
    next(error);
  }
});

// PUT /api/services/:id - Update an existing service (admin only)
app.put('/api/services/:id', isAuthenticated, async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, url, category, icon } = req.body;
    if (!name || !url) {
      return res.status(400).json({ message: 'Name and URL are required.' });
    }
    let services = await readServices();
    const serviceIndex = services.findIndex(s => s.id === id);

    if (serviceIndex === -1) {
      return res.status(404).json({ message: 'Service not found.' });
    }

    const updatedService = { ...services[serviceIndex], name, url, category, icon };
    services[serviceIndex] = updatedService;
    await writeServices(services);
    res.json(updatedService);
  } catch (error) {
    next(error);
  }
});

// DELETE /api/services/:id - Delete a service (admin only)
app.delete('/api/services/:id', isAuthenticated, async (req, res, next) => {
  try {
    const { id } = req.params;
    let services = await readServices();
    const filteredServices = services.filter(s => s.id !== id);

    if (services.length === filteredServices.length) {
      return res.status(404).json({ message: 'Service not found.' });
    }

    await writeServices(filteredServices);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

// Basic error handling middleware
app.use((err, req, res, next) => {
  console.error(err.message || err.stack);
  res.status(500).json({ message: err.message || 'Something broke!' });
});

// --- Initialize Admin Password Hash and Start Server ---
async function startServer() {
  try {
    const saltRounds = 10;
    ADMIN_PASSWORD_HASH = await bcrypt.hash(ADMIN_PASSWORD, saltRounds);
    // console.log('Admin password hashed.'); // Keep console cleaner

    app.listen(PORT, () => {
      console.log(`Backend server is running on http://localhost:${PORT}`);
      // console.log(`Admin username: ${ADMIN_USERNAME}`);
      // console.log(`Admin password (for local dev): ${ADMIN_PASSWORD}`);
      // console.log(`Session secret (for local dev): ${SESSION_SECRET}`);
    });
  } catch (error) {
    console.error("Failed to hash admin password or start server:", error);
    process.exit(1);
  }
}

startServer();
