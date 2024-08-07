
description="Fetch a list of mods by modrinth version IDs."

add_argument "mod ids" "string..." "A list of modrinth project version IDs."

function target_fetch_mods {
    local ids=($@)
    echo
    echo "Fetching mods..."
    for (( i=0; i<${#ids[@]}; i++ )); do
        local version_id=${ids[i]}
        [[ $(( (i + 1) % 4 )) -eq 0 ]] && sleep 1
        local version_info=$(curl -s --user-agent "${MODRINTH_REQUEST_USER_AGENT}" "${MODRINTH_API}/version/${version_id}")
        local url=$(echo ${version_info} | jq -r '.files[0].url')
        local filename=$(echo ${version_info} | jq -r '.files[0].filename')
        echo -e "[${version_id}]: Fetching mod ${filename}"
        wget -q -O ./data-dir/mods/${filename// /_} ${url} &
    done
    wait
}
