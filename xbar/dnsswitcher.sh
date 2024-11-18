#!/usr/bin/env bash
#
# DNS Switcher
# The list of DNS options should be defined on this file
#
# <xbar.title>DNS Switcher</xbar.title>
# <xbar.version>v0.1</xbar.version>
# <xbar.author>Neo Ighodaro</xbar.author>
# <xbar.author.github>neoighodaro</xbar.author.github>
# <xbar.desc>Switch DNS to your defined DNS options.</xbar.desc>

# DNS Addresses
# ------------------------------------------------------------------------------
## Default DNS
default="empty"

## Pi-hole
pihole="192.168.0.3"

## Cloudflare
cloudflare="1.1.1.1 1.0.0.1"

# Configuration
# ------------------------------------------------------------------------------
## Network Service
network_service="Wi-Fi"

## Enabled DNS Addresses
enabled_dns_address=(pihole cloudflare default)

# Script
# ------------------------------------------------------------------------------
## Selected DNS
selected_dns="Unknown"

## Current DNS Output
current_dns_output="$(networksetup -getdnsservers $network_service)"

## If current DNS output is "There aren't any DNS Servers set on Wi-Fi."
if [[ $current_dns_output == There* ]] # For e.g. "There aren't any DNS Servers set on Wi-Fi."
then
    selected_dns="Default"
else
    IFS=', ' read -r -a current_dns_address <<< "$current_dns_output"

    for dns_name in "${enabled_dns_address[@]}"
    do
        for current_dns in "${current_dns_address[@]}"
        do
        dns_option="$(eval echo \$"${dns_name}" | xargs)"
            if [[ $dns_option == *"$current_dns"* ]]
            then
                selected_dns="$dns_name"
            fi
        done
    done
fi

