#!/bin/bash

sketchybar --set $NAME label="Loading..."

# fetch weather data
LOCATION="Hamburg"
REGION=""
LANG="en"

# Line below replaces spaces with +
LOCATION_ESCAPED="${LOCATION// /+}+${REGION// /+}"
WEATHER_JSON=$(curl -s "https://wttr.in/$LOCATION_ESCAPED?0pq&format=j1&lang=$LANG")

# Fallback if empty
if [ -z $WEATHER_JSON ]; then
  sketchybar --set $NAME label="$LOCATION"
  return
fi

TEMPERATURE=$(echo $WEATHER_JSON | jq '.current_condition[0].temp_C' | tr -d '"')
WEATHER_DESCRIPTION=$(echo $WEATHER_JSON | jq '.current_condition[0].weatherDesc[0].value' | tr -d '"' | sed 's/\(.\{100\}\).*/\1.../')

sketchybar --set $NAME label="$TEMPERATURE$(echo '°')C • $WEATHER_DESCRIPTION"
