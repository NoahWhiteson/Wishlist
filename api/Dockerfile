# Coolify: build context is the repo root, Dockerfile path is /api/Dockerfile.
# Local: docker build -f api/Dockerfile .

FROM node:22-alpine AS build
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY api/package.json api/package-lock.json ./
RUN npm ci --ignore-scripts
COPY api/tsconfig.json ./
COPY api/src ./src
RUN npm run build

FROM node:22-alpine
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY api/package.json api/package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts
COPY --from=build /app/dist ./dist
EXPOSE 8787
CMD ["node", "dist/index.js"]
