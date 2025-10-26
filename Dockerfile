FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ALL dependencies (including dev for building)
RUN npm ci

# Copy build configuration
COPY tsconfig.json ./
COPY tsup.config.ts ./

# Copy source code
COPY src ./src
COPY bin ./bin

# Generate schemas and build
RUN npm run generate && npm run build

# Remove dev dependencies to reduce size
RUN npm prune --production

# Create logs directory with proper permissions
RUN mkdir -p /app/logs && chmod 777 /app/logs

# Expose port for HTTP mode (optional)
EXPOSE 3000

# Default entrypoint and command
ENTRYPOINT ["node", "dist/index.js"]
CMD []
