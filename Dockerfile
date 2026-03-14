# ---- Build stage ----
FROM node:20-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    libsecret-1-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY tsup.config.ts ./
COPY src ./src
COPY bin ./bin

RUN npm run generate && npm run build
RUN npm prune --production

# ---- Production stage ----
# Note: Using Debian-based image instead of Alpine because keytar (native dependency)
# is not compatible with Alpine's musl libc
FROM node:20-slim

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends libsecret-1-0 \
    && rm -rf /var/lib/apt/lists/*

# Remove npm and its bundled dependencies (not needed at runtime)
RUN rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx \
           /usr/local/bin/corepack

WORKDIR /app

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nodejs && \
    chown -R nodejs:nodejs /app

USER nodejs

COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./

RUN mkdir -p /app/logs

ENV NODE_ENV=production

EXPOSE 3000

ENTRYPOINT ["node", "dist/index.js"]
CMD []
