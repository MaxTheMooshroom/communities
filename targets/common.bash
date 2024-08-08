
# ================================================================================================
#                                            GLOBALS
declare -ga DEPENDENCIES=(unzip jq awk sha512sum java rcon sshuttle)

declare -ga PORTS=(25565 25575 3876 24454 8080)

#declare -g MODRINTH_API="https://staging-api.modrinth.com/v2"
declare -g MODRINTH_API="https://api.modrinth.com/v2"
declare -g MODRINTH_REQUEST_USER_AGENT="MaxTheMooshroom/communities (alpha) (maxthemooshroom@gmail.com)"

declare -g CONSOLE_NC='\033[0m'
declare -g CONSOLE_RED='\033[0;31m'
declare -g CONSOLE_PINK='\033[1;35m'
declare -g CONSOLE_GREEN='\033[1;32m'

# fetch a file from a provided url, store it at a provided path, and check it against a provided
# hash. You can skip the check with '-' as the hash
#(1: the url; 2: the path; 3: the hash)
function fetch_file {
    local url=$1
    local outpath=$2
    local hash_expected=$3

    mkdir -p $(dirname ${outpath// /_})
    wget -q -O ${outpath// /_} ${url}

    [[ ! -f ${outpath// /_} ]] && error "Failed to download mod '${url}'..."
    [[ "${hash_expected}" == '-' ]] && return

    local hash_real=$(sha512sum ${outpath// /_} | awk '{ print $1 }')
    if [[ "${hash_real}" != "${hash_expected}" ]]; then
        error "Hash of '${outdir}' did not match expected hash (sha512): '${hash_expected}'"
    fi
}

