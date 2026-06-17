FROM node:22 AS base
WORKDIR /app

COPY package.json package.json
# COPY package-lock.json package-lock.json
RUN npm install
COPY . .
CMD ["npm", "run", "dev"]
