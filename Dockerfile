FROM node:18-bullseye

WORKDIR /workspace

RUN set -eux \
  && apt-get update \
  && apt-get install -y unzip \
  && curl -kSL -O https://github.com/qdrant/qdrant-web-ui/archive/refs/heads/master.zip \
  && unzip master.zip \
  && rm -f master.zip && apt-get purge -y --auto-remove && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace/qdrant-web-ui-master

RUN set -eux \
  && npm install

ENTRYPOINT ["npm"]
CMD ["start"]
