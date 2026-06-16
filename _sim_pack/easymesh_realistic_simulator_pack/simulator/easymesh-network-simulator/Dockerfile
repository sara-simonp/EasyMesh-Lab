FROM python:3.12-alpine
WORKDIR /app
COPY app.py /app/app.py
EXPOSE 9200
ENV SIM_PORT=9200
ENV DATA_DIR=/data
ENV WRITE_TR181_CSV=1
CMD ["python", "/app/app.py"]
