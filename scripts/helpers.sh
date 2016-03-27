#!/usr/bin/env bash
# 
# get_location: detects your location, returns (lat, lon)
# get_data: get data from FORECAST.io, returns (json)
# parse_data: parses data, returns (icon, degree)
#
# note: 
# - degree: set UNIT="american" or UNIT="ce" (Fahrenheits vs Celsius)
# - API_KEY: use mine or just get one from http://forecast.io
# - period: set $update_period to adjust caching period

# The update period in seconds.
update_period=600 # 10 mins
tmp_file="/tmp/.tmux-weather.txt"

# global vars
GEO_PROVIDER="http://ip-api.com/csv"
FORECAST="https://api.forecast.io/forecast"
FORECAST_API_KEY="eb55f102b6683b9af28d4a40abcb69be"

TMUX_POWERLINE_SEG_WEATHER_DATA_PROVIDER_DEFAULT="yahoo"
TMUX_POWERLINE_SEG_WEATHER_UNIT_DEFAULT="c"
TMUX_POWERLINE_SEG_WEATHER_UPDATE_PERIOD_DEFAULT="600" # 10 mins
# TMUX_POWERLINE_SEG_WEATHER_UPDATE_PERIOD_DEFAULT="6" # 10 mins
TMUX_POWERLINE_SEG_WEATHER_GREP_DEFAULT="grep"
# TMUX_POWERLINE_SEG_WEATHER_LOCATION_DEFAULT="12770746" # Atlanta
TMUX_POWERLINE_SEG_WEATHER_LOCATION_DEFAULT="2354842" # Ann Arbor



get_location() {
	if [ -f "$tmp_file" ]; then
    last_update=$(stat -c "%Y" ${tmp_file})
		time_now=$(date +%s)
		up_to_date=$(echo "(${time_now}-${last_update}) < ${update_period}" | bc)
		if [ "$up_to_date" -eq 1 ]; then
      weather_data=$(__read_tmp_file)
      # echo "recyclying!!"
      echo $weather_data
		fi
	fi
  if [ -z "$weather_data" ]; then
    location_data=$(curl --max-time 4 -s $GEO_PROVIDER)
    IFS=',' read -a location_vars <<< "$location_data"

    lat=${location_vars[7]}
    lon=${location_vars[8]}
    # echo "$lat,$lon"
    degree=$(get_data $lat $lon)
    echo $degree > ${tmp_file}
    weather_data=$degree
    echo $degree
  fi
}

