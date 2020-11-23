#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

# function for getting the refresh rate
get_tmux_option() {
  local option=$1
  local default_value=$2
  local option_value=$(tmux show-option -gqv "$option")
  if [ -z $option_value ]; then
    echo $default_value
  else
    echo $option_value
  fi
}

get_percent()
{
	case $(uname -s) in
		Linux)
			# Set HOME to /dev/null to avoid using user's .toprc
			# Use -bn2 and ignore the first iteration to account for top startup
			percent=$(HOME=/dev/null LC_NUMERIC=en_US.UTF-8 top -bn2 | awk '/^top -/ { p=!p } { if (!p) print }' | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
			echo $percent
		;;
		
		Darwin)
			percent=$(ps -A -o %cpu | awk '{s+=$1} END {print s "%"}')
			echo $percent
		;;

		CYGWIN*|MINGW32*|MSYS*|MINGW*)
			# TODO - windows compatability
		;;
	esac
}

main()
{
	while true; do
		# storing the refresh rate in the variable RATE, default is 5
		RATE=$(get_tmux_option "@dracula-refresh-rate" 5)
		cpu_percent=$(get_percent)
		tmux set -g @dracula_cpu_percent "$cpu_percent"
		sleep $RATE
	done
}

TMPDIR="$(dirname $(mktemp -u))"
SOCKET=$(echo $TMUX | cut -d',' -f1 | sed -e 's_.*tmp/__' -e 's~/~_~g')

PIDFILE="$TMPDIR/${SOCKET}-cpu-collect.pid"
if [ -e "$PIDFILE" ]; then
	PID=$(cat "$PIDFILE")
	# Exit if there is already a running cpu collection script.
	kill -0 $PID && exit 0
fi
echo $$ > "$PIDFILE"

cleanup()
{
	rm -f "$PIDFILE"
}
trap cleanup EXIT


# run main driver
main
