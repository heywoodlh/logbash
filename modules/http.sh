### HTTP log module

http() {
	target="$1"
	valid_submodules="200"
	case $2 in
		200)
			echo "-------------------------"
			echo "HTTP 200 code access logs"
			echo "-------------------------"
			export target_cmd="grep -R -E 'HTTP.*200' ${target}"
			;;
		--help)	
			echo "usage: $0 [${valid_submodules}]"
			;;
		*)	
			echo "usage: $0 [${valid_submodules}]"
			;;
	esac
}
