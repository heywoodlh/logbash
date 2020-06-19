### Linux log module

linux() {
	target="$1"
	valid_submodules="ssh ssh-failed-login"
	case $2 in
		ssh)
			echo "-------------------------"
			echo "Linux ssh logs"
			echo "-------------------------"
			export target_cmd="grep -R sshd ${target}"
			;;
		ssh-failed-login)
			echo "-------------------------"
			echo "Linux ssh failure logs"
			echo "-------------------------"
			export target_cmd="grep -R -e 'sshd.*Failed password' -e 'sshd.*Invalid verification code' -e 'sshd.*invalid user' ${target}"
			;;
		--help)	
			echo "usage: $0 linux [ ${valid_submodules} ]"
			;;
		*)	
			echo "usage: $0 linux [ ${valid_submodules} ]"
			;;
	esac
}
