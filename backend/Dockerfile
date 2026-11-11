FROM node:20-alpine

# Set non-root working environment
WORKDIR /app

ENV NODE_ENV=production \
    PORT=8787

# Copy service dependencies and source code
COPY package.json ./
COPY server.mjs ./

# Run as unprivileged node user
USER node

EXPOSE 8787

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD node -e "fetch('http://localhost:' + (process.env.PORT || 8787) + '/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

CMD ["node", "server.mjs"]
