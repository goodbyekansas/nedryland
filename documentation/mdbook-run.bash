ticker=("⢿" "⡿" "⣟" "⣯" "⣷" "⣾" "⣽" "⣻")
tickerCount=0
echo -n "📖 Starting mdbook... ${ticker[tickerCount]}"
serveOutput=$(mktemp)
mdbook serve --port "${1:-0}" "$@" 1>"$serveOutput" 2>&1 &
servePid=$!
servePort=""
while ps -p $servePid >/dev/null && [ -z "$servePort" ]; do
    if [ $((tickerCount % 2)) -eq 0 ]; then
        servePort=$(sed -n -E 's/^.*listening on (.*)$/\1/p' "$serveOutput")
    else
        sleep 0.25
    fi

    tickerCount=$((tickerCount + 1))
    tickerCount=$((tickerCount % ${#ticker[@]}))
    echo -en "\b${ticker[tickerCount]}"
done

if ! ps -p $servePid >/dev/null; then
    wait $servePid || true
    echo "📒 mdbook exited with code: $?"
    echo "Output:"
    sed "s/^/  [ 📔 ] /" <"$serveOutput"
    exit 1
fi

echo $servePid > ./run.pid
echo "$servePort" >> ./run.pid
echo ""
echo "Mdbook running on $servePort"
