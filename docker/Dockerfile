FROM python:3.11-alpine

LABEL maintainer="security-lab"
LABEL description="Phase 8 web app container"

RUN addgroup -S appgroup && \
    adduser -S -G appgroup -h /app -s /bin/sh appuser

WORKDIR /app
COPY app.py .
RUN chown -R appuser:appgroup /app

USER appuser
EXPOSE 8080
CMD ["python3", "app.py"]
