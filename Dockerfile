FROM archongum/spark:3.3.2-hadoop3

# -------------------------- Custom --------------------------
# Livy
## env
ENV LIVY_VERSION=0.7.1
ENV LIVY_HOME="/opt/livy"
ENV LIVY_CONF_DIR="/etc/livy"
WORKDIR ${LIVY_HOME}

## install
RUN set -eux \
  # specific user
  && useradd spark \
  && curl -kfSL https://archive.apache.org/dist/incubator/livy/0.7.1-incubating/apache-livy-0.7.1-incubating-bin.zip -o /tmp/livy.zip \
  # untar
  && unzip /tmp/livy.zip -d /tmp/ \
  && mv /tmp/apache-livy-0.7.1-incubating-bin ${LIVY_HOME} \
  # conf
  && mv ${LIVY_HOME}/conf ${LIVY_CONF_DIR} \
  && ln -s ${LIVY_CONF_DIR} ${LIVY_CONF_DIR}/conf \
  # non-root
  && chown -R spark ${LIVY_HOME} \
  # cleanup
  && rm -rf /tmp/* /var/tmp/*

# non-root
USER spark

# Default is executor entrypoint because STS's entrypoint can be changed in kubernetes yml file easily
ENTRYPOINT ["bin/livy-server"]
CMD ["--help"]
