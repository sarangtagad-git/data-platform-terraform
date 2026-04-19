FROM python:3.11-slim

WORKDIR /app

# Install only what the ETL script needs
RUN pip install --no-cache-dir boto3

COPY main.py .

CMD ["python", "main.py"]
