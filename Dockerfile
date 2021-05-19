FROM python:3
RUN python3 -m venv /opt/venv

COPY requirements.txt .
RUN . /opt/venv/bin/activate
RUN pip3 install pytest pytest-cov

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
