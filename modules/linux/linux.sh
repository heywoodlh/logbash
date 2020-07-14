### Linux log module
linux() {
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
	if [[ -f ${target_file} ]]
	then
		echo "-------------------------"
		echo "Linux ${target} logs"
		echo "-------------------------"
		source ${target_file}
		if [[ -n "${grep_pattern}" ]]
		then
			grep ${grep_pattern} ${linux_log_target}
		elif [[ -n "${search_command}" ]]
		then
			${search_command}
		fi	
	else
		echo "usage: $0 $(basename $1) [ ${valid_submodules}]"
	fi
}
