# Logbash

## Description:
Logbash is a simple log parsing framework using the BASH scripting language/shell and common GNU/Linux tools for searching through raw log files in the command line quick. Many other log searching tools exist but are very complex, difficult to manage, resource intensive (and -- often --expensive). Logbash aims to simplify the searching of logs in the command line in a modular but simple fashion. 

The target platform is Linux and while you could make this easily work on MacOS or Windows (WSL 2) there is no desire to make logbash work out-of-the-box on other platforms. Since logbash is extremely flexible, it would not be difficult at all to modify the relevant shell scripts to get logbash to work on other platforms.


### Use Case:
The imagined scenario is to use a log ingestion service to receive logs, write the log messages to files on disk and then use logbash to retrieve the desired log messages.

Log ingestion services such as [Logstash](https://www.elastic.co/logstash) or [Syslog-ng](https://github.com/syslog-ng/syslog-ng) would be optimal (and free/open source) services that could work well in combination with logbash.

### Organization (Modules and Submodules):
Logbash relies on what are termed "modules" and "submodules" for extensible functionality. Modules consist of a shell script that contains a function named the same as the module. Submodules define the rules that submodules will use to search files.

For example, `modules/linux/linux.sh` contains a function named `linux` that then enumerates all of the submodules in `modules/linux/submodules`. All the `linux` function does is enumerate the submodules in the `submodules` folder and calls on one when it is specified in logbash (or give you a help message if you don't call a submodule). 

This is the way we organized it for our use-case, but you could easily modify the modules to not be restricted to this structure -- they are just BASH scripts, after all.

## Installation:

(As root):

```bash
git clone https://github.com/heywoodlh/logbash /opt/logbash
ln -s /opt/logbash/logbash.sh /usr/bin/logbash
```

## Configuration:

Edit `config.sh` to match the paths to your relevant log files. 

Logbash supports wildcard in the log paths out-of-the-box, but if your logs are huge or you want to optimize for speed it would be recommended to make your wildcards match fewer log sources (based on your logging file name structure). If you don't care then just use all the wildcards you'd like. 

Since `config.sh` is documented with comments, it should be fairly straightforward as to what the variables do.

```bash
❯ cat config.sh

#export linux_log_target="/log/linux/*.log"
#export http_log_target="/log/http/*.log"
#export palo_log_target="/log/palo/*.log"
#export cisco_log_target="/log/cisco/*.log"


## Uncomment default_find_mime_time if you want logbash to default to only search for files modified within a certain time:
#export default_find_mime_time='-1' ## Defaults to one day

## No need to uncomment unless you want to make an exception for specific modules to not use the default find time if you have it set
## You should probably add this variable to the modules you don't want to use default time to search, not in config.sh
#export disable_default_find_mime_time="true"



## Uncomment if you want to disable the --date flag.
## You should probably add this variable to the modules you don't want to use the --date flag, not in config.sh
#export disable_date="true


## Uncomment for minor performance improvements in grep
#export LC_ALL=C
``` 


## Usage:

Once logbash is installed, usage is fairly simple:

```bash
❯ logbash
usage: /usr/bin/logbash [ cisco http linux palo ] [ --tail --date "Jan 01 2020" ]
```

If I want to get help on the `linux` module:
```bash
❯ logbash
usage: /usr/bin/logbash linux [ filebeat ssh ssh-failed-login ] [ --tail --date "Jan 01 2020" ]
```

Finally, if I want to run the `linux ssh` submodule to retrieve all ssh logs:

```bash
❯ logbash linux ssh | grep heywoodlh | tail -1
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

They expect one of two variables be set in the submodule file named `grep_pattern` or `search_command`. For example:

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
