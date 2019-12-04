# docker-nifi

This is a simpler version of Nifi Docker image, when compared to the [official image](https://hub.docker.com/r/apache/nifi/). It avoids all the Bash tricks (config generation in runtime via find-and-replace in files, sending proccess to background and other not cool stuff), and instead only assembles Java line command and runs it attached to container original proccess.

Configuration files included in the image are the ones shipped along with the official package. All user custom configuration must be made via Docker volumes.

Nifi's files are under `/opt/nifi/nifi-current`, so default path for configuration files is `/opt/nifi/nifi-current/conf`.

The only and few enviroment variables accepted by this image are:

- `JVM_HEAP_INIT` - JVM minimum heap size (`-Xms`)
- `JVM_HEAP_MAX`  - JVM maximum heap size (`-Xmx`)
- `JAVA_OPTS` - JVM extra options

## Custom configuration

NiFi's configuration is very complex, consisting of many separate file in more than a single format. So, providing pre-defined enviroment variables for every options and scenario is nearly impossible (specially when considering structured files like XMLs.)

Yet, in order to leverage the deployment possibilies of this image, without depending exclusively on static configuration, an alternative is provided.

You can provide config-file templates to be rendered at runtime by the image's entrypoint script. The advantage of it is to use user-defined enviroment variables, which may contain sensitive information, and let this to be  interpolated in runtime, instead of leaving this content statically set. Besides it, users can provided their own template sets, which would take a given set of pre-defined enviroment variables for any scenarios, without having to modify the actual Docker image.

All files with extension `.tpl` found in `opt/nifi/nifi-current/conf` will be rendered (output to the same path, with the same name without `.tpl` extension).

The image uses [*gomplate*](https://docs.gomplate.ca/) to interpolate templates, so they must be in [*Go Template*](https://golang.org/pkg/text/template/) format.

For example:

A template named _zookeeper.properties.tpl_ ...
```
server.1=node1.{{ .Env.MYDOMAIN }}:2888:3888;2181
server.2=node2.{{ .Env.MYDOMAIN }}:2888:3888;2181
server.3=node3.{{ .Env.MYDOMAIN }}:2888:3888;2181
```

... could be passed to container as ...
```
docker run --rm --name nifi -p 8443:8443 -p 8080:8080 -p 8000:8000 -v ${PWD}/zookeeper.properties.tpl:/opt/nifi/nifi-current/cof/zookeeper.properties.tpl -e MYDOMAIN=foo.bar nifi
```

... resulting in the following output ...
```
Generated config file from template in /opt/nifi/nifi-current/conf/zookeeper.properties
```
