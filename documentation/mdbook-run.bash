#! @bash@
# shellcheck shell=bash

args=()
port=0

while [[ $# -gt 0 ]]; do
  case $1 in
    -p|--port)
      port=$2
      shift 2
      ;;
    -p=*|--port=*)
      port="${1#*=}"
      shift 1
      ;;
    -p*)
      port="${1#-p}"
      shift 1
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

ticker=("⢿" "⡿" "⣟" "⣯" "⣷" "⣾" "⣽" "⣻")
tickerCount=0
echo -n "📖 Starting mdbook... ${ticker[tickerCount]}"
serveOutput=$(mktemp)
mdbook serve --port "$port" "${args[@]}" 1>"$serveOutput" 2>&1 &
servePid=$!
servePort=
while [ -z "$servePort" ] && ps -p "$servePid" >/dev/null 2>&1; do
    tickerCount=$((tickerCount + 1))
    tickerCount=$((tickerCount % ${#ticker[@]}))
    echo -en "\b${ticker[tickerCount]}"
    servePort=$(@procfd@ --pid $servePid --socket-type tcp --json \
        | @jq@ 'first(.. | .local_port? | select(. != null))')
    sleep 0.1
done

if ! ps -p $servePid >/dev/null; then
    wait $servePid || true
    echo "📒 mdbook exited with code: $?"
    echo "Output:"
    sed "s/^/  [ 📔 ] /" <"$serveOutput"
    exit 1
fi

echo $servePid > ./mdbook.pid
echo "$servePort" >> ./mdbook.pid
echo ""
echo "Mdbook running on http://localhost:$servePort"
