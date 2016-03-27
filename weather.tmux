#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/scripts/helpers.sh"

weather_degree="#($CURRENT_DIR/scripts/weather_degree.sh)"
weather_icon="#($CURRENT_DIR/scripts/weather_icon.sh)"
weather_degree_interpolation="\#{weather_degree}"
weather_icon_interpolation="\#{weather_icon}"

set_tmux_option() {
	local option="$1"
	local value="$2"
	tmux set-option -gq "$option" "$value"
}

do_interpolation() {
	local string="$1"
	local degree_interpolated="${string/$weather_degree_interpolation/$weather_degree}"
	local all_interpolated="${degree_interpolated/$weather_icon_interpolation/$weather_icon}"
	echo "$all_interpolated"
}

update_tmux_option() {
	local option="$1"
	local option_value="$(get_tmux_option "$option")"
	local new_option_value="$(do_interpolation "$option_value")"
	set_tmux_option "$option" "$new_option_value"
}

main() {
	update_tmux_option "status-right"
	update_tmux_option "status-left"
}
main
