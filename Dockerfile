ARG PG_MAJOR=14

# pgvector
FROM postgres:$PG_MAJOR as pgvector-builder

ARG PGVECTOR_BRAND=v0.4.1

RUN apt-get update && \
		apt-get install -y --no-install-recommends build-essential git ca-certificates postgresql-server-dev-$PG_MAJOR && \
    cd /tmp && \
    git clone --branch ${PGVECTOR_BRAND} https://github.com/pgvector/pgvector.git && \
		cd pgvector && \
		make clean && \
		make OPTFLAGS="" && \
		make install && \
		rm -r /tmp/pgvector && \
		rm -rf /var/lib/apt/lists/*


# postgres
FROM postgres:$PG_MAJOR

## support zh_CN.UTF-8
RUN localedef -i zh_CN -c -f UTF-8 -A /usr/share/locale/locale.alias zh_CN.UTF-8 \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ENV LANG zh_CN.UTF-8
ENV LC_COLLATE 'zh_CN.UTF-8'
ENV LC_CTYPE 'zh_CN.UTF-8'

## pgvector
COPY --from=pgvector-builder /usr/lib/postgresql/14/lib/ /usr/lib/postgresql/14/lib/
COPY --from=pgvector-builder /usr/share/postgresql/14/extension/ /usr/share/postgresql/14/extension/
