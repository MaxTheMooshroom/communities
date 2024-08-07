
description="Install all of the necessary prequisites for running the provided modpack in a server"

MRPACK="./communities-0.2.1.mrpack"
add_flag '-' "mrpack" "the mrpack to use for the server construction" 1 "mrpack" "string"
function flag_name_mrpack {
    MRPACK="$1"
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
        echo Fetching forge server...
        wget -q "https://maven.minecraftforge.net/net/minecraftforge/forge/${versionLong}/forge-${versionLong}-installer.jar" -O installers/forge-${versionLong}-installer.jar
        chmod +x installers/forge-${versionLong}-installer.jar
    else
        echo "Found forge installer..."
    fi
    if [[ ! -f ./data-dir/run.sh ]]; then
        echo "Installing server jar..."
        java -jar installers/forge-${versionLong}-installer.jar --installServer ./data-dir 2>&1 >/dev/null
        chmod +rx ./data-dir/forge-${versionLong}.jar ./data-dir/run.sh
        mv forge-${versionLong}-installer.jar.log logs/
    else
        echo "Found server jar..."
    fi
}

# check if a file is client-side only using the download URL
#(1: the url)
function validate_file {
    local url=$1
    local project_id=${url##"https://cdn.modrinth.com/data/"}
    project_id=${project_id%%/*}
    local long_urlprefix="https://cdn.modrinth.com/data/${project_id}/versions/"
    local version_id=${url##${long_urlprefix}}
    version_id=${version_id%%/*}
    # echo -e "\t[${project_id}:${version_id}]: ${long_urlprefix}" >&2
    local mod_info=$(curl --user-agent "${MODRINTH_REQUEST_USER_AGENT}" "${MODRINTH_API}/project/${project_id}" 2>/dev/null)
    [[ -z ${mod_info} ]] && error "Got no response for the modrinth project id '${project_id}'" 255
    if [[ "$(echo ${mod_info} | jq -r '.server_side')" == "unsupported" ]]; then
        local mod_name=$(echo ${mod_info} | jq -r '.title')
        echo -e "\tNot supported server-side, skipping... ('${version_id}':'${mod_name}')" >&2
        return 1
    fi
    return 0
}

function fetch_mrpack {
    local cfg="$(cat /dev/shm/mrpack/modrinth.index.json)"
    local num_files=$(echo "${cfg}" | jq -r '.files | length')

    echo "Processing pack index..."
    local fetch_count=0
    for (( i=0; i<${num_files}; i++ )); do
        local filepath=$(echo ${cfg} | jq -r ".files[$i].path")
        filepath=./data-dir/${filepath// /_}
        local fileurl=$(echo ${cfg} | jq -r ".files[$i].downloads[0]")
        local filehash=$(echo ${cfg} | jq -r ".files[$i].hashes.sha512")

        [[ $(( fetch_count % 3 )) -eq 0 ]] && sleep 1

        if [[ -f "${filepath}" ]]; then
            local live_hash="$(sha512sum "${filepath}" | awk '{ print $1 }')"

            if [[ "${live_hash}" == "${filehash}" ]]; then
                echo -e "\tFile found locally, skipping" >&2
                echo -e "\t    -> '${filepath##./data-dir/}'"
                continue
            else
                echo -e "\tFile found locally, hash mismatch! Replacing..." >&2
                rm "${filepath}"
            fi
        fi

        if validate_file ${fileurl}; then
            fetch_file ${fileurl} ${filepath} ${filehash} &
            $(( fetch_count++ ))
        fi
    done
    wait

    echo "Copying overrides..."
    cp -r /dev/shm/mrpack/overrides/* ./data-dir/
}

function target_install {
    mkdir -p ./data-dir/
    mkdir -p ./logs/
    mkdir -p /dev/shm/mrpack
    unzip -q ${MRPACK} -d /dev/shm/mrpack
    chown -R $(whoami) /dev/shm/mrpack
    chmod -R +r /dev/shm/mrpack/*

    local cfg="$(cat /dev/shm/mrpack/modrinth.index.json)"
    fetch_forge $(echo ${cfg} | jq -r '.dependencies | .minecraft, .forge')
    fetch_mrpack 2>&1 | tee logs/mrpack.log

    chmod -R +rw ./data-dir

    rm -rf /dev/shm/mrpack
}

