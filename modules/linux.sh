### Linux log module

linux() {
	target="$1"
	valid_submodules="ssh sudo audit"
	case $2 in
		ssh)
			echo "-------------------------"
			echo "Linux ssh logs"
			echo "-------------------------"
			grep_params="sshd"
			export target_cmd="grep -R ${grep_params} ${target}"
			;;
		--help)	
			echo "usage: $0 [${valid_submodules}]"
			;;
		*)	
			echo "usage: $0 [${valid_submodules}]"
			;;
	esac
}
