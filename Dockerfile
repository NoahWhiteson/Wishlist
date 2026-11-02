FROM node:22-alpine AS build
RUN apk add --no-cache libc6-compat
WORKDIR /src
COPY . .
WORKDIR /app
RUN if [ -f /src/api/package.json ]; then \
      cp -r /src/api/. /app/; \
    else \
      cp -r /src/. /app/; \
    fi
RUN npm ci --ignore-scripts
RUN npm run build

FROM node:22-alpine
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY --from=build /app/package.json /app/package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts
COPY --from=build /app/dist ./dist
EXPOSE 8787
CMD ["node", "dist/index.js"]
