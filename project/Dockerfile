FROM python:3.8
LABEL maintainer="KienLe TV"

COPY . /app
WORKDIR /app
RUN pip install flask werkzeug

# command to run on container start
CMD [ "python", "hello-k8s.py" ]