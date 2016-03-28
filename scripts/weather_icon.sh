#!/usr/bin/env bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CURRENT_DIR/helpers.sh"

# condition_symbol=$(__get_condition_symbol "$condition" "$sunrise" "$sunset") 
__get_condition_symbol() {
  DEBUG=false
  location=$(get_location)
  weather_data=$(get_data ${location})

  IFS=',' read -a weather_vars <<< "$weather_data"
  len=${#weather_vars[@]}

  bool_icon=false
  for (( i=0; i<${len}; i++ )); do
    string=${weather_vars[$i]}
    if test "$bool_icon" = "false"; then
      if [[ $string == *"icon"* ]]; then
        prefix='\"icon\":\"'
        suffix='\"'
        icon_str=${string#$prefix}
        icon_str=${icon_str%$suffix}
        bool_icon=true
      fi
    fi
  done

  __debug ${icon_str}
   
  # supported:
  # clear-day, clear-night, rain, snow, sleet, wind, fog, cloudy,
  # partly-cloudy-day, or partly-cloudy-night
  case $icon_str in
    "sunny" | "hot")
      hourmin=$(date +%H%M)
      if [ "$hourmin" -ge "$sunset" -o "$hourmin" -le "$sunrise" ]; 
      then
        # echo "☽"
        echo "☾"
      else
        # echo "☀"
        echo "☼"
      fi
      ;;
    "rain" | "mixed rain and snow" | "mixed rain and sleet" | "freezing drizzle" | "drizzle" | "light drizzle" | "freezing rain" | "showers" | "mixed rain and hail" | "scattered showers" | "isolated thundershowers" | "thundershowers" | "light rain with thunder" | "light rain" | "rain and snow")
      # echo "☂"
      echo "☔"
      ;;
    "snow" | "mixed snow and sleet" | "snow flurries" | "light snow showers" | "blowing snow" | "sleet" | "hail" | "heavy snow" | "scattered snow showers" | "snow showers" | "light snow" | "snow/windy" | "snow grains" | "snow/fog")
      # echo "☃"
      echo "❅"
      ;;
    "cloudy" | "mostly cloudy" | "partly cloudy" | "partly cloudy/windy" | "partly-cloudy-day" | "partly-cloudy-night")
      echo "☁"
      ;;
    "tornado" | "tropical storm" | "hurricane" | "severe thunderstorms" | "thunderstorms" | "isolated thunderstorms" | "scattered thunderstorms")
      # echo "⚡"
      echo "☈"
      ;;
    "dust" | "foggy" | "fog" | "haze" | "smoky" | "blustery" | "mist")
      # echo "♨"
      # echo "﹌"
      echo "〰"
      ;;
    "windy" | "fair/windy" | "wind")
      # echo "⚐"
      echo "⚑"
      ;;
    "clear" | "fair" | "cold" | "clear-day" | "clear-night")
      hourmin=$(date +%H%M)
      if [ "$hourmin" -ge "$sunset" -o "$hourmin" -le "$sunrise" ]; 
      then
        echo "☾"
      else
        echo "〇"
      fi
      ;;
    *)
      echo "?$icon_str"
      ;;
  esac
}


main() {
  __get_condition_symbol
}

main
