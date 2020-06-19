#!/usr/bin/env bash
config_file="./config.sh"
modules_dir="./modules"

source ${config_file}

modules_array=()
for file in ${modules_dir}/*
do
	file="$(basename ${file%.sh}) "
	modules_array+=${file}
done
valid_modules="${modules_array}"

case $1 in
	linux)
        	target="${linux_log_target}"
		source ${modules_dir}/linux.sh
		linux ${target} $2
		eval ${target_cmd}
		;;
        http)
                target="${http_log_target}"
                source ${modules_dir}/http.sh
                http ${target} $2
                eval ${target_cmd}
                ;;
	-h|--help)
		echo "usage: $0 [ $valid_modules ]"
		;;	
	*)
		echo "usage: $0 [ $valid_modules ]"
		;;	
esac
