# Logbash

## Description:
Logbash is a simple log parsing framework using the BASH scripting language/shell and common GNU/Linux tools for searching through raw log files in the command line quick. Many other log searching tools exist but are very complex, difficult to manage, resource intensive (and -- often -- expensive). Logbash aims to simplify the searching of logs in the command line in a modular but simple fashion. 

The target platform is Linux and while you could make this easily work on MacOS or Windows (WSL 2) there is no desire to make logbash work out-of-the-box on other platforms. Since logbash is extremely flexible, it would not be difficult at all to modify the relevant shell scripts to get logbash to work on other platforms.


### Use Case:
The imagined scenario is to use a log ingestion service to receive logs, write the log messages to files on disk and then use logbash to retrieve the desired log messages.

View the [syslog-ng example](examples/syslog-ng) directory for an example Docker deployment of syslog-ng that will work well with logbash.

### Organization (Modules and Submodules):
Logbash relies on what are termed "modules" and "submodules" for extensible functionality. Modules consist of a shell script that contains a function named the same as the module. Submodules define the rules that submodules will use to search files.

For example, `modules/linux/linux.sh` contains a function named `linux` that then enumerates all of the submodules in `modules/linux/submodules`. All the `linux` function does is enumerate the submodules in the `submodules` folder and calls on one when it is specified in logbash (or give you a help message if you don't call a submodule). 

This is the way we organized it for our use-case, but you could easily modify the modules to not be restricted to this structure -- they are just BASH scripts, after all.

## Configuration:

```
cp config.sh.example config.sh
```

Edit `config.sh` to match the paths to your relevant log files. If you'd like to set a custom path to `config.sh` use the `LOGBASH_CONFIG` environment variable to specify a path. 

Logbash supports wildcard in the log paths out-of-the-box, but if your logs are huge or you want to optimize for speed it would be recommended to make your wildcards match fewer log sources (based on your logging file name structure). If you don't care then just use all the wildcards you'd like. 

Since `config.sh` is documented with comments, it should be fairly straightforward as to what the variables do -- feel free to open an issue if `config.sh` isn't clear.

### Docker deployment:

The `docker-compose.yml` in this repo contains a fully working reference for syslog-ng and logbash. Deploy like so:

```
cp ./config.sh.example config.sh #edit config.sh as desired
docker compose up -d
```

Then get a shell in the `logbash` container like so:

```
docker compose exec logbash bash
```

The `docker-compose.yml` and its configuration deploys a listener on UDP port 514 for Unifi devices and a TCP listener on port 1514 for Linux servers to forward syslog. For other services, you'll need to add more ports and update the syslog-ng configuration in _./examples/syslog-ng_.

### Deployment in Kubernetes:

Use the following manifest as a reference:

```
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: logbash
  namespace: monitoring
data:
  config.sh: |-
    export linux_log_target="/log/linux/*.log"
    export http_log_target="/log/http/*.log"
    export palo_log_target="/log/palo/*.log"
    export cisco_log_target="/log/cisco/*.log"
    export unifi_log_target="/logs/unifi/*.log"
    export default_find_mime_time='-1' ## Defaults to one day
    #export disable_default_find_mime_time="true"
    #export disable_date="true
    export LC_ALL=C
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: logbash
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: logbash
  template:
    metadata:
      labels:
        app: logbash
    spec:
      hostname: logbash
      containers:
      - name: logbash
        image: docker.io/heywoodlh/logbash:latest
        command: [ "bash", "-c" ]
        args: [ "sleep infinity" ]
        env:
          - name: LOGBASH_CONFIG
            value: "/app/config.sh"
        volumeMounts:
          - mountPath: /logs
            name: logs
          - name: logbash-conf
            mountPath: /app/config.sh
            subPath: config.sh
      volumes:
        - name: logs
          hostPath:
            path: /logs
            type: Directory
        - name: logbash-conf
          configMap:
            name: logbash
            items:
            - key: config.sh
              path: config.sh
```

Once deployed, get a shell in the `logbash` deployment pod to interface with `logbash`.

Below is an incomplete reference for a syslog-ng deployment that would work with logbash

<details>

```
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: syslog-conf
  namespace: monitoring
data:
  # reminder, syslog-ng.conf breaks if you don't append a newline
  syslog-ng.conf: |
    @version: 4.2
    @include "/config/conf.d/*.conf"

  linux.conf: |
    source linux_remote {
      tcp(ip(0.0.0.0) port(1514));
    };
    destination linux_log {
      file(
        "/logs/linux/${YEAR}_${MONTH}_${DAY}.log"
        create-dirs(yes)
      );
    };
    log {
      source(linux_remote);
      destination(linux_log);
    };

  unifi.conf: |
    source unifi_remote {
      udp(ip(0.0.0.0) port(514));
    };
    destination unifi_log {
      file(
        "/logs/unifi/${YEAR}_${MONTH}_${DAY}.log"
        create-dirs(yes)
      );
    };
    log {
      source(unifi_remote);
      destination(unifi_log);
    };

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: syslog
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: syslog
  template:
    metadata:
      labels:
        app: syslog
    spec:
      hostname: syslog
      securityContext:
        fsGroup: 1000
      containers:
      - name: syslog
        image: docker.io/linuxserver/syslog-ng:4.8.1
        env:
          - name: PUID
            value: "1000"
          - name: PGID
            value: "1000"
          - name: LOG_TO_STDOUT
            value: "true"
        ports:
          - name: syslog-0
            containerPort: 514
            protocol: UDP
          - name: syslog-1
            containerPort: 1514
            protocol: TCP
        volumeMounts:
          - mountPath: /logs
            name: logs
          - name: syslog-conf
            mountPath: /config/syslog-ng.conf
            subPath: syslog-ng.conf
          - name: syslog-conf-d
            mountPath: /config/conf.d
          - mountPath: /config
            name: syslog-ng-config-dir # syslog-ng writes to /config a bunch to function
      volumes:
        - name: logs
          hostPath:
            path: /media/data-ssd/syslog
            type: Directory
        - name: syslog-ng-config-dir
          emptyDir:
            sizeLimit: 1Gi
        - name: syslog-conf
          configMap:
            name: syslog-conf
            items:
            - key: syslog-ng.conf
              path: syslog-ng.conf
        - name: syslog-conf-d
          configMap:
            name: syslog-conf
            items:
              - key: linux.conf
                path: linux.conf
              - key: unifi.conf
                path: unifi.conf
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: syslog
  name: syslog
  namespace: monitoring
spec:
  ports:
    - name: syslog-0
      port: 514
      protocol: UDP
      targetPort: syslog-0
    - name: syslog-1
      port: 1514
      protocol: TCP
      targetPort: syslog-1
  selector:
    app: syslog
  type: ClusterIP
```

</details>

## Usage:

Once logbash is deployed, usage is fairly simple:

```bash
❯ logbash
usage: /usr/local/bin/logbash [ cisco http linux palo unifi ] [ --tail --date "Jan 01 2020" ]
```

If I want to get help on the `linux` module:
```bash
❯ logbash linux
usage: /usr/local/bin/logbash linux [ ssh ssh-failed-login ] [ --tail --date "Jan 01 2020" ]
```

Finally, if I want to run the `linux ssh` submodule to retrieve all ssh logs:

```bash
❯ logbash linux ssh
/log/2020.07.16.log:Jul 16 11:12:13 127.0.0.1 sshd[10010]: pam_unix(sshd:session): session closed for user heywoodlh
```

The `--date` argument and `--tail` arguments are optional and cannot be used together.

For example:

```bash
logbash linux ssh --date "Jul 16"
```

Or:

```bash
logbash linux ssh --tail
```

Bonus, to grep while using the `--tail` argument:

```bash
logbash linux ssh --tail | grep --line-buffered heywoodlh
```


## Adding and Removing Modules:

### Removing Modules:

If there are particular modules that you don't find useful just remove their directories from your `modules` folder:

```bash
rm -rf /opt/logbash/modules/cisco
```

### Creating New Modules:

Anyone somewhat comfortable with BASH scripting should be able to add modules and submodules.

To start, copy one of the base modules (we'll use the `linux` module in this example):

```bash
cd modules
cp -r linux custom

cd custom
```

Rename `linux.sh`:

```bash
mv linux.sh custom.sh
```


Then change the stuff related to the `linux` module in `custom.sh`:

```bash
## linux log module
linux() {
        module="linux"
        set -o noglob
        log_target=${linux_log_target}
...
```

Change to:

```bash
## custom log module
custom() {
        module="custom"
        set -o noglob
        log_target=${custom_log_target}
...
```

Make sure that you define the path to your logs in `$custom_log_target` in `config.sh`:

```bash
export custom_log_target=/log/custom/*.log
```

Modify `modules/custom.sh` for any module-specific changes that are needed.

### Adding Submodules:

Modules out-of-the-box expect that submodules be stored in the `submodules` directory of the `module` directory.

For example, the ssh submodule in the linux module has the following path:

```bash
modules/linux/submodules/ssh
```

The modules expect one of two variables be set in the submodule file named `grep_pattern` or `search_command`. For example:

```bash
export grep_pattern="sshd"
```

or 

```bash
export search_command="cat ${log_target} | jq '.message'"
```


The variables should be self explanatory, but here's an explanation anyway:

`grep_pattern`: pattern that `grep` will use to search `$log_target`

`search_command`: custom search command to run 
