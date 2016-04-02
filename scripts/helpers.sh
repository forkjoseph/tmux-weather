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
data_update_period=600 # 10 mins
loc_update_period=36000 # 10 hours
update_period=600 # 10 mins
tmp_file="/tmp/.tmux-weather.txt"

# global vars
UNIT="ce"
GEO_PROVIDER="http://ip-api.com/csv"
FORECAST="https://api.forecast.io/forecast"
FORECAST_API_KEY="eb55f102b6683b9af28d4a40abcb69be"
DEBUG=true

get_location() {
  local ts=$TMUX_WEATHER_LOC_TS
  local sanity=$(__loc_sanity)
  __debug "location sanity is ${sanity} ${ts}"

  local lat
  local lon
  if [ "${sanity}" -gt 0 ]; then
    lat=$TMUX_WEATHER_LOC_LAT
    lon=$TMUX_WEATHER_LOC_LON
  elif [ "${sanity}" -le 0 ]; then 
    # either timer expired or DNE
    location_data=$(curl --max-time 4 -s $GEO_PROVIDER)
    # __debug $location_data

    # read as an array
    IFS=',' read -a location_vars <<< "$location_data"
    lat=${location_vars[7]}
    lon=${location_vars[8]}
 
    # cache...
    export TMUX_WEATHER_LOC_TS="$(date +%s)"
  fi

  __debug "Lat:${lat}, Lon:${lon}, TS:${ts}"

  export TMUX_WEATHER_LOC_LAT="${lat}"
  export TMUX_WEATHER_LOC_LON="${lon}"
  return 
}

get_data() {
  local sanity=$(__fresh ${tmp_file})
  # local sanity=$(__data_sanity)
  __debug "data sanity is ${sanity}"

  if [ "${sanity}" -gt 0 ]; then
    weather_data=$(__read_tmp_file ${tmp_file})
    __debug "recyclying!!" ${weather_data}
  elif [ "${sanity}" -le 0 ]; then 
    prefix="\"data\""
    suffix="}}"
    local URL="${FORECAST}/${FORECAST_API_KEY}/$TMUX_WEATHER_LOC_LAT,$TMUX_WEATHER_LOC_LON,$(date +%s)"
    __debug "URL is ${URL}"
    weather_data=$(curl --max-time 4 -s ${URL})
    # echo $weather_data | sed "s/^$prefix//" #| sed "s/$suffix$//"
    echo ${weather_data} > ${tmp_file}
  fi

  echo ${weather_data}
  return
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
  if [ ! -f "$1" ]; then
    return
  fi
  cat "$1"
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

__debug() {
  if test "$DEBUG" = "true"; then
    echo $@
  fi
}

f_to_c() {
  echo "scale=0; (($1 - 32) * 5) / 9" | bc
}

c_to_f() {
  echo "scale=1; (($1 * 9) / 5) + 32" | bc
}

__loc_sanity() {
  __sanity "$TMUX_WEATHER_LOC_TS" ${loc_update_period}
}

__data_sanity() {
  __sanity "$TMUX_WEATHER_DATA_TS" ${data_update_period}
}

__sanity() {
  local last_ts="$1"
  if [ ! -z "$last_ts" ]; then
    time_now=$(date +%s)
    up_to_date=$(echo "(${time_now}-${last_ts}) < $2" | bc)
    echo "${up_to_date}"
  else
    echo -1
  fi
}

# > 0 : time not expired
# = 0 : timer expired
# < 0 : file DNE
__fresh() {
  file_name="$1"
  if [ -f "$file_name" ]; then
    # sanity check...
    last_update=$(stat -c "%Y" ${file_name})
    time_now=$(date +%s)
    up_to_date=$(echo "(${time_now}-${last_update}) < ${update_period}" | bc)
    echo "${up_to_date}"
  else 
    echo -1
  fi
}

# get_location
# get_location
# get_data
