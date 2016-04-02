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
UNIT="c"
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
  local sanity=$(__data_sanity)
  if [ $(__loc_sanity) -le 0 ]; then
    get_location
  fi
  __debug "data sanity is ${sanity}"

  if [ "${sanity}" -gt 0 ]; then
    weather_data=$(__read_tmp_file ${tmp_file})
    __debug "recyclying!!" #${weather_data}
  elif [ "${sanity}" -le 0 ]; then 
    prefix="\"data\""
    suffix="}}"
    local URL="${FORECAST}/${FORECAST_API_KEY}/$TMUX_WEATHER_LOC_LAT,$TMUX_WEATHER_LOC_LON,$(date +%s)"
    __debug "URL is >> ${URL}"
    weather_data=$(curl --max-time 4 -s ${URL})
    # echo $weather_data | sed "s/^$prefix//" #| sed "s/$suffix$//"
    echo ${weather_data} > ${tmp_file}
    export TMUX_WEATHER_DATA_TS="$(date +%s)"
  fi

  echo ${weather_data}
  return
}

generate_segmentrc() {
# read -d '' rccontents  << EORC
# What unit to use. Can be any of {c,f,k}.
  export WEATHER_UNIT="${UNIT}"
}

generate_segmentrc

run_segment() {
	__process_settings
}

__process_settings() {
  if [ -z "$WEATHER_UNIT" ]; then
    export WEATHER_UNIT="${UNIT}"
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
  local sanity=$(__sanity "$TMUX_WEATHER_DATA_TS" ${data_update_period})
  if [ $sanity -gt 1 ]; then
    __fresh ${tmp_file}
    return
  fi
  echo -1
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
  file_size=$(stat -c "%s" ${file_name})
  if [ $file_size -gt 200 ]; then
    echo 1
  fi
  echo -1
  return
}

# get_location
# get_location
# get_data
