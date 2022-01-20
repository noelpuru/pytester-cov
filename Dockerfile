FROM python:3.8-buster

RUN set -eux; \
	apt-get update; \
	rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
