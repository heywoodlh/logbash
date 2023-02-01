## Syslog-ng Docker Implementation:

This is an example Syslog-ng implementation that will work well with logbash. If you look at `config/syslog-ng.conf` it simply reads the config files in `config/conf.d` to setup listeners.

## Running:

Assuming your working directory is the same in which `run.sh` is contained, you can run it as is:

```
./run.sh
```

The default setup has two listeners defined in `config/conf.d` named `linux.conf` and `network.conf`. Any logs sent to TCP port 1514 will be considered Linux logs and any logs sent to TCP port 1515 will be considered Network logs.

The default configuration of `run.sh` mounts the `log` directory to `/data` in the container. So all log configurations should place logs in `/data/`.

## More Details:

In this setup, it is expected to have a different port for each service type. Looking at the `config/conf.d/linux.conf` file for example:

```
source linux_remote {
    tcp(ip(0.0.0.0) port(1514));
};

destination linux_log {
    file("/data/linux/${HOST}.${YEAR}.${MONTH}.${DAY}.log");
};

log {
    source(linux_remote);
    destination(linux_log);
};
```

There are three major parts to this config:

`source`: a listener that we have named `linux_remote` will be on TCP port `1514` of the container

`destination`: a log file destination that we have named `linux_log` will output received logs to the following file pattern in the container: `/data/linux/${HOST}.${YEAR}.${MONTH}.${DAY}.log` (for example: `/data/linux/server1.2022.07.22.log`

`log`: configures the `linux_remote` listener to output to the `linux_log` destination. Meaning any logs received on TCP port `1514` on the container will go to `/data/linux/${HOST}.${YEAR}.${MONTH}.${DAY}.log`

### Adding an additional log source:

If you wanted to add another log source on TCP port 1516, which we will refer to as `custom`, you could create a new config in `config/conf.d/custom.conf` with the following content:

```
source custom_remote {
    tcp(ip(0.0.0.0) port(1516));
};

destination custom_log {
    file("/data/custom/${HOST}.${YEAR}.${MONTH}.${DAY}.log");
};

log {
    source(custom_remote);
    destination(custom_log);
};
```

Just make sure to add the new TCP port to `run.sh` to expose it:

```
...
-p 1516:1516 \
...
```
