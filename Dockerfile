FROM archongum/spark:3.3.2-hadoop3

# -------------------------- Custom --------------------------
# Livy
## env
ENV LIVY_VERSION=0.7.1
ENV LIVY_HOME="/opt/livy"
ENV LIVY_CONF_DIR="/etc/livy"


## install
USER root
RUN set -eux \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    unzip \
  && apt-get purge -y --auto-remove; rm -rf /var/lib/apt/lists/* \
  # download
  && curl -kfSL https://archive.apache.org/dist/incubator/livy/0.7.1-incubating/apache-livy-0.7.1-incubating-bin.zip -o /tmp/livy.zip \
  # untar
  && unzip /tmp/livy.zip -d /tmp/ \
  && mv /tmp/apache-livy-0.7.1-incubating-bin ${LIVY_HOME} \
  && mkdir ${LIVY_HOME}/logs \
  # non-root
  && chown -R spark ${LIVY_HOME} \
  # conf
  && mv ${LIVY_HOME}/conf ${LIVY_CONF_DIR} \
  && ln -s ${LIVY_CONF_DIR} ${LIVY_HOME}/conf \
  # cleanup
  && rm -rf /tmp/* /var/tmp/*

WORKDIR ${LIVY_HOME}

# non-root
USER spark

# Default is executor entrypoint because STS's entrypoint can be changed in kubernetes yml file easily
ENTRYPOINT ["bin/livy-server"]
