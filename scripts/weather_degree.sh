#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/helpers.sh"

parse_data() {
  DEBUG=false
  location=$(get_location)
  weather_data=$(get_data)

  # error=$(echo "$weather_data" | grep "error");
  # if [ -n "$error" ]; then
  #   rm -f ${tmp_location} ${tmp_file}
  #   echo "error"
  #   exit 1
  # fi

  IFS=',' read -a weather_vars <<< "$weather_data"
  len=${#weather_vars[@]}
    
  bool_degree=false
  for (( i=0; i<${len}; i++ )); do
    string=${weather_vars[$i]}
    if [[ $string == *"temperature"* ]]; then
      if test "$bool_degree" = "false"; then
        prefix='\"temperature\":'
        fa=${string#$prefix}
        if [[ ${WEATHER_UNIT} == "american" ]] || [[ ${WEATHER_UNIT} == "f" ]] || [[ ${WEATHER_UNIT} == "F" ]] ; then
          degree=${fa}
        elif [[ ${WEATHER_UNIT} == "ce" ]] || [[ ${WEATHER_UNIT} == "c" ]] || [[ ${WEATHER_UNIT} == "C" ]]; then
          degree=$(f_to_c $fa)
        else 
          echo "UNIT(${WEATHER_UNIT}) is wrong!"
          exit 1
        fi
        bool_degree=true
      fi
    fi
  done
  __debug "degree is ${degree}"
  echo "${degree}°$(echo "$WEATHER_UNIT" | tr '[:lower:]' '[:upper:]')"
}

parse_data

