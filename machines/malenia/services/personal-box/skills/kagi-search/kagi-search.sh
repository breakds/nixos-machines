# Usage: kagi-search [-n N] QUERY...
# Searches the web through Kagi's API, with the key at ~/.config/kagi/api-key.

limit=10
words=()
while [ $# -gt 0 ]; do
  case $1 in
    -n) limit=$2; shift 2 ;;
    *) words+=("$1"); shift ;;
  esac
done
if [ ${#words[@]} -eq 0 ]; then
  echo "usage: kagi-search [-n N] QUERY..." >&2
  exit 2
fi
key="$HOME/.config/kagi/api-key"
if [ ! -s "$key" ]; then
  echo "kagi-search: no API key at $key" >&2
  exit 1
fi
if ! response=$(jq -n --arg q "${words[*]}" --argjson n "$limit" '{query: $q, limit: $n}' |
  curl -sS --fail-with-body https://kagi.com/api/v1/search \
    -H @<(printf 'Authorization: Bearer %s\n' "$(cat "$key")") \
    -H 'Content-Type: application/json' -d @-); then
  echo "kagi-search: $(jq -r ".errors[0].message // ." <<< "$response" 2>/dev/null || echo "$response")" >&2
  exit 1
fi
# Titles and snippets come as HTML: drop the tags, decode the common entities.
jq -r '
  def text: gsub("<[^>]*>"; "") | gsub("&#39;"; "\u0027") | gsub("&quot;"; "\"")
    | gsub("&lt;"; "<") | gsub("&gt;"; ">") | gsub("&amp;"; "&");
  (.data.search // []) as $results
  | if $results == [] then "no results"
    else $results[]
      | "\(.title | text)\n\(.url)\(if .time then "  (\(.time[0:10]))" else "" end)\n\(.snippet // "" | text)\n"
    end
' <<< "$response"