default_icon="PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyB3aWR0aD0iMThweCIgaGVpZ2h0PSIxOHB4IiB2aWV3Qm94PSIwIDAgMTggMTgiIHZlcnNpb249IjEuMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayI+CiAgICA8dGl0bGU+QXJ0Ym9hcmQ8L3RpdGxlPgogICAgPGcgaWQ9IkFydGJvYXJkIiBzdHJva2U9Im5vbmUiIHN0cm9rZS13aWR0aD0iMSIgZmlsbD0ibm9uZSIgZmlsbC1ydWxlPSJldmVub2RkIj4KICAgICAgICA8cmVjdCBmaWxsPSIjRkZGRkZGIiBvcGFjaXR5PSIwIiB4PSIwIiB5PSIwIiB3aWR0aD0iMTgiIGhlaWdodD0iMTgiPjwvcmVjdD4KICAgICAgICA8ZyBpZD0id2Fybi1zdmdyZXBvLWNvbSIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMiwgMikiIGZpbGw9IiMwMDAwMDAiIGZpbGwtcnVsZT0ibm9uemVybyI+CiAgICAgICAgICAgIDxwYXRoIGQ9Ik03LDAgQzguMjYsMCA5LjQyNjY2NjY3LDAuMzE1IDEwLjUsMC45NDUgQzExLjU3MzMzMzMsMS41NzUgMTIuNDI1LDIuNDI2NjY2NjcgMTMuMDU1LDMuNSBDMTMuNjg1LDQuNTczMzMzMzMgMTQsNS43NCAxNCw3IEMxNCw4LjI2IDEzLjY4NSw5LjQyNjY2NjY3IDEzLjA1NSwxMC41IEMxMi40MjUsMTEuNTczMzMzMyAxMS41NzMzMzMzLDEyLjQyNSAxMC41LDEzLjA1NSBDOS40MjY2NjY2NywxMy42ODUgOC4yNiwxNCA3LDE0IEM1Ljc0LDE0IDQuNTczMzMzMzMsMTMuNjg1IDMuNSwxMy4wNTUgQzIuNDI2NjY2NjcsMTIuNDI1IDEuNTc1LDExLjU3MzMzMzMgMC45NDUsMTAuNSBDMC4zMTUsOS40MjY2NjY2NyAwLDguMjYgMCw3IEMwLDUuNzQgMC4zMTUsNC41NzMzMzMzMyAwLjk0NSwzLjUgQzEuNTc1LDIuNDI2NjY2NjcgMi40MjY2NjY2NywxLjU3NSAzLjUsMC45NDUgQzQuNTczMzMzMzMsMC4zMTUgNS43NCwwIDcsMCBaIE01Ljg4LDMuMDggTDUuODgsNy41NiBMOC4xMiw3LjU2IEw4LjEyLDMuMDggTDUuODgsMy4wOCBaIE01Ljg4LDguNjggTDUuODgsMTAuOTIgTDguMTIsMTAuOTIgTDguMTIsOC42OCBMNS44OCw4LjY4IFoiIGlkPSJTaGFwZSI+PC9wYXRoPgogICAgICAgIDwvZz4KICAgIDwvZz4KPC9zdmc+"
pihole_icon="iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAYAAADhAJiYAAAAAXNSR0IArs4c6QAAAAlwSFlzAAAWJQAAFiUBSVIk8AAAActpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDUuNC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDx4bXA6Q3JlYXRvclRvb2w+d3d3Lmlua3NjYXBlLm9yZzwveG1wOkNyZWF0b3JUb29sPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KGMtVWAAAA2dJREFUWAnFlluITWEUx4dmGPdcHlA8yClK1MyTS03G0xByV5TEeCKKlAYRkoaUJ0Lz4FbkUngwNC8uDUoI5TrRFHIZzCAzZvj92auWbZ8znLPPmVW/+da3vvWtteY7a3975+W1Lz3bd8mdxwlS/YDPcArKoEOliewqyHOReaKjqqoNFWOFNWDvkNNakqQgFdYMpZBM1HtFUJDMIR27gt0FO5nw+I61QaHA3Zjvhq8g/+MQqxQTzYKHC9J8u8tWiH4VvN8ltx6buohIbaFElvSey7IuwmeBW49VXUG0qKJkGwz6eevBCtVYDVmVWUT/AD6pdPXMypD9BvP+kHUZSIZKuA/fIVycLtEq6AU5FxV3EHxRi3NehUvYGX0M+N56xVyF5lTUwFvgPfjTMf0m9u6QE1GjXgFLrvEyqLEbnP08ehfIquhW1r1jxXxD13VgkkB5CbZ+Bl2nmRXRyejJsmSv0SdEZJrjfOR7EmIvSv3g3/yfmI+FKJmJUYWcDkbp+q7Kh1ikE1H0grST8eND7AdgFSwD9VEjnIO54H2PMddTmbFUEMECP0CfDuWgYsweHieytjdifSu2jEQ/Swv4hK3Mj4DeXypM945f1ymp3z6CPl1GwnOQj+4rnVxa0pVdT0CB3sAG0Ju7BmR7Ckqs/poNq6EEJCpKPvamnxfMZXsLA+C/ZS07FEAooMk4FLNvMqMbh6E3g3yGBHb1of+J9wT2v4ZUTbbUeT9zuj7WTBKmuFGnUhDMdSdJVNy1X9rvPzOc/oeaqiDvOMpNRjj9kdNNHW4KY6HTeztd/RUpqQqqcjumOl0Xn0SfHmrusOinMRkfKP0YJ5mRcb/T/1nVf1cHOm49HWrqzcFctn2gd9VOeAxnQTd3X9DJyecFrIHrwVw2+ab9jiths05CgTyNzPWJsStkV+Fq2KFwCFrB72throciI9nIbh9U+jYohXBC86tnbT2UQx2YvQI9Y9EjexQsqEZdmLq1lXgK9IA+MB/0M3lf0w9jV6xYRJdkDVhwff9IXw5hWYjB/GzUXsWIVXQKvigl2xGRIdxX2qO9WRG9JqrB/vMm9CKXqRj9i1u/gK49WZV8ousU2kCF6bt6WoB9Y2utEuSbM5lMpttgp2XjLWxl6VaRaddrv5640UEBdxhrQcWlJT8BdaxGflEnmuwAAAAASUVORK5CYII=="
cloudflare_icon="PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyB3aWR0aD0iMThweCIgaGVpZ2h0PSIxOHB4IiB2aWV3Qm94PSIwIDAgMTggMTgiIHZlcnNpb249IjEuMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayI+CiAgICA8dGl0bGU+QXJ0Ym9hcmQ8L3RpdGxlPgogICAgPGcgaWQ9IkFydGJvYXJkIiBzdHJva2U9Im5vbmUiIHN0cm9rZS13aWR0aD0iMSIgZmlsbD0ibm9uZSIgZmlsbC1ydWxlPSJldmVub2RkIj4KICAgICAgICA8cmVjdCBmaWxsPSIjRkZGRkZGIiBvcGFjaXR5PSIwIiB4PSIwIiB5PSIwIiB3aWR0aD0iMTgiIGhlaWdodD0iMTgiPjwvcmVjdD4KICAgICAgICA8ZyBpZD0iY2xvdWRzLXN2Z3JlcG8tY29tIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSgtMCwgMy40NzUpIiBmaWxsPSIjMDAwMDAwIiBmaWxsLXJ1bGU9Im5vbnplcm8iPgogICAgICAgICAgICA8cGF0aCBkPSJNMTIuMTA2MjMwNSwxLjU3OTQzMjcyIEM4Ljk0NjgwODU5LC0xLjUxNDMxNzI4IDMuNTk0Nzk2ODgsMC4xODMzMDc3MjQgMi44MDM5NTcwMyw0LjUzMDYyNDEzIEMxLjIyMDI3MzQ0LDQuNzYwMzM1MDcgMCw2LjEyNjk5OTEzIDAsNy43NzMzMzExNiBDMCw5LjU4MDExNjMyIDEuNDY5OTE3OTcsMTEuMDUwMDM0MyAzLjI3NjcwMzEyLDExLjA1MDAzNDMgTDEzLjIwMTY5OTIsMTEuMDUwMDM0MyBDMTUuODQ3NDg4MywxMS4wNTAwMzQzIDE3Ljk5OTk2NDgsOC44OTc1NTc3MiAxNy45OTk5NjQ4LDYuMjUxODAzODIgQzE3Ljk5OTk2NDgsMy4xNzgxMjgwNCAxNS4xMjcxNzE5LDAuODczMjEzOTc0IDEyLjEwNjIzMDUsMS41Nzk0MzI3MiBaIiBpZD0iUGF0aCI+PC9wYXRoPgogICAgICAgIDwvZz4KICAgIDwvZz4KPC9zdmc+"

# Bitbar Menu
# ------------------------------------------------------------------------------
if [[ $selected_dns == "Unknown" ]]
then
    echo "Unrecognized DNS"
else
    if [[ $selected_dns == "pihole" ]]; then
        echo " | templateImage=$pihole_icon"
    elif [[ $selected_dns == "cloudflare" ]]; then
        echo " | templateImage=$cloudflare_icon"
    else
        echo " | templateImage=$default_icon"
    fi
fi

echo "---"

tmp_dir="/tmp"
for dns_name in "${enabled_dns_address[@]}"
do
  switcher="$tmp_dir/bitbar_dns_switcher_${dns_name}"
  cat <<EOF > "$switcher"
dns_address='$(eval "echo \${${dns_name[*]}}")'
networksetup -setdnsservers "$network_service" \$(echo \$dns_address)
EOF
  chmod a+x "$switcher"
  echo "$dns_name | refresh=true shell=bash param1=$switcher"
done
