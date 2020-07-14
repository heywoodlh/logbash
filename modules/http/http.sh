### HTTP log module

http() {
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
		source ${target_file}
	else
		echo "usage: $0 $(basename $1) [ ${valid_submodules}]"
	fi
}
