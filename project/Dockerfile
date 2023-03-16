FROM python:3.8
LABEL maintainer="Sami Islam"

COPY . /app
WORKDIR /app
RUN pip install flask werkzeug

# command to run on container start
CMD [ "python", "hello-k8s.py" ]