FROM python:3.6
RUN set -eux; \
	apt-get update; \
	apt-get install -y sqlite3; \
	rm -rf /var/lib/apt/lists/*
RUN pip install pytest pytest-cov
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
