FROM node

ARG VERSION=unknown

COPY *.json ./
RUN npm install

COPY *.js ./
RUN echo $VERSION > ./version

CMD ["npm", "start"]
