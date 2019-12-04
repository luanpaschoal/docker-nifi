# docker-nifi

This is a *vanilla* [NiFi](https://nifi.apache.org/) *Docker* image, much simpler than the [official one](https://hub.docker.com/r/apache/nifi/). It avoids all those *Bash* tricks - config generation in runtime via *find-and-replace* in files, proccess sent to background and other not cool stuff - and, instead, only assembles *Java* line command and runs the proccess directly attached to the container.

Configuration files included in this image are the ones shipped along with the official package, so **all user custom configuration must be exported via *Docker* volumes**. (Or, yet, this image could be used as a base for more specific ones.)

*NiFi* installation is under `/opt/nifi/nifi-current`, and default configuration files are under `/opt/nifi/nifi-current/conf`. See [the official documentation](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html) for details about how to setup *NiFi*.

The only and few enviroment variables accepted by this image are:

- `JVM_HEAP_INIT` - JVM minimum heap size (`-Xms`)
- `JVM_HEAP_MAX`  - JVM maximum heap size (`-Xmx`)
- `JAVA_OPTS` - JVM extra options

**This image does not use _NiFi Bootstrapper_**.

## Custom configuration

*NiFi* configuration is very complex, consisting of many separate files in more than one format. So, providing pre-defined enviroment variables for every possible scenario is nearly impossible (specially when considering structured files like *XML*.)

The most simple way to set your own configuration would be to present files via volumes (inside container's path `/opt/nifi/nifi-current/conf`).

### Dynamic configuration via templates

Yet, in order to leverage the deployment possibilities of this image, without depending exclusively on static configuration, an alternative is available.

It is possible to provide configuration file templates to be rendered at *runtime* by image's *entrypoint* script. The advantage of this method is to able to provide some parameters via (user-defined) enviroment variables - which may contain sensitive information or that varies quite frequently - letting them to be interpolated in every time a container is created, instead of hardcoding those values in files. This empowers users so they can write their own template sets, along with pre-defined enviroment variables for their own scenarios, almost like a _"configuration flavor"_ - all this without having to modify the actual image. [Helm charts](https://helm.sh/docs/topics/charts/) can be useful for that.

All files with extension `.tpl` found in `opt/nifi/nifi-current/conf` will be rendered before the application is started - they will be output to the same path, with the same name (without the `.tpl` extension).

The image uses [*gomplate*](https://docs.gomplate.ca/) to render templates, so **.tpl files must be in [*Go Template*](https://golang.org/pkg/text/template/) format**.

For example:

A template named `zookeeper.properties.tpl` ...
```
server.1=node1.{{ .Env.MYDOMAIN }}:2888:3888;2181
server.2=node2.{{ .Env.MYDOMAIN }}:2888:3888;2181
server.3=node3.{{ .Env.MYDOMAIN }}:2888:3888;2181
```

... could be passed to container as volumed file along with `MYDOMAIN` enviroment variable (like below) ...
```
docker run -e MYDOMAIN=foo.bar -v ${PWD}/zookeeper.properties.tpl:/opt/nifi/nifi-current/cof/zookeeper.properties.tpl -p 8443:8443 -p 8080:8080 -p 8000:8000 nifi
```

... resulting in a file named `zookeeper.properties` with the following content:
```
server.1=node1.foo.bar:2888:3888;2181
server.2=node2.foo.bar:2888:3888;2181
server.3=node3.foo.bar:2888:3888;2181
```

The *entrypoint* scripts points out every interpolated file in container startup log, like:
```
Generated config file from template in /opt/nifi/nifi-current/conf/zookeeper.properties
```
