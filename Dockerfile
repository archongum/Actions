# Base image
ARG HIVE_VERSION
FROM apache/hive:${HIVE_VERSION}

# Change user to get apt privilege
USER root
# MySQL jar, S3a jar
RUN \
    echo "Download database driver jar (MySQL)" && \
        apt update && apt-get install -y curl net-tools && \
        curl -L https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.23/mysql-connector-java-8.0.23.jar --output /opt/hive/lib/mysql-connector-java-8.0.23.jar && \
    echo "Add S3a jars to the classpath using this hack" && \
        ln -s /opt/hadoop/share/hadoop/tools/lib/hadoop-aws* /opt/hadoop/share/hadoop/common/lib/ && \
        ln -s /opt/hadoop/share/hadoop/tools/lib/aws-java-sdk* /opt/hadoop/share/hadoop/common/lib/ && \
    echo "Purge build artifacts" && \
        apt-get purge -y --auto-remove && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*
# Fix utf8 character issue by removed character settings
RUN cat <<-EOF >> ${HIVE_HOME}/scripts/metastore/upgrade/mysql/hive-schema-4.0.0.mysql.sql
-- Fix utf8 character issue by removed character settings
alter table COLUMNS_V2       modify column COMMENT      varchar(4000) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
alter table TYPE_FIELDS      modify column COMMENT      varchar(256)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
alter table PARTITION_KEYS   modify column PKEY_COMMENT varchar(4000) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
alter table PARTITION_KEYS   modify column PKEY_NAME    varchar(256)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
alter table PARTITION_KEYS   modify column PKEY_TYPE    varchar(767)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
alter table DATABASE_PARAMS  modify column PARAM_VALUE  varchar(4000) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
alter table PARTITION_PARAMS modify column PARAM_VALUE  mediumtext    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
alter table SD_PARAMS        modify column PARAM_VALUE  mediumtext    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
alter table SERDE_PARAMS     modify column PARAM_VALUE  mediumtext    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
alter table TABLE_PARAMS     modify column PARAM_VALUE  mediumtext    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

EOF

# Restore user
USER hive
