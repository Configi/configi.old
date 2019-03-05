function RERUN_FUNC_CLEANUP {
    rm -rf "$TMPDIR"
}
trap RERUN_FUNC_CLEANUP ERR

print()
{
    printf '[\e[1;33m+\e[m] \e[1;35m%s\e[m\n' "$@"
}
