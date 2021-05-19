FROM python:3
RUN pip3 install pytest pytest-cov
RUN if [ -f requirements.txt ]; then pip3 install -r requirements.txt; fi
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
