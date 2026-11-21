# Usage: kagi-search [-n N] QUERY...
# Searches the web through Kagi's API, with the key at ~/.config/kagi/api-key.

limit=10
if [ "${1:-}" = "-n" ]; then limit=$2; shift 2; fi
if [ $# -eq 0 ]; then
  echo "usage: kagi-search [-n N] QUERY..." >&2
  exit 2
fi
key="$HOME/.config/kagi/api-key"
if [ ! -s "$key" ]; then
  echo "kagi-search: no API key at $key" >&2
  exit 1
fi
if ! response=$(jq -n --arg q "$*" --argjson n "$limit" '{query: $q, limit: $n}' |
  curl -sS --fail-with-body https://kagi.com/api/v1/search \
    -H @<(printf 'Authorization: Bearer %s\n' "$(cat "$key")") \
    -H 'Content-Type: application/json' -d @-); then
  echo "kagi-search: $(jq -r ".errors[0].message // ." <<< "$response" 2>/dev/null || echo "$response")" >&2
  exit 1
fi
jq -r '.data.search[] | "\(.title)\n\(.url)\(if .time then "  (\(.time[0:10]))" else "" end)\n\(.snippet // "")\n"' <<< "$response"
