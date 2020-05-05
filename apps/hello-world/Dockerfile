FROM node:8-alpine

WORKDIR /app
COPY views views/
COPY package.json .
COPY server.js .

ENV NPM_CONFIG_LOGLEVEL warn
ENV PORT 8080
RUN npm install --production

EXPOSE 8080

CMD ["node", "server.js"]
