#!/bin/bash

CONF_DIR="${NIFI_HOME}/conf"
CLASSPATH=$(ls -1 ${NIFI_HOME}/lib/*.jar | tr '\n' ':')
CLASSPATH="${CLASSPATH}${CONF_DIR}"

# Override JVM memory settings
if [ ! -z "${NIFI_JVM_HEAP_INIT}" ]; then
  JAVA_OPTS="${JAVA_OPTS} -Xms${NIFI_JVM_HEAP_INIT}"
fi

if [ ! -z "${NIFI_JVM_HEAP_MAX}" ]; then
  JAVA_OPTS="${JAVA_OPTS} -Xmx${NIFI_JVM_HEAP_MAX}"
fi

JAVA_OPTS="${JAVA_OPTS} -Dorg.apache.jasper.compiler.disablejsr199=true -Djavax.security.auth.useSubjectCredsOnly=true -Djava.security.egd=file:/dev/urandom -Dsun.net.http.allowRestrictedHeaders=true -Djava.net.preferIPv4Stack=true -Djava.awt.headless=true -Djava.protocol.handler.pkgs=sun.net.www.protocol -Dnifi.bootstrap.listen.port=41491 -Dorg.apache.nifi.bootstrap.config.log.dir=/opt/nifi/nifi-current/logs"

exec java -classpath ${CLASSPATH} -Dnifi.properties.file.path=${NIFI_HOME}/conf/nifi.properties org.apache.nifi.NiFi
