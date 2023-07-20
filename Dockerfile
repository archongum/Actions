ARG LIVY_VERSION
FROM archongum/livy-bin:${LIVY_VERSION}-scala2.12-spark3-hadoop3 as builder

FROM archongum/spark:3.3.2-hadoop3

# -------------------------- Custom --------------------------
# Livy
## env
ENV LIVY_VERSION=${LIVY_VERSION}
ENV LIVY_HOME="/opt/livy"
ENV LIVY_CONF_DIR="/etc/livy"

## install
USER root
COPY --from=builder /tmp/livy ${LIVY_HOME}
RUN set -eux \
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
ENTRYPOINT ["${LIVY_HOME}/bin/livy-server"]
CMD ["--help"]
