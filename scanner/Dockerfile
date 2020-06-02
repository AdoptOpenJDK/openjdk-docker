FROM python:3.7-alpine

COPY requirements.txt scanner.py /

# Install and Remove requirements.txt
RUN pip install -r requirements.txt && rm -f requirements.txt

# Create entrypoint for script
ENTRYPOINT ["/usr/local/bin/python", "scanner.py"]
