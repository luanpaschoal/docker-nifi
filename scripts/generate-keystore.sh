#!/bin/bash -e
#
#
# This is a helper script to generate certificate in runtime to enable HTTPS in NiFi,
# useful for setups with dynamic certificates, like Let's Encrypt, etc.
#
# It only cares about server-side certificates (a.k.a. keystore). Truststore is also
# provided, but only to keep compatibility with default configurations that expects it.
# If PEM certificate key-pair is provided, keystore is created with it. If not, a
# self-signed pair is generated.
#
# Also, the password is dummy, and not supposed to protect key, but only provided because
# it is a requirement. At the end of the day, we only want SSL encryption enabled, not
# authentication.
#

cert=${1:-/opt/nifi/nifi-current/ssl/cert.pem}
key=${2:-/opt/nifi/nifi-current/ssl/key.pem}
out_dir=${3:-/opt/nifi/nifi-current/conf}

# Password strength doesn't really matter in this case
PASSWORD="nifinifi"

if [ -f ${cert} -a -f ${key} ]; then
  openssl pkcs12 -export -in ${cert} -inkey ${key} -passout "pass:${PASSWORD}" -name nifi-key > /tmp/nifi.p12 && \
  keytool -importkeystore -srckeystore /tmp/nifi.p12 -destkeystore ${out_dir}/keystore.jks -noprompt \
    -srcstoretype pkcs12 -alias nifi-key -deststorepass ${PASSWORD} -srcstorepass ${PASSWORD} && \
  keytool -import -alias nifi-cert -file ${cert} -keystore ${out_dir}/truststore.jks \
    -deststorepass ${PASSWORD} -noprompt && \
  echo -e "\nWritten files: ${out_dir}/keystore.jks and ${out_dir}/truststore.jks with password '${PASSWORD}'."
else
  echo "Certificates not found. Auto-generating key-pair."
  /opt/nifi/nifi-toolkit-current/bin/tls-toolkit.sh standalone -n 'localhost' -C 'CN=localhost, OU=NIFI' \
    -o /tmp --keyPassword ${PASSWORD} --clientCertPassword ${PASSWORD} && \
  cp /tmp/localhost/keystore.jks ${out_dir}/keystore.jks && \
  cp /tmp/localhost/truststore.jks ${out_dir}/truststore.jks && \
  echo -e "\nWritten files: ${out_dir}/keystore.jks and ${out_dir}/truststore.jks with password '${PASSWORD}'".
fi
