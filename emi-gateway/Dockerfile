FROM node:10.15.1
COPY merged-projects/playground/emi-gateway /app/emi-gateway
WORKDIR /app/emi-gateway
RUN npm rebuild
RUN npm install --prod
USER node
CMD [ "npm","start" ]
