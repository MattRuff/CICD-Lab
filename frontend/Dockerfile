# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine

# Install envsubst (part of gettext package)
RUN apk add --no-cache gettext

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.template.conf /etc/nginx/templates/nginx.template.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Set default values
ENV BACKEND_HOST=backend
ENV BACKEND_PORT=3000

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]

