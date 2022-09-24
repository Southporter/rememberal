FROM docker.io/library/node:lts as frontend

WORKDIR /node

COPY frontend/ .
RUN npm install -g elm && \
    npx elm make src/Main.elm --output index.js --optimize


FROM docker.io/library/python:3.10-bullseye as app

WORKDIR /app
COPY --from=frontend /node/index.* .
COPY backends/python .

RUN pip install uvicorn==0.17.6 fastapi==0.75.2 sqlalchemy==1.4.36

EXPOSE 8000

ENTRYPOINT ["uvicorn", "app.main:app" , "--host", "0.0.0.0", "--port", "8000"]

