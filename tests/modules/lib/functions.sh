function RERUN_FUNC_CLEANUP {
    echo "Error encountered. Cleaning up..."
    rm -rf "$TMPDIR"
    echo "Done!"

}
trap RERUN_FUNC_CLEANUP ERR

print()
{
    printf '[\e[1;33m+\e[m] \e[1;35m%s\e[m\n' "$@"
}

split()
{
    local IFS="$2"
    O="$1"
    set --
    set -- "$O"
    echo $*
}

