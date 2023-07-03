FROM debian:bullseye

# -------------------------- Common --------------------------
# settings
SHELL ["/bin/bash", "-c"]

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
ENV SPARK_EXTJARS="${SPARK_HOME}/extjars"
ENV PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:$PATH"
WORKDIR ${SPARK_HOME}

## install
RUN set -eux \
  # specific user
  && useradd spark \
  # version switch
  ## hadoop-aws
  && if [[ "${HADOOP_VERSION}" == "2" ]] ; then export export HADOOP_AWS=2.7.7 ; fi \
  && if [[ "${HADOOP_VERSION}" == "3" ]] ; then export export HADOOP_AWS=3.3.6 ; fi \
  ## spark-hadoop
  && if [[ "${HADOOP_VERSION}" == "2" && ( "${SPARK_VERSION:2:1}" == "1" || "${SPARK_VERSION:2:1}" == "2" ) ]] ; then export HADOOP_VERSION=2.7 ; fi \
  && if [[ "${HADOOP_VERSION}" == "3" && ( "${SPARK_VERSION:2:1}" == "1" || "${SPARK_VERSION:2:1}" == "2" ) ]] ; then export HADOOP_VERSION=3.2 ; fi \
  && echo "Use HADOOP_VERSION=${HADOOP_VERSION}" \
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
  && spark_extjars_url=( \
      # S3
      https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS}/hadoop-aws-${HADOOP_AWS}.jar \
      https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk/1.12.500/aws-java-sdk-1.12.500.jar \
      # Iceberg Extension
      https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-${SPARK_VERSION:0:3}_2.12/1.3.0/iceberg-spark-runtime-${SPARK_VERSION:0:3}_2.12-1.3.0.jar \
      # MySQL Datasource
      https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.48/mysql-connector-java-5.1.48.jar \
      # ES Datasource
      https://repo1.maven.org/maven2/org/elasticsearch/elasticsearch-spark-20_2.12/7.17.9/elasticsearch-spark-20_2.12-7.17.9.jar \
      # MongoDB Datasource, Spark Connector 3.x for Data Source not 10.x that for Structured Streaming, ref: https://www.mongodb.com/blog/post/new-mongodb-spark-connector
      https://repo1.maven.org/maven2/org/mongodb/spark/mongo-spark-connector_2.12/3.0.2/mongo-spark-connector_2.12-3.0.2-assembly.jar \
  ) \
  && for file_url in "${spark_extjars_url[@]}"; do \
      echo "Download file [$file_url]" ; \
      curl -kfSL --create-dirs --output-dir ${SPARK_EXTJARS} -O "$file_url" ; \
  done

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

# (WIP)non-root
#USER spark

ENTRYPOINT ["/entrypoint.sh"]
CMD ["--help"]
