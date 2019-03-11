function RERUN_FUNC_CLEANUP {
    echo "Error encountered. Cleaning up..."
    rm -rf "$TMPDIR"
    echo "Done!"

}
trap RERUN_FUNC_CLEANUP ERR
trap RERUN_FUNC_CLEANUP INT

print()
{
    printf '[\e[1;33m+\e[m] \e[1;35m%s\e[m\n' "$@"
}

