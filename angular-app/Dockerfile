# Stage 1 — build
FROM node:18-alpine AS build
WORKDIR /app

# install dependencies (cache by copying package.json first)
COPY package*.json ./
RUN npm ci --silent

# copy sources and build (AOT + production)
COPY . .
# If you use environment files, set ANGULAR_CLI to use the right config or pass --configuration
RUN npx -p @angular/cli ng build --configuration production --output-path=dist --base-href=/

# Stage 2 — runtime (nginx)
FROM nginx:stable-alpine
# Remove default nginx html
RUN rm -rf /usr/share/nginx/html/*

# Copy built files from builder
COPY --from=build /app/dist /usr/share/nginx/html

# Copy custom nginx config (optional, for SPA fallback)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port (optional)
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]