
description="Install all of the necessary prequisites for running the provided modpack in a server."

declare -g MRPACK="./communities-0.2.1.mrpack"
add_flag '-' "mrpack" "The mrpack to use for the server construction." 1 "mrpack" "string"
function flag_name_mrpack {
    MRPACK="$1"
}

declare -g VERBOSE=0
add_flag 'v' "verbose" "Enable verbose output." 1
function flag_name_verbose {
    VERBOSE=1
}

# fetch the forge server jar
# (1: minecraft version; 2: forge version)
function fetch_forge {
    local minecraft=$1
    local forge=$2
    local versionLong="${minecraft}-${forge}"

    [[ ! -d /dev/shm/mrpack ]] && error "Expected to find directory '/dev/shm/mrpack'!"
    [[ ! -d ./data-dir ]] && error "Expected to have directory '$(pwd)/data-dir'!"
    mkdir -p installers

    if [[ ! -f installers/forge-${versionLong}-installer.jar ]]; then
        echo -e "${CONSOLE_RED}Fetching forge server...${CONSOLE_NC}"
        wget -q "https://maven.minecraftforge.net/net/minecraftforge/forge/${versionLong}/forge-${versionLong}-installer.jar" -O installers/forge-${versionLong}-installer.jar
        chmod +x installers/forge-${versionLong}-installer.jar
    else
        echo -e "${CONSOLE_GREEN}Found forge installer...${CONSOLE_NC}"
    fi
    if [[ ! -f ./data-dir/run.sh ]]; then
        echo -e "${CONSOLE_RED}Installing server jar...${CONSOLE_NC}"
        java -jar installers/forge-${versionLong}-installer.jar --installServer ./data-dir 2>&1 >/dev/null
        chmod +rx ./data-dir/forge-${versionLong}.jar ./data-dir/run.sh
        mv forge-${versionLong}-installer.jar.log logs/
    else
        echo -e "${CONSOLE_GREEN}Found server jar...${CONSOLE_NC}"
    fi
}

# https://stackoverflow.com/questions/1527049/how-can-i-join-elements-of-a-bash-array-into-a-delimited-string
function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

function mrfetch {
    local endpoint=$1
    local query=$2
    curl                                               \
        --user-agent "${MODRINTH_REQUEST_USER_AGENT}"  \
        "${MODRINTH_API}/${endpoint}?${query}"         \
        2>/dev/null
}

# check if a file is client-side only using the download URL
#(1: the urls)
function validate_files {
    local -a urls=($@)
    local -a project_ids

    for url in "${urls[@]}"; do
        local project_id=${url##"https://cdn.modrinth.com/data/"}
        project_id="${project_id%%/*}"
        project_ids+=(${project_id})
    done

    local id_list=%5B%22$(join_by '%22%2C%22' ${project_ids[@]})%22%5D
    #[[ ${VERBOSE} -eq 1 ]] && echo -e "IDS:\n${CONSOLE_GREEN}${id_list}${CONSOLE_NC}"

    local mods_info=$(mrfetch projects "ids=${id_list}")
    local server_projects=($(echo "${mods_info}" | jq -r '.[] | select(.server_side != "unsupported") | .id'))
    #[[ ${VERBOSE} -eq 1 ]] && echo -e "IDS:\n${CONSOLE_PINK}${server_projects}${CONSOLE_NC}"

    local -a server_urls
    for project_id in "${server_projects[@]}"; do
        for url in "${urls[@]}"; do
            if [[ ${url} =~ ${project_id} ]]; then
                server_urls+=(${url})
                #echo -e "${CONSOLE_PINK}${url}${CONSOLE_NC}"
                break
            fi
        done
    done
    echo ${server_urls[@]}
}

# read the json file containing the modpack's index and fetch all required server files
function fetch_mrpack {
    local cfg="$(cat /dev/shm/mrpack/modrinth.index.json)"
    local -a packed_data=( $(cat /dev/shm/mrpack/modrinth.index.json | jq -r '[.files[] | "\(.path | gsub(" "; "_")),\(.downloads[0]),\(.hashes.sha512)"] | join(" ")') )

    local -a download_queue
    local -a urls

    for data in "${packed_data[@]}"; do
        local -a mod_data=( ${data//,/ } )
        local filepath=./data-dir/${mod_data[0]}
        local fileurl=${mod_data[1]}
        local filehash=${mod_data[2]}

        if [[ -f "${filepath}" ]]; then
            local live_hash="$(sha512sum "${filepath}" | awk '{ print $1 }')"

            if [[ "${live_hash}" == "${filehash}" ]]; then
                if [[ ${VERBOSE} -eq 1 ]]; then
                    echo -e "\t${CONSOLE_GREEN}File found locally, skipping...${CONSOLE_NC}" >&2
                    echo -e "\t    -> '${filepath##./data-dir/}'"
                fi
                continue
            else
                [[ ${VERBOSE} -eq 1 ]] && echo -e "\tFile found locally, hash mismatch! Removing..." >&2
                rm "${filepath}"
            fi
        fi
        urls+=(${fileurl})
    done

    local -a server_files=($(validate_files ${urls[@]}))

    for fileurl in "${server_files[@]}"; do
        for data in "${packed_data[@]}"; do
            if [[ ${data} =~ ${fileurl} ]]; then
                local -a mod_data=( ${data//,/ } )
                local filepath=./data-dir/${mod_data[0]}
                local filehash=${mod_data[2]}
                [[ ${VERBOSE} -eq 1 ]] && echo -e "\t${CONSOLE_RED}Missing '${filepath##./data-dir/}'...${CONSOLE_NC}"
                fetch_file ${fileurl} ${filepath} ${filehash} &
                break
            fi
        done
    done
    wait

    echo "Copying overrides..."
    cp -r /dev/shm/mrpack/overrides/* ./data-dir/
}

function fetch_overrides {
    [[ ! -f ./.manual_overrides ]] && return

    local fetch_count=0

    for version_id in "$(cat ./.manual_overrides)"; do
        [[ ${VERBOSE} -eq 1 ]] && echo -e "${CONSOLE_PINK}${version_id}${CONSOLE_NC}"
    done
}

function target_install {
    mkdir -p ./data-dir/
    mkdir -p ./logs/
    [[ -d /dev/shm/mrpack ]] && rm -rf /dev/shm/mrpack
    mkdir -p /dev/shm/mrpack
    unzip -q ${MRPACK} -d /dev/shm/mrpack
    chown -R $(whoami) /dev/shm/mrpack
    chmod -R +r /dev/shm/mrpack/*

    local cfg="$(cat /dev/shm/mrpack/modrinth.index.json)"
    fetch_forge $(echo ${cfg} | jq -r '.dependencies | .minecraft, .forge')
    fetch_mrpack 2>&1 | tee logs/mrpack.log
    fetch_overrides

    chmod -R +rw ./data-dir

    rm -rf /dev/shm/mrpack
}

