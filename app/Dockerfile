# Use lightweight Node.js image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy dependency manifests
COPY package.json package-lock.json ./

# Install only production dependencies (faster, reproducible)
RUN npm ci --omit=dev

# Copy application code
COPY src ./src

# Expose port
EXPOSE 3000

# Run the app
CMD ["npm", "start"]