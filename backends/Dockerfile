FROM node:18-alpine

ENV NODE_ENV local
WORKDIR /nebulae/app
COPY ["package.json", "package-lock.json*", "npm-shrinkwrap.json*", "./"]
RUN npm install --production --silent && mv node_modules ../
COPY . .
COPY entrypoint.sh /

# ENTRYPOINT ["/entrypoint.sh"]
ENTRYPOINT ["/bin/sh", "-c" , "npm run get-ready && npm start"]
# CMD npm start