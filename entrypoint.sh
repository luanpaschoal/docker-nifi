#!/bin/bash

CONF_DIR="${NIFI_HOME}/conf"
CLASSPATH=$(ls -1 ${NIFI_HOME}/lib/*.jar | tr '\n' ':')
CLASSPATH="${CLASSPATH}${CONF_DIR}"

# Override JVM memory settings
if [ ! -z "${JVM_HEAP_INIT}" ]; then
  JAVA_OPTS="${JAVA_OPTS} -Xms${JVM_HEAP_INIT}"
fi

if [ ! -z "${JVM_HEAP_MAX}" ]; then
  JAVA_OPTS="${JAVA_OPTS} -Xmx${JVM_HEAP_MAX}"
fi

JAVA_OPTS="${JAVA_OPTS} -Dorg.apache.jasper.compiler.disablejsr199=true -Djavax.security.auth.useSubjectCredsOnly=true -Djava.security.egd=file:/dev/urandom -Dsun.net.http.allowRestrictedHeaders=true -Djava.net.preferIPv4Stack=true -Djava.awt.headless=true -Djava.protocol.handler.pkgs=sun.net.www.protocol -Dnifi.bootstrap.listen.port=41491 -Dorg.apache.nifi.bootstrap.config.log.dir=/opt/nifi/nifi-current/logs"

for file in ${CONF_DIR}/*.tpl; do
  out_file=${file%%.tpl}
  gomplate -f ${file} -o ${out_file} && echo "Generated config file from template in ${out_file}"
done

JAVA_CMD="java -classpath ${CLASSPATH} -Dnifi.properties.file.path=${NIFI_HOME}/conf/nifi.properties org.apache.nifi.NiFi"

echo "Launching NiFi with the following command: ${JAVA_CMD}"
exec $JAVA_CMD
