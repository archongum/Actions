FROM bitnami/postgresql:14-debian-11

USER root

# base tools
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		vim \
		htop \
		telnet \
		iputils-ping \
	; \
	apt-get purge -y --auto-remove; rm -rf /var/lib/apt/lists/*

# Use Aliyun Source
RUN echo '\
deb https://mirrors.aliyun.com/debian/ bullseye           main\n\
deb https://mirrors.aliyun.com/debian/ bullseye-updates   main\n\
deb https://mirrors.aliyun.com/debian/ bullseye-security  main\
'\
> /etc/apt/sources.list

# Addition
RUN set -eux; \
	apt-get update; \
  echo 'alias ll="ls -lh --color=yes"' >> /etc/profile

ENTRYPOINT ["/bin/bash", "-l", "-c"]
