# docker-nifi

This is a *vanilla* [NiFi](https://nifi.apache.org/) Docker image, much simpler than the [official one](https://hub.docker.com/r/apache/nifi/). It avoids all those *Bash* tricks - config generation in runtime via *find-and-replace* in files, proccess sent to background and other not cool stuff - and, instead, only assembles Java line command and runs the proccess directly attached to the container.

Configuration files included in this image are the ones shipped along with the official package. All user custom configuration must be made via Docker volumes.

NiFi's files are under `/opt/nifi/nifi-current`, so the default path for configuration files is `/opt/nifi/nifi-current/conf`.

The only and few enviroment variables accepted by this image are:

- `JVM_HEAP_INIT` - JVM minimum heap size (`-Xms`)
- `JVM_HEAP_MAX`  - JVM maximum heap size (`-Xmx`)
- `JAVA_OPTS` - JVM extra options

## Custom configuration

NiFi's configuration is very complex, consisting of many separate files in more than one format. So, providing pre-defined enviroment variables for every possible scenario is nearly impossible (specially when considering structured files like XMLs.)

Yet, in order to leverage the deployment possibilities of this image, without depending exclusively on static configuration, an alternative is available.

You can provide config file templates to be rendered at *runtime* by image's *entrypoint* script. The advantage of this method is to able to provide some parameters via (user-defined) enviroment variables - which may contain sensitive information or that varies quite frequently - letting them to be interpolated in runtime, instead of hardcoding those values in files. Besides it, users can write their own template sets, along with pre-defined enviroment variables for specific scenarios, almost like a _"configuration flavor"_, all this without having to modify the actual Docker image.

All files with extension `.tpl` found in `opt/nifi/nifi-current/conf` will be rendered before the application is started - they will be output to the same path, with the same name (only without the `.tpl`).

The image uses [*gomplate*](https://docs.gomplate.ca/) to interpolate templates, so **template must be in [*Go*](https://golang.org/pkg/text/template/) format**.

For example:

A template named _zookeeper.properties.tpl_ ...
```
server.1=node1.{{ .Env.MYDOMAIN }}:2888:3888;2181
server.2=node2.{{ .Env.MYDOMAIN }}:2888:3888;2181
server.3=node3.{{ .Env.MYDOMAIN }}:2888:3888;2181
```

... could be passed to container as volumed file (like below) ...
```
docker run --rm --name nifi -p 8443:8443 -p 8080:8080 -p 8000:8000 -v ${PWD}/zookeeper.properties.tpl:/opt/nifi/nifi-current/cof/zookeeper.properties.tpl -e MYDOMAIN=foo.bar nifi
```

... resulting in the following output ...
```
server.1=node1.foo.bar:2888:3888;2181
server.2=node2.foo.bar:2888:3888;2181
server.3=node3.foo.bar:2888:3888;2181
```

Its interpolation will be informed in container startup log, like:
```
Generated config file from template in /opt/nifi/nifi-current/conf/zookeeper.properties
```
