FROM python:3
RUN pip3 install pytest pytest-cov
COPY entrypoint.sh /
COPY .coveragerc /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
