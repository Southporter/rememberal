FROM docker.io/library/python:3.10-bullseye as app

WORKDIR /app
COPY backends/python .
COPY frontend/index.* public/.

RUN pip install uvicorn==0.17.6 fastapi==0.75.2 sqlalchemy==1.4.36

EXPOSE 8000

ENTRYPOINT ["uvicorn", "app.main:app" , "--host", "0.0.0.0", "--port", "8000"]