get_data() {    
  lat=$1
  lon=$2

  prefix="\"data\""
  suffix="}}"
  weather_data=$(curl --max-time 4 -s \
    "${FORECAST}/${FORECAST_API_KEY}/$lat,$lon,$(date +%s)")

  # echo $weather_data | sed "s/^$prefix//" #| sed "s/$suffix$//"

  IFS=',' read -a weather_vars <<< "$weather_data"
  len=${#weather_vars[@]}
    
  bool_degree=false
  bool_icon=false

  for (( i=0; i<${len}; i++ )); do
    string=${weather_vars[$i]}
    if [[ $string == *"temperature"* ]] || [[ $string == *"icon"* ]]; then
      if test "$bool_icon" = "false"; then
        prefix='\"icon\":'
        icon=${string#$prefix}
        bool_icon=true
      elif test "$bool_degree" = "false"; then
        prefix='\"temperature\":'
        fa=${string#$prefix}
        degree=$(f_to_c $fa)
        bool_degree=true
      fi
    fi
  done
  echo $icon $degree
}

f_to_c() {
  echo "scale=1; (($1 - 32) * 5) / 9" | bc
}

c_to_f() {
  echo "scale=1; (($1 * 9) / 5) + 32" | bc
}

generate_segmentrc() {
	# read -d '' rccontents  << EORC
  export TMUX_POWERLINE_SEG_WEATHER_DATA_PROVIDER="${TMUX_POWERLINE_SEG_WEATHER_DATA_PROVIDER_DEFAULT}"
# What unit to use. Can be any of {c,f,k}.
  export TMUX_POWERLINE_SEG_WEATHER_UNIT="${TMUX_POWERLINE_SEG_WEATHER_UNIT_DEFAULT}"
  export WEATHER_UNIT="${TMUX_POWERLINE_SEG_WEATHER_UNIT}"
# How often to update the weather in seconds.
  export TMUX_POWERLINE_SEG_WEATHER_UPDATE_PERIOD="${TMUX_POWERLINE_SEG_WEATHER_UPDATE_PERIOD_DEFAULT}"
# Name of GNU grep binary if in PATH, or path to it.
  export TMUX_POWERLINE_SEG_WEATHER_GREP="${TMUX_POWERLINE_SEG_WEATHER_GREP_DEFAULT}"
# Your location. Find a code that works for you:
# 1. Go to Yahoo weather http://weather.yahoo.com/
# 2. Find the weather for you location
# 3. Copy the last numbers in that URL. e.g. "http://weather.yahoo.com/united-states/california/newport-beach-12796587/" has the numbers "12796587"
  export TMUX_POWERLINE_SEG_WEATHER_LOCATION="${TMUX_POWERLINE_SEG_WEATHER_LOCATION_DEFAULT}"
# EORC
}

generate_segmentrc

run_segment() {
	__process_settings
  local tmp_file="/tmp/weather_yahoo.txt"
	local weather
	case "$TMUX_POWERLINE_SEG_WEATHER_DATA_PROVIDER" in
		"yahoo") weather=$(__yahoo_weather) ;;
		*)
			echo "Unknown weather provider [${$TMUX_POWERLINE_SEG_WEATHER_DATA_PROVIDER}]";
			return 1
	esac
	if [ -n "$weather" ]; then
		echo "$weather"
	fi
}

__process_settings() {
	if [ -z "$TMUX_POWERLINE_SEG_WEATHER_DATA_PROVIDER" ]; then
		export TMUX_POWERLINE_SEG_WEATHER_DATA_PROVIDER="${TMUX_POWERLINE_SEG_WEATHER_DATA_PROVIDER_DEFAULT}"
	fi
	if [ -z "$TMUX_POWERLINE_SEG_WEATHER_UNIT" ]; then
		export TMUX_POWERLINE_SEG_WEATHER_UNIT="${TMUX_POWERLINE_SEG_WEATHER_UNIT_DEFAULT}"
	fi
	if [ -z "$TMUX_POWERLINE_SEG_WEATHER_UPDATE_PERIOD" ]; then
		export TMUX_POWERLINE_SEG_WEATHER_UPDATE_PERIOD="${TMUX_POWERLINE_SEG_WEATHER_UPDATE_PERIOD_DEFAULT}"
	fi
	if [ -z "$TMUX_POWERLINE_SEG_WEATHER_GREP" ]; then
		export TMUX_POWERLINE_SEG_WEATHER_GREP="${TMUX_POWERLINE_SEG_WEATHER_GREP_DEFAULT}"
	fi
  export TMUX_POWERLINE_SEG_WEATHER_LOCATION="12770746"
	if [ -z "$TMUX_POWERLINE_SEG_WEATHER_LOCATION" ]; then
		echo "No weather location specified.";
		exit 8
	fi
}

__read_tmp_file() {
	if [ ! -f "$tmp_file" ]; then
		return
	fi
	cat "${tmp_file}"
	exit
}

get_tmux_option() {
	local option="$1"
	local default_value="$2"
	local option_value="$(tmux show-option -gqv "$option")"
	if [ -z "$option_value" ]; then
		echo "$default_value"
	else
		echo "$option_value"
	fi
}

command_exists() {
	local command="$1"
	type "$command" >/dev/null 2>&1
}

get_location
