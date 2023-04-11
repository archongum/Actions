FROM debian:bullseye

# -------------------------- Common --------------------------
# env
ENV TZ=Asia/Shanghai

# base tools
RUN set -eux \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
        vim \
        htop \
        telnet \
        iputils-ping \
        curl \
        procps \
        less \
  && apt-get purge -y --auto-remove; rm -rf /var/lib/apt/lists/*

# Addition
RUN set -eux \
  # In case of need for package installation
  && apt-get update \
  # alias
  && echo '' >> /etc/profile \
  && echo '# alias' >> /etc/profile \
  && echo 'alias ll="ls -lh --color=yes' >> /etc/profile

# -------------------------- JDK --------------------------
# env
ENV JDK_VERSION="8"
ENV JAVA_HOME="/opt/jdk/jdk-${JDK_VERSION}"
ENV PATH="${JAVA_HOME}/bin:$PATH"

## install
RUN set -eux \
  # profile
  && echo '' >> /etc/profile \
  && echo '# JDK' >> /etc/profile \
  && echo 'export JDK_VERSION=${JDK_VERSION}' >> /etc/profile \
  && echo 'export JAVA_HOME=${JAVA_HOME}' >> /etc/profile \
  && echo 'export PATH=${PATH}' >> /etc/profile \
  # download
  && curl -kfSL https://cdn.azul.com/zulu/bin/zulu8.68.0.21-ca-jdk8.0.362-linux_x64.tar.gz -o /tmp/jdk.tgz \
  # untar
  && mkdir -p ${JAVA_HOME} \
  && tar -xzf /tmp/jdk.tgz --strip-components=1 -C ${JAVA_HOME} \
  # cleanup
  && rm -rf /tmp/* /var/tmp/*

# -------------------------- Custom --------------------------
# Spark
## env
ENV SPARK_VERSION="3.1.3"
ENV SPARK_HOME="/opt/spark-${SPARK_VERSION}-bin-hadoop2.7"
ENV SPARK_CONF_DIR="/etc/spark"
ENV PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:$PATH"
WORKDIR ${SPARK_HOME}

## install
RUN set -eux \
  # profile
  && echo '' >> /etc/profile \
  && echo '# spark' >> /etc/profile \
  && echo 'export SPARK_VERSION=${SPARK_VERSION}' >> /etc/profile \
  && echo 'export SPARK_HOME=${SPARK_HOME}' >> /etc/profile \
  && echo 'export SPARK_CONF_DIR=${SPARK_CONF_DIR}' >> /etc/profile \
  && echo 'export PATH=${SPARK_HOME}/bin:${SPARK_HOME}/sbin:$PATH' >> /etc/profile \
  # download
  && curl -kfSL https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop2.7.tgz -o /tmp/spark.tgz \
  # untar
  && mkdir -p ${SPARK_HOME} \
  && tar -xzf /tmp/spark.tgz --strip-components=1 -C ${SPARK_HOME} \
  # conf
  && mv ${SPARK_HOME}/conf ${SPARK_CONF_DIR} \
  && ln -s ${SPARK_CONF_DIR} ${SPARK_HOME}/conf \
  # cleanup
  && rm -rf /tmp/* /var/tmp/*

## add jars, like mysql-jdbc, udf, etc.
RUN set -eux \
  # MySQL
  && curl -kfSL https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.48/mysql-connector-java-5.1.48.jar -o ${SPARK_HOME}/jars/mysql-connector-java-5.1.48.jar \
  # Elasticsearch 7.17
  && curl -kfSL https://repo1.maven.org/maven2/org/elasticsearch/elasticsearch-spark-20_2.12/7.17.9/elasticsearch-spark-20_2.12-7.17.9.jar -o ${SPARK_HOME}/jars/elasticsearch-spark-20_2.12-7.17.9.jar \
  # MongoDB for Spark 3.1+ and MongoDB 4.0+
  && curl -kfSL https://repo1.maven.org/maven2/org/mongodb/spark/mongo-spark-connector_2.12/10.1.1/mongo-spark-connector_2.12-10.1.1.jar -o ${SPARK_HOME}/jars/mongo-spark-connector_2.12-10.1.1.jar

# non-root
RUN useradd spark \
  && chown spark:spark -R ${SPARK_HOME} ${SPARK_CONF_DIR}
USER spark

ENTRYPOINT ["start-thriftserver.sh"]
CMD ["--help"]
