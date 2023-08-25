# ANSI color codes
BOLD="\033[1m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

DEV_CONTAINER_NAME="gail-dev"

function ok() {
    echo -e "[${GREEN}${BOLD} OK ${RESET}] $1"
}


function warn() {
    echo -e "[${YELLOW}${BOLD}WARN${RESET}] $1"
}


function fail() {
    echo -e "[${RED}${BOLD}FAIL${RESET}] $1"
    exit 1
}


function print_usage() {
    echo -e "Usage: ${GREEN}$0${RESET} [options] <image>"
    echo ""
    echo "Options:"
    echo -e "  ${GREEN}-h, --help${RESET}   Display this help message"
    echo -e "  ${GREEN}-v, --verbose${RESET}  Enable verbose mode"
}


function run_docker() {
    local image=$1

    local existing_container=$(docker ps -a \
                                      --filter "name=^/${DEV_CONTAINER_NAME}$" \
                                      --format '{{.Names}}' \
                                   | grep -w "^${DEV_CONTAINER_NAME}$")

    if [[ ! -z "$existing_container" ]]; then
        ok "Container with the name ${DEV_CONTAINER_NAME} exists."
        return
    fi

    local tmp_bashrc=$(mktemp)
    echo 'export PS1="\[\033[38;5;81m\]\u\[$(tput sgr0)\]\[\033[38;5;15m\]@\[$(tput sgr0)\]\[\033[38;5;214m\]\h\[$(tput sgr0)\]\[\033[38;5;15m\] {\[$(tput sgr0)\]\[\033[38;5;228m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]} \\$ \[$(tput sgr0)\]"' > "$tmp_bashrc"

    # Define extra mounts
    local extra_mounts="-v $tmp_bashrc:$HOME/.bashrc:ro"

    # In case you would like to mount more paths, here is an example
    # 
    # if [[ -f "$HOME/.inputrc" ]]; then
    #     extra_mounts+=" -v $HOME/.bashrc:$HOME/.inputrc:ro"
    # fi

    docker run --rm -d --name "${DEV_CONTAINER_NAME}" \
           --gpus all \
           --user $UID:$GID \
           -v /etc/passwd:/etc/passwd:ro \
           -v /etc/group:/etc/group:ro \
           -v /etc/shadow:/etc/shadow:ro \
           -v /tmp:/tmp \
           -v "$HOME/projects:$HOME/projects" \
           $extra_mounts \
           ${image} \
           tail -f /dev/null
}


function enter_container() {
    ok "Entering the container ${DEV_CONTAINER_NAME}."
    docker exec -it -w "$HOME" "${DEV_CONTAINER_NAME}" /bin/bash
}


function app() {
    local verbos=0
    # TODO(breakds): Initialize image by reading from an environment variable.
    local image=""

    while [[ "$#" -gt 0 ]]; do
        key="$1"
        case $key in
            -h|--help)
                print_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=1
                shift
                ;;
            *)
                # TODO(breakds): Make sure that image is only assigned once
                image=$1
                shift
                ;;
        esac
    done

    # +--------------------+
    # | Identify Image     |
    # +--------------------+

    if [[ -z "${image}" ]]; then
        print_usage
        fail "Please provide the name to the docker image."
    fi

    ok "Receive the request to run image ${image} as development environment."

    # +--------------------+
    # | Start container    |
    # +--------------------+

    run_docker ${image}

    # +--------------------+
    # | Enter contaienr    |
    # +--------------------+

    enter_container
}

app "$@"
