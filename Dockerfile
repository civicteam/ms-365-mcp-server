FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./
COPY tsup.config.ts ./

# Install dependencies
RUN npm ci

# Copy source code
COPY src ./src
COPY bin ./bin

# Generate schemas and build
RUN npm run generate && npm run build

# Create a minimal runtime layer
FROM node:20-alpine

WORKDIR /app

# Copy built files and dependencies
COPY --from=0 /app/package*.json ./
COPY --from=0 /app/dist ./dist
COPY --from=0 /app/node_modules ./node_modules

# Expose port for HTTP mode (optional)
EXPOSE 3000

# Default entrypoint and command
ENTRYPOINT ["node", "dist/index.js"]
CMD []
