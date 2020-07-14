#!/usr/bin/env bash
rootDir="$(dirname $(realpath $0))"

config_file="${rootDir}/config.sh"
modules_dir="${rootDir}/modules"

source ${config_file}

modules_array=()
for file in ${modules_dir}/*
do
	if [[ -d ${file} ]]
	then
		file="$(basename ${file}) "
		modules_array+=${file}
	fi
done
valid_modules="${modules_array}"

target_command="$1"
subcommands="${*:2}"

module_dir="${modules_dir}/${target_command}"
module_file="${module_dir}/${target_command}.sh"

if [[ -f "${module_file}" ]]
then
	source "${module_file}"
	${target_command} ${module_dir} ${subcommands}
else
	echo "usage: $0 [ $valid_modules]"
fi
