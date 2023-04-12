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
  && apt-get update

# -------------------------- JDK --------------------------
# env
ENV JDK_VERSION="8"
ENV JAVA_HOME="/opt/jdk/jdk-${JDK_VERSION}"
ENV PATH="${JAVA_HOME}/bin:$PATH"

## install
RUN set -eux \
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
ARG SPARK_VERSION
ARG HADOOP_VERSION
ENV SPARK_VERSION=${SPARK_VERSION}
ENV SPARK_HOME="/opt/spark-${SPARK_VERSION}"
ENV SPARK_CONF_DIR="/etc/spark"
ENV PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:$PATH"
WORKDIR ${SPARK_HOME}

## install
RUN set -eux \
  && if [[ "${HADOOP_VERSION}" == "2" && "${SPARK_VERSION:2:1}" != "3" ]]; then export HADOOP_VERSION=2.7; elif [[ "${HADOOP_VERSION}" == "3" && "${SPARK_VERSION:2:1}" != "3" ]]; then export HADOOP_VERSION=3.2; else echo "Use Default HADOOP_VERSION=${HADOOP_VERSION}"; fi \
  # download
  && curl -kfSL https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -o /tmp/spark.tgz \
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
  && curl -kfSL https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.48/mysql-connector-java-5.1.48.jar --create-dirs -o ${SPARK_HOME}/extjars/mysql-connector-java-5.1.48.jar \
  # Elasticsearch 7.17
  && curl -kfSL https://repo1.maven.org/maven2/org/elasticsearch/elasticsearch-spark-20_2.12/7.17.9/elasticsearch-spark-20_2.12-7.17.9.jar --create-dirs -o ${SPARK_HOME}/extjars/elasticsearch-spark-20_2.12-7.17.9.jar \
  # MongoDB Spark Connector 3.x for Data Source not 10.x that for Structured Streaming, ref: https://www.mongodb.com/blog/post/new-mongodb-spark-connector
  && curl -kfSL https://repo1.maven.org/maven2/org/mongodb/spark/mongo-spark-connector_2.12/3.0.2/mongo-spark-connector_2.12-3.0.2-assembly.jar --create-dirs -o ${SPARK_HOME}/extjars/mongo-spark-connector_2.12-3.0.2-assembly.jar

## entrypoint.sh
RUN printf '%s\n' > /entrypoint.sh \
    '#!/bin/bash' \
    'java -cp "${SPARK_CONF_DIR}:${SPARK_HOME}/jars/*:${SPARK_HOME}/extjars/*" \' \
    'org.apache.spark.deploy.SparkSubmit \' \
    '--class org.apache.spark.sql.hive.thriftserver.HiveThriftServer2 \' \
    '--name "Spark Thrift Server (Docker)" \' \
    '"$@" \' \
    'spark-internal' \
    && chmod +x /entrypoint.sh

# non-root
RUN useradd spark \
  && chown spark:spark -R ${SPARK_HOME} ${SPARK_CONF_DIR}
USER spark

ENTRYPOINT ["/entrypoint.sh"]
CMD ["--help"]
