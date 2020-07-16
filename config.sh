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
