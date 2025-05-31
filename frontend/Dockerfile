# ---- Build Stage ----
FROM node:18-alpine AS build-stage

WORKDIR /app/frontend

COPY package*.json ./
RUN npm install

COPY . .

# Set VITE_API_BASE_URL if your app uses it to configure the backend URL
# This should ideally match where the backend will be accessible from the user's browser
# For docker-compose setup, if frontend is at port 8080 and backend at 3001,
# it would be http://localhost:3001/api or similar.
# If frontend is served by Nginx on port 80, and Nginx proxies /api to backend,
# then it could be /api.
# For now, let's assume direct access or a common proxy setup.
# The frontend code currently hardcodes http://localhost:3001. This should ideally be configurable.
# We'll add a placeholder for VITE_API_BASE_URL to be used during build if needed.
ARG VITE_API_BASE_URL=/api # Default if not provided, can be overridden at build time
ENV VITE_API_BASE_URL=\${VITE_API_BASE_URL}

RUN npm run build

# ---- Serve Stage ----
FROM nginx:1.25-alpine AS serve-stage

# Copy built assets from build stage
COPY --from=build-stage /app/frontend/dist /usr/share/nginx/html

# Copy nginx configuration
# Create a default nginx.conf for SPA
RUN rm /etc/nginx/conf.d/default.conf
COPY <<EOF /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name localhost;

    root /usr/share/nginx/html;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Optional: Proxy API requests to backend if frontend and backend are served under the same domain by Nginx
    # This requires frontend to make API calls to /api/... instead of http://localhost:3001/api/...
    # And docker-compose to link frontend to backend.
    # location /api/ {
    #    proxy_pass http://backend:3001/api/; # 'backend' is the service name in docker-compose
    #    proxy_set_header Host \$host;
    #    proxy_set_header X-Real-IP \$remote_addr;
    #    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    #    proxy_set_header X-Forwarded-Proto \$scheme;
    # }
}
EOF

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
