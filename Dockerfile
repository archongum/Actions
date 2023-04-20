# pgvector
# FROM postgres:14 as pgvector-builder
# RUN apt-get update \
#     # clickhouse_fdw build
#     && apt-get install -y --no-install-recommends openssl ca-certificates libssl-dev postgresql-server-dev-14 libcurl4-openssl-dev automake make gcc cmake autoconf pkg-config libtool uuid-dev git build-essential \
#     && cd /tmp \
#     && git clone --branch ${PGVECTOR_BRAND} https://github.com/pgvector/pgvector.git \
#     && cd pgvector \
#     && make && make install \
#     && cd - && rm -rf /tmp/pgvector

# postgres
FROM postgres:14

ARG PG_MAJOR=14
ARG PGVECTOR_BRAND=v0.4.1

RUN apt-get update && \
		apt-get install -y --no-install-recommends build-essential postgresql-server-dev-$PG_MAJOR && \
    cd /tmp && \
    git clone --branch ${PGVECTOR_BRAND} https://github.com/pgvector/pgvector.git && \
		cd pgvector && \
		make clean && \
		make OPTFLAGS="" && \
		make install && \
		mkdir /usr/share/doc/pgvector && \
		cp LICENSE README.md /usr/share/doc/pgvector && \
		rm -r /tmp/pgvector && \
		apt-get remove -y build-essential postgresql-server-dev-$PG_MAJOR && \
		apt-get autoremove -y && \
		rm -rf /var/lib/apt/lists/*

## pgvector
# COPY --from=pgvector-builder /usr/lib/postgresql/14/lib/ /usr/lib/postgresql/14/lib/
# COPY --from=pgvector-builder /usr/share/postgresql/14/extension/ /usr/share/postgresql/14/extension/

ENV PGDATA /data

## support zh_CN.UTF-8
RUN localedef -i zh_CN -c -f UTF-8 -A /usr/share/locale/locale.alias zh_CN.UTF-8 \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ENV LANG zh_CN.UTF-8
ENV LC_COLLATE 'zh_CN.UTF-8'
ENV LC_CTYPE 'zh_CN.UTF-8'
