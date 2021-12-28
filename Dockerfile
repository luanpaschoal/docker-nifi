# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements. See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership. The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the
# specific language governing permissions and limitations
# under the License.
#

FROM openjdk:8-jre
LABEL maintainer="Apache NiFi <dev@nifi.apache.org>"
LABEL site="https://nifi.apache.org"

ARG NIFI_VERSION=1.15.2
ARG BASE_URL=https://archive.apache.org/dist
ARG MIRROR_BASE_URL=${MIRROR_BASE_URL:-${BASE_URL}}
ARG NIFI_BINARY_PATH=${NIFI_BINARY_PATH:-/nifi/${NIFI_VERSION}/nifi-${NIFI_VERSION}-bin.zip}
ARG NIFI_TOOLKIT_BINARY_PATH=${NIFI_TOOLKIT_BINARY_PATH:-/nifi/${NIFI_VERSION}/nifi-toolkit-${NIFI_VERSION}-bin.zip}
ARG MYSQL_DRIVER=mysql-connector-java-8.0.16
ARG MYSQL_DRIVER_URL=https://dev.mysql.com/get/Downloads/Connector-J/${MYSQL_DRIVER}.zip
ARG POSTGRESQL_DRIVER=postgresql-42.3.1
ARG POSTGRESQL_DRIVER_URL=https://jdbc.postgresql.org/download/${POSTGRESQL_DRIVER}.jar

ENV NIFI_BASE_DIR=/opt/nifi
ENV NIFI_HOME ${NIFI_BASE_DIR}/nifi-current
ENV NIFI_TOOLKIT_HOME ${NIFI_BASE_DIR}/nifi-toolkit-current

ENV NIFI_PID_DIR=${NIFI_HOME}/run
ENV NIFI_LOG_DIR=${NIFI_HOME}/conf/logs

USER root

# Setup NiFi user and create necessary directories
RUN mkdir -p ${NIFI_BASE_DIR} \
    && chmod -R 777 ${NIFI_BASE_DIR} \
    && apt-get update \
    && apt-get install -y jq xmlstarlet procps

RUN curl -fSL https://github.com/hairyhenderson/gomplate/releases/download/v3.6.0/gomplate_linux-amd64 \
      -o /usr/local/bin/gomplate \
    && chmod 775 /usr/local/bin/gomplate

RUN curl -fSL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 \
      -o /usr/local/bin/jq \
    && chmod 775 /usr/local/bin/jq

# Download, validate, and expand Apache NiFi Toolkit binary.
RUN curl -fSL ${MIRROR_BASE_URL}/${NIFI_TOOLKIT_BINARY_PATH} -o ${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION}-bin.zip \
    && echo "$(curl ${BASE_URL}/${NIFI_TOOLKIT_BINARY_PATH}.sha256) *${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION}-bin.zip" | sha256sum -c - \
    && unzip ${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION}-bin.zip -d ${NIFI_BASE_DIR} \
    && rm ${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION}-bin.zip \
    && mv ${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION} ${NIFI_TOOLKIT_HOME} \
    && ln -s ${NIFI_TOOLKIT_HOME} ${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION} \
    && chmod -R g+rwX ${NIFI_TOOLKIT_HOME}

# Download, validate, and expand Apache NiFi binary.
RUN curl -fSL ${MIRROR_BASE_URL}/${NIFI_BINARY_PATH} -o ${NIFI_BASE_DIR}/nifi-${NIFI_VERSION}-bin.zip \
    && echo "$(curl ${BASE_URL}/${NIFI_BINARY_PATH}.sha256) *${NIFI_BASE_DIR}/nifi-${NIFI_VERSION}-bin.zip" | sha256sum -c - \
    && unzip ${NIFI_BASE_DIR}/nifi-${NIFI_VERSION}-bin.zip -d ${NIFI_BASE_DIR} \
    && rm ${NIFI_BASE_DIR}/nifi-${NIFI_VERSION}-bin.zip \
    && mv ${NIFI_BASE_DIR}/nifi-${NIFI_VERSION} ${NIFI_HOME} \
    && mkdir -p ${NIFI_HOME}/conf \
    && mkdir -p ${NIFI_LOG_DIR} \
    && ln -s ${NIFI_HOME} ${NIFI_BASE_DIR}/nifi-${NIFI_VERSION} \
    && mkdir -p ${NIFI_HOME}/conf/drivers \
    && curl -fSL ${MYSQL_DRIVER_URL} -o ${NIFI_HOME}/conf/drivers/${MYSQL_DRIVER}.zip \
    && unzip -j ${NIFI_HOME}/conf/drivers/${MYSQL_DRIVER}.zip ${MYSQL_DRIVER}/${MYSQL_DRIVER}.jar -d ${NIFI_HOME}/conf/drivers \
    && curl -fSL ${POSTGRESQL_DRIVER_URL} -o ${NIFI_HOME}/conf/drivers/${POSTGRESQL_DRIVER}.jar \
    && chmod -R g+rwX ${NIFI_HOME}

ADD bootstrap.conf ${NIFI_HOME}/conf/bootstrap.conf

# Clear nifi-env.sh in favour of configuring all environment variables in the Dockerfile
RUN echo "#!/bin/sh\n" > ${NIFI_HOME}/bin/nifi-env.sh

# Web HTTP(s) & Socket Site-to-Site Ports
EXPOSE 8080 8443 10000 8000

WORKDIR ${NIFI_HOME}

USER 1001

# Apply configuration and start NiFi
#
# We need to use the exec form to avoid running our command in a subshell and omitting signals,
# thus being unable to shut down gracefully:
# https://docs.docker.com/engine/reference/builder/#entrypoint
#
# Also we need to use relative path, because the exec form does not invoke a command shell,
# thus normal shell processing does not happen:
# https://docs.docker.com/engine/reference/builder/#exec-form-entrypoint-example
ENTRYPOINT ["./scripts/start.sh"]
