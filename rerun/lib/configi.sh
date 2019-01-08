COMMAND="$1"
REPAIR()
{
    printf '[\e[1;33mREPAIR\e[m] \e[1;35m%s\e[m \e[1;36m%s\e[m\n' "$COMMAND" "$2"
}
PASS()
{
    printf '[\e[1;32mPASS\e[m] \e[1;35m%s\e[m \e[1;36m%s\e[m\n' "$COMMAND" "$2"
}
FAIL()
{
    printf '[\e[1;31mPASS\e[m] \e[1;35m%s\e[m \e[1;36m%s\e[m\n' "$COMMAND" "$2"
}


