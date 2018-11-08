Development Tomcat wildcard certificates and keystore generated via:

```
$ openssl genrsa -out tomcat-wildcard-dev.key 2048
$ openssl req -nodes -newkey rsa:2048 -keyout  tomcat-wildcard-dev.key -out  tomcat-wildcard-dev.csr -subj "/C=US/ST=Wisconsin/L=Middleon/O=US Geological Survey/OU=WMA/CN=*"
$ openssl x509 -req -days 9999 -in tomcat-wildcard-dev.csr -signkey tomcat-wildcard-dev.key  -out tomcat-wildcard-dev.crt
$ openssl pkcs12 -export -in tomcat-wildcard-dev.crt -inkey tomcat-wildcard-dev.key -name tomcat -out tomcat.pkcs12 -password pass:changeit
$ keytool -v -importkeystore -deststorepass changeit -destkeystore ./keystore -deststoretype JKS -srckeystore tomcat.pkcs12 -srcstorepass changeit -srcstoretype PKCS12 -noprompt
```
