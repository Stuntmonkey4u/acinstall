# Stage 1: Base Node image
FROM node:18-alpine AS base

WORKDIR /app/backend

# Copy package.json and package-lock.json (or npm-shrinkwrap.json)
COPY package*.json ./

# Stage 2: Install production dependencies
FROM base AS dependencies
# Install only production dependencies
RUN npm ci --only=production

# Stage 3: Copy application code
FROM base AS application
COPY --from=dependencies /app/backend/node_modules ./node_modules
COPY . .

# Default services.json - will be overwritten by volume mount in docker-compose
# Ensure a default one exists in the image for standalone 'docker run' if needed.
# If services.json is not in the repo root for the backend, adjust path.
# Assuming services.json is in the same directory as Dockerfile (backend/)
RUN if [ ! -f services.json ]; then \
    echo '[{"id":"default","name":"Example Service","url":"http://example.com","category":"Default","icon":""}]' > services.json; \
    fi

# Expose port
EXPOSE 3001

# Define environment variables needed by the application
# These should be set during 'docker run' or in docker-compose.yml
ENV NODE_ENV=production
ENV PORT=3001
# ENV SESSION_SECRET (to be set by user)
# ENV ADMIN_USERNAME (to be set by user)
# ENV ADMIN_PASSWORD (to be set by user)
# ENV FRONTEND_URL (to be set by user, e.g., http://localhost:8080)

# Start the application
CMD [ "node", "index.js" ]
