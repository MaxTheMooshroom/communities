
description="Fetch a list of mods by modrinth version IDs."

add_argument "mod ids" "string..." "A list of modrinth project version IDs."

function target_fetch_mods {
    local ids=($@)
    local fetch_count=0
    echo -e "\nFetching mods..."

    [[ ! -f ./.manual_overrides ]] && touch ./.manual_overrides

    for (( i=0; i<${#ids[@]}; i++ )); do
        local version_id=${ids[i]}
        [[ $(( fetch_count % 4 )) -eq 0 ]] && sleep 1 && (( fetch_count++ ))
        local version_info=$(curl -s --user-agent "${MODRINTH_REQUEST_USER_AGENT}" "${MODRINTH_API}/version/${version_id}")
        local url=$(echo ${version_info} | jq -r '.files[0].url')
        local filename=$(echo ${version_info} | jq -r '.files[0].filename')

        [[ ! $(cat ./.manual_overrides) =~ ${version_id} ]] && echo ${version_id} >> ./.manual_overrides
        echo -e "\t${CONSOLE_PINK}[${version_id}]: Fetching mod ${filename}${CONSOLE_NC}"
        wget -q -O ./data-dir/mods/${filename// /_} ${url} &
        (( fetch_count++ ))
    done
    wait
}
