# Re-encode a video to AV1 with SVT-AV1, keeping resolution, frame rate,
# audio and 360° (spherical) metadata. Requires ffmpeg built with libsvtav1.

GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BOLD="\033[1m"
RESET="\033[0m"

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
    echo -e "Usage: ${GREEN}to-av1${RESET} [options] <input>"
    echo ""
    echo "Writes <input stem>.av1.mp4 next to the input."
    echo ""
    echo "Options:"
    echo -e "  ${GREEN}-p, --preset${RESET} N   SVT-AV1 speed, 0 (slowest, smallest) to 13 (fastest). Default 6"
    echo -e "  ${GREEN}-c, --crf${RESET} N      Quality, lower is better and larger. Default 30"
    echo -e "  ${GREEN}-t, --duration${RESET} S Encode only the first S seconds, for a test run"
    echo -e "  ${GREEN}-h, --help${RESET}       Display this help message"
}

function has_spherical() {
    ffprobe -v error -select_streams v:0 -show_entries stream_side_data \
            "$1" | grep -q "Spherical Mapping"
}

function app() {
    local preset=6
    local crf=30
    local duration_args=()
    local input=""

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -h|--help)
                print_usage
                exit 0
                ;;
            -p|--preset)
                preset=$2
                shift 2
                ;;
            -c|--crf)
                crf=$2
                shift 2
                ;;
            -t|--duration)
                duration_args=(-t "$2")
                shift 2
                ;;
            *)
                [[ -n "${input}" ]] && fail "Only one input file is allowed."
                input=$1
                shift
                ;;
        esac
    done

    if [[ -z "${input}" ]]; then
        print_usage
        fail "Please provide the input file."
    fi
    [[ -f "${input}" ]] || fail "${input} does not exist."

    ffmpeg -hide_banner -encoders 2>/dev/null | grep -q libsvtav1 \
        || fail "This ffmpeg is not built with libsvtav1."

    local output="${input%.*}.av1.mp4"
    [[ -e "${output}" ]] && fail "${output} already exists."

    ok "Encoding ${input} -> ${output} (preset ${preset}, crf ${crf})"

    # -map: first video stream and all audio. Camera data streams (e.g.
    #       GoPro telemetry) are dropped because MP4 often rejects them.
    # -strict unofficial: lets the MP4 muxer write spherical metadata.
    ffmpeg -hide_banner -i "${input}" "${duration_args[@]}" \
           -map 0:v:0 -map "0:a?" \
           -c:v libsvtav1 -crf "${crf}" -preset "${preset}" \
           -fps_mode passthrough \
           -c:a copy \
           -strict unofficial \
           -movflags +faststart \
           "${output}" \
        || fail "ffmpeg failed."

    if has_spherical "${input}"; then
        if has_spherical "${output}"; then
            ok "Spherical (360°) metadata kept."
        else
            warn "Input is 360° but the output lost its spherical metadata."
        fi
    fi

    ok "Done: ${output}"
}

app "$@"
