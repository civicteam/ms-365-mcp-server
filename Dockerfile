# Note: Using Debian-based image instead of Alpine because keytar (native dependency)
# is not compatible with Alpine's musl libc
FROM node:20-slim

# Install system dependencies needed by keytar (for credential storage)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libsecret-1-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create non-root user and set ownership of /app BEFORE npm install
# This ensures npm install scripts run as non-root for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nodejs && \
    chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Set npm cache directory to /app/.npm (owned by nodejs user)
# This prevents npm from trying to write to /nonexistent (the nodejs user's home)
ENV npm_config_cache=/app/.npm

# Copy package files
COPY --chown=nodejs:nodejs package*.json ./

# Install ALL dependencies (including dev for building)
RUN npm ci

# Copy build configuration
COPY --chown=nodejs:nodejs tsconfig.json ./
COPY --chown=nodejs:nodejs tsup.config.ts ./

# Copy source code
COPY --chown=nodejs:nodejs src ./src
COPY --chown=nodejs:nodejs bin ./bin

# Generate schemas and build
RUN npm run generate && npm run build

# Remove dev dependencies to reduce size
RUN npm prune --production

# Create logs directory with proper permissions
RUN mkdir -p /app/logs

# Set environment variables
ENV NODE_ENV=production

# Expose port for HTTP mode (optional)
EXPOSE 3000

# Default entrypoint and command
ENTRYPOINT ["node", "dist/index.js"]
CMD []
