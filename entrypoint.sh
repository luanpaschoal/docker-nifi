#!/bin/bash

if ! whoami &> /dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME:-nifi}:x:$(id -u):0:${USER_NAME:-nifi} user:${HOME}:/sbin/nologin" >> /etc/passwd
  fi
fi

CONF_DIR="${NIFI_HOME}/conf"
CLASSPATH=$(find ${NIFI_HOME}/lib -type f | tr '\n' ':')
CLASSPATH="${CLASSPATH}${CONF_DIR}"

# Override JVM memory settings
if [ ! -z "${JVM_HEAP_INIT}" ]; then
  JAVA_OPTS="${JAVA_OPTS} -Xms${JVM_HEAP_INIT}"
fi

if [ ! -z "${JVM_HEAP_MAX}" ]; then
  JAVA_OPTS="${JAVA_OPTS} -Xmx${JVM_HEAP_MAX}"
fi

JAVA_OPTS="${JAVA_OPTS} -Dorg.apache.jasper.compiler.disablejsr199=true -Djavax.security.auth.useSubjectCredsOnly=true -Djava.security.egd=file:/dev/urandom -Dsun.net.http.allowRestrictedHeaders=true -Djava.net.preferIPv4Stack=true -Djava.awt.headless=true -Djava.protocol.handler.pkgs=sun.net.www.protocol -Dorg.apache.nifi.bootstrap.config.log.dir=/opt/nifi/nifi-current/logs"

if [ -d ${CONF_DIR}/templates ]; then
  for file in $(ls -1 ${CONF_DIR}/templates | grep -E '\.tpl$'); do
    out_file=${file%%.tpl}
    gomplate -f ${CONF_DIR}/templates/${file} -o ${CONF_DIR}/${out_file}
    if [ $? -ne 0 ]; then
      echo "Error rendering config template file ${CONF_DIR}/${out_file}. Aborting."
      exit 1
    fi
    echo "Generated config file from template in ${CONF_DIR}/${out_file}"
  done
fi

JAVA_CMD="java -classpath ${CLASSPATH} -Dnifi.properties.file.path=${NIFI_HOME}/conf/nifi.properties ${JAVA_OPTS} org.apache.nifi.NiFi"

echo "Launching NiFi with the following command: ${JAVA_CMD}"
exec $JAVA_CMD
