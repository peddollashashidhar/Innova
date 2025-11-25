# Use official slim python base image
FROM python:3.11-slim

# Create a non-root user
RUN addgroup --system app && adduser --system --ingroup app app

WORKDIR /app

# Copy requirements and install
COPY requirements.txt ./
RUN pip install --no-cache-dir -U pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

# Copy the source
COPY chat_fetcher.py ./

# Make the script executable
RUN chmod +x ./chat_fetcher.py

# Run as non-root
USER app

# Default entrypoint: run the chat fetcher. Pass runtime args to the container.
ENTRYPOINT ["python","/app/chat_fetcher.py"]
CMD ["--help"]
