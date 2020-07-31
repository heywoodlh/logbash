### palo log module
palo() {
	set -o noglob
	log_target=${palo_log_target}
	set +o noglob
	
	### Enumerate the submodules
	target=$2
	submodules_dir="$1/submodules"
	submodules_array=()
	for file in ${submodules_dir}/*
	do
        	if [[ -f ${file} ]]
       		then
                	file="$(basename ${file}) "
                	submodules_array+=${file}
        	fi
	done
	valid_submodules="${submodules_array}"
	target_file=${submodules_dir}/${target}
	###

	### Execute the submodule
	if [[ -f ${target_file} ]]
	then
		source ${target_file}
		if [[ -n ${grep_pattern} ]] && [[ -n ${tail} ]]
		then
			if [[ ${disable_default_find_time} == "true" ]] && [[ -n ${default_find_mime_time} ]]
			then
				target_array=()
				set +o noglob
				for pattern in ${log_target}
				do
					target_array+="$(find ${pattern} -mtime ${default_find_mime_time}) "
				done
			fi
			if [[ -n ${target_array} ]]
			then
				tail -f ${target_array} -n +1 | grep --line-buffered ${grep_pattern}
			else
				tail -f ${log_target} -n +1 | grep --line-buffered ${grep_pattern}
			fi
		elif [[ -n ${grep_pattern} ]] && [[ -z ${tail} ]] && [[ -z ${search_date} ]]
		then
			if [[ ${disable_default_find_time} == "true"  ]] && [[ -n ${default_find_mime_time} ]]
			then
				target_array=()
				set +o noglob
				for pattern in ${log_target}
				do
					target_array+="$(find ${pattern} -mtime ${default_find_mime_time}) "
				done
			fi
			if [[ -n ${target_array} ]]
			then
				grep ${grep_pattern} ${target_array}
			else
				grep ${grep_pattern} ${log_target}
			fi
		elif [[ -n "${grep_pattern}" ]] && [[ -n ${search_date} ]]
		then
			grep "${grep_pattern}" ${log_target} | grep "${search_date}"
		elif [[ -n ${search_command} ]]
		then
			eval ${search_command}
		fi
	else
		echo "usage: $0 $(basename $1) [ ${valid_submodules}] [ ${optional_args} ]"
	fi
	###
}
