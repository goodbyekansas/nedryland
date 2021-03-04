if [ $1 == "--fix" ]; then
    @nixpkgsFmt@ "${2:-.}"
    exit $?
fi
files=$(@nixpkgsFmt@ . --check)

if [ $? == 1 ]; then
    echo "$files"
    dir=$(mktemp --directory "/tmp/nix-fmt-XXXXXX")
    for file in ${files[@]}; do
        echo ""
        echo "⚠️ Formatting errors in $file:"
        cp "$file" "$dir/copy"
        @nixpkgsFmt@ "$dir/copy" | tail -n +2
        @diff@ -u --color=always "$file" "$dir/copy" | tail -n +3
    done
    rm -rf "$dir"
    exit 1
fi
