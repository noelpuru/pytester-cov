FROM python:3
RUN pip3 install pytest pytest-cov
RUN pip3 install -r requirements.txt
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
