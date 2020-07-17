#!/usr/bin/env bash
target_command="$1"
subcommands="${*:2}"
### Enumerate script location, modules, etc.
rootDir="$(dirname $(realpath $0))"
config_file="${rootDir}/config.sh"
modules_dir="${rootDir}/modules"

#### Parse config file strings literally
set -o noglob
source ${config_file}
set +o noglob

### Arguments after modules
optional_args="--tail --date \"Jan 01 2020\""
while [[ $# -gt 0 ]]; do
	value="$1"
	case ${value} in
		--tail)
			tail=1
			;;
		--date)
			shift
			if [[ disable_date != "true" ]]
			then
				search_date=$1
			fi
			;;
		--date=*)
			if [[ disable_date != "true" ]]
			then
				search_date="${value#*=}"
			fi
			;;
	esac
	shift
done

### Make sure that --tail and --date aren't set at the same time (since you can't tail + follow in the past)
if [[ -n "${search_date}" ]] && [[ -n "${tail}" ]]
then
	echo "Cannot run both --tail and --date arguments."
	error="true"
fi

#### Make sure --date value is correct			
if ! date -d "${search_date}" &> /dev/null
then
	echo "Invalid date passed to --date argument."
	error="true"
fi
####
###


### Enumerate modules in module directory
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

module_dir="${modules_dir}/${target_command}"
module_file="${module_dir}/${target_command}.sh"
###

### Run module
if [[ -f "${module_file}" ]] && [[ ${error} != "true" ]]
then
	source "${module_file}"
	${target_command} ${module_dir} ${subcommands}
else
	echo "usage: $0 [ $valid_modules] [ ${optional_args} ]"
fi
###
