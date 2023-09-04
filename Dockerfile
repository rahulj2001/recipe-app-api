FROM python:3.9-alpine3.13
LABEL maintainer="rahulj2001"

ENV PYTHONUNBUFFERED 1

COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
COPY ./app /app
WORKDIR /app
EXPOSE 8000

ARG DEV="false"

# Each line could be a separate RUN command but that would a new image layer for each command
# This only creates one layer and is more efficient and lightweight

# MY NOTES 
# 1. create a virtual env
# 2. upgade pip to latest inside the venv that we just created
# 2.5. download dependencies for psycopg2 package
# 3. install the requirements file
# 4. check if we are in dev mode and install the dev requirements as well
# 5. then remove the tmp dir and tmp apks - we dont want any extra deps - keep it lightweight
# 6. Best practice not to use root user - so run app with a user and group that has limited privileges
# 7. Change the ownership of the app dir to django-user

RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client && \
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    if [ $DEV = true ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    rm -rf /tmp && \
    apk del .tmp-build-deps && \
    adduser \
        --disabled-password \
        --no-create-home \
        django-user

RUN chown django-user:django-user -R /app/

# update the path env variable to run python commands from py/bin
ENV PATH="/py/bin:$PATH"

# switch to new created user with limited privileges
# USER django-user