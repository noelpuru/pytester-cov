FROM python:3
RUN python3 -m venv /opt/venv

RUN . /opt/venv/bin/activate
RUN pip3 install pytest pytest-cov

RUN ls -al

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
