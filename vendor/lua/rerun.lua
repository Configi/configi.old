return [==[#!/usr/bin/env bash
#
# **rerun** - If you've got a bunch of loose
# unstructured shell scripts, rerun will help you
# turn them into testable automation modules.
#
# Minimalism is rerun's goal. It will try to stay out of your way
# yet take care of some of your grunt work.
#
#/ usage: rerun [-h][-G][-x][-v][-V][--version] [--loglevel <>] [-M <dir>] [--answers|-A <file>] [--sudo-user|-S <user>] [module:[command [options]]]
#
# __Install__
#
# See [wiki](http://github.com/rerun/rerun/wiki) for install and
# setup instructions.

# The rerun version.

RERUN_VERSION=1.4.1



# Public functions
# ----------------------
#
# The rerun public function library contains
# a range of functions useful for looking up
# and executing rerun commands.
# This rerun script can be sourced.
#

# rerun - Invoke the rerun command in the current environment.
#
#     rerun
#
# Arguments: None
#
# Environment variables:
#
# * RERUN: The path to the rerun executable
# * RERUN_MODULES: The module directory path
#

rerun() {
    command "$RERUN" -M "$RERUN_MODULES" "$@"
}

#
# - - -
#

# rerun_color - Prints message in specified color using ansi codes.
#
#     rerun_color color message
#
# Arguments:
#
# * color:    The color to print (red|hred|blue|cyan|yellow|green|ul|bold)
# * message:  The message to colorize.
#
# Notes:
#
# * If RERUN_COLOR is unset, no text effect is applied.
# * Unrecognized colors are defaulted to black.
#
rerun_color() {
    (( $# < 2 )) && {
        printf >&2 'wrong # args: should be: rerun_color color message\n'
        return 2
    }
    local color=$1 reset="\033[0m" black="\033[0;30m" code=
    case $color in
        red)    code="\033[31m"   ;;
        hred)   code="\033[1;31m" ;;
        blue)   code="\033[34m"   ;;
        cyan)   code="\033[36m"   ;;
        yellow) code="\033[33m"   ;;
        green)  code="\033[32m"   ;;
        # text effects
        bold)   code="\033[1m"    ;;
        ul)     code="\033[4m"    ;;
        # default to black
        *)      code="$black"     ;;
    esac
    shift;
    local message="$*"
    if [[ -n "${RERUN_COLOR:-}" ]]
    then echo -ne "${code}" "${message:-}" "${reset}"
    else printf -- "%s" "${message:-}"
    fi
}

#
# - - -
#

#
# rerun_log_puts - Produce a log message
#
#     rerun_log_puts level command message
#
# Arguments:
#
# * level:    The numeric log level.
# * command:  Command name. Usually module:command
# * message:  The message text.
#
# Notes:
#
# * Messages are written to stdout if below error level.
# * RERUN_LOG_LEVELS defines the set of valid log levels
RERUN_LOG_LEVELS=([0]=debug [1]=info [2]=warn [3]=error [4]=fatal)
# * RERUN_LOG_LEVEL specifies the current log level (default: info)
: "${RERUN_LOG_LEVEL:=1}"
# * RERUN_LOG_ERR_LEVEL specifies the minimum level for messages printed to stderr.
: "${RERUN_LOG_ERR_LEVEL:=3}"
# * Messages can be colored depending on level.
RERUN_LOG_COLORS=([0]=cyan [1]=green [2]=yellow [3]=red [4]=hred)
# * RERUN_LOG_FMT_CONSOLE specifies the format for messages printed to the console.
if [[ -z ${RERUN_LOG_FMT_CONSOLE:-} ]]
then
    if [[ -t 0 ]]
    then RERUN_LOG_FMT_CONSOLE="%message%"
    else RERUN_LOG_FMT_CONSOLE="[%level%] %command%: %message%"
    fi
fi
# * RERUN_LOG_FMT_LOGFILE specifies the format for log entries.
: "${RERUN_LOG_FMT_LOGFILE:=[%tstamp%] [%level%] %command%: %message%}"

#
rerun_log_puts() {
    (( $# != 4 )) && {
        printf >&2 'wrong # args: should be: rerun_log_puts format level command message\n'
        return 2
    }
    [[ "$2" =~ [0-9]+ ]] || { printf >&2 "rerun_log_puts: level must be numeric: '%s'\n" "$2"; return 2; }
    local -r format="$1" level="$2" command="$3" message="$4"
    local -r tstamp=$(date '+%Y-%m-%dT%H%M%S-%Z')
    local fmt_spec output
    case "$format" in
        console) fmt_spec=$RERUN_LOG_FMT_CONSOLE
        ;;
        logfile) fmt_spec=$RERUN_LOG_FMT_LOGFILE
        ;;
    esac
    output=$(printf -- "%s" "$fmt_spec" |
    sed -e "s^%tstamp%^$tstamp^g" \
        -e "s^%level%^${RERUN_LOG_LEVELS[$level]}^g" \
        -e "s^%command%^$command^g" \
        -e "s^%message%^$message^g")

    if (( level >= RERUN_LOG_ERR_LEVEL ))
    then
        # write message to stderr
        printf >&2 -- "%s\n" "$(rerun_color "${RERUN_LOG_COLORS[$level]}" "$output")"
    else
        # write message to stdout
        printf -- "%s\n" "$(rerun_color "${RERUN_LOG_COLORS[$level]}" "$output")"
    fi

    return 0
}

#
# - - -
#

#
# rerun_log_syslog - Print a log message to syslog
#
#     rerun_log_syslog level command message
#
# Arguments:
#
# * facility: Valid syslog facility. (e.g., local3)
# * level:    The numeric log level.
# * command:  Command name. Usually formatted "module:command". If empty, 'rerun' is used.
# * message:  The message text.
#
# Notes:
#
# * rerun_log levels are mapped to equivalent syslog priority.
#
rerun_log_syslog() {
    (( $# == 4 )) || {
        printf >&2 'wrong # args: should be: rerun_log_syslog facility level command message\n'
        return 2
    }
    local -r facility="$1" level="$2" command="${3:-$(basename "$0")}" message="$4"

    # map rerun_log level to syslog priority.
    local pri=
    case "$level" in
        4)   pri="fatal"   ;;
        3)   pri="err"     ;;
        2)   pri="warning" ;;
        1|0) pri="$level"  ;;
    esac
    logger -p "${facility}.${pri}" -t "${LOGNAME:-$USER} ($command)" -- "$message"
    return $?
}

#
# - - -
#

#
# rerun_log - Perform a log action.
#
#     rerun_log action ?args?
#
# Arguments:
#
# * action:   Action to perform. See actions below.
#     - levels - print the supported log levels. (eg, debug info warn error fatal)
#     - logfile ?path? - set or get the current log file to write messages.
#     - level ?level? - set or get the current log level.
#     - log priority message - write the message to the log at the specified priority.
#     - syslog ?facility? - set or get the current syslog facility. Set it to empty disables syslog.
#     - {debug,info,warn,error,fatal} message - convenience action to write a log at specified level.
# * command:  Command name. Usually module:command
# * message:  The message text.
#
# Notes:
#
# * Command context is determined by RERUN_MODULE_DIR and RERUN_COMMAND_DIR
# * RERUN_LOG_LEVELS should be considered immutable
# * RERUN_LOG_LEVEL should only be controlled via `rerun_log level`.
# * RERUN_LOG_FILE should be controlled via `rerun_log logfile`.
# * RERUN_LOG_SYSLOG specifies syslog facility. Must be set to enable syslogging (unset by default).
: "${RERUN_LOG_SYSLOG:=}"
#
rerun_log() {
    (( $# >= 1 )) || {
        printf >&2 'usage: rerun_log ?action? ?args?\n'
        return 2
    }
    local -r action="$1"
    local level
    case "$action" in
        levels)
            printf "%s\n" "${RERUN_LOG_LEVELS[*]}"
            return 0
            ;;
        level)
            (( $# == 1 )) && printf "%s\n" "${RERUN_LOG_LEVELS[$RERUN_LOG_LEVEL]}"
            (( $# == 2 )) && {
                level=$(rerun_list_index "$2" "${RERUN_LOG_LEVELS[*]}")
                if (( "$level" >= 0 && "$level" <= ${#RERUN_LOG_LEVELS[*]})); then
                    RERUN_LOG_LEVEL=$level
                else
                    printf >&2 "rerun_log level: invalid level: %s\n" "$2"; return 2;
                fi
            }
            return 0
            ;;
        logfile)
            (( $# == 1 )) && printf "%s\n" "${RERUN_LOG_FILE}"  || RERUN_LOG_FILE=$2
            return 0
            ;;
        syslog)
            if (( $# == 1 )); then
                printf "%s\n" "${RERUN_LOG_SYSLOG}"
            else
                [[ "$2" =~ ^[[:alnum:]]+$ ]] || {
                    printf >&2 "rerun_log syslog: facility is not a valid name: '%s'\n" "$2"
                    return 2
                }
                RERUN_LOG_SYSLOG=$2
            fi
            return 0
            ;;
        fmt-console)
            (( $# == 1 )) && printf "%s\n" "${RERUN_LOG_FMT_CONSOLE}"  || RERUN_LOG_FMT_CONSOLE=$2
            return 0
            ;;
        fmt-logfile)
            (( $# == 1 )) && printf "%s\n" "${RERUN_LOG_FMT_LOGFILE}"  || RERUN_LOG_FMT_LOGFILE=$2
            return 0
            ;;
        debug|info|warn|error|fatal)
            level=$(rerun_list_index "$action" "${RERUN_LOG_LEVELS[*]}")
            shift
            local message="$*"
            ;;
        log)
            level=$(rerun_list_index "$2" "${RERUN_LOG_LEVELS[*]}")
            (( "$level" >= 0 && "$level" <= 4)) || { "rerun_log log: invalid level: $2"; return 2; }
            shift
            local message="$*"
            ;;
        *)
            local message="$*"
            ;;
    esac
    local -a ctx=()
    [[ -n "${RERUN_MODULE_DIR:-}" ]] && {
        ctx=( ${ctx[*]:-} $(basename "$RERUN_MODULE_DIR") )
    }
    [[ -n "${RERUN_COMMAND_DIR:-}" ]] && {
        ctx=( ${ctx[*]:-} $(basename "$RERUN_COMMAND_DIR") )
    }
    local -r command=$( IFS=:; printf "%s" "${ctx[*]:-}" )
    : "${level:=$RERUN_LOG_LEVEL}"
    local current_level=$RERUN_LOG_LEVEL
    if (( level >= current_level ))
    then
        rerun_log_puts console "$level" "$command" "$message"
        [[ -n "${RERUN_LOG_FILE:-}" ]] && {
            rerun_log_puts logfile "$level" "$command" "$message" >> "$RERUN_LOG_FILE"
        }
    fi
    [[ -n "${RERUN_LOG_SYSLOG:-}" ]] && {
        rerun_log_syslog "$RERUN_LOG_SYSLOG" "$level" "$command" "$message"
    }
    return 0
}

#
# - - -
#

#
# rerun_die - Print an error message and exit with exit code status.
#
#     rerun_die ?exit_code? ?message?
#
# Arguments:
#
# * exit_code:   Exit code status. Defaults to 1.
# * message:     Text to print in message
#
# Notes:
#
# * Messages are written to stderr.
# * Use text effects if `RERUN_COLOR` environment variable set.
# * Message format:     `"ERROR : ?message?"`
# * Exit status returned to invoking command: 0
rerun_die() {
   (( $# > 1 )) && {
        local exit_status=$1
        shift
    }
    local -i frame=0; local info=
    while info=$(caller $frame)
    do
        local -a f=( $info )
        (( frame > 0 )) && {
            printf >&2 "ERROR in \"%s\" %s:%s\n" "${f[1]}" "${f[2]}" "${f[0]}"
        }
        (( frame++ )) || :; #ignore increment errors (i.e., errexit is set)
    done

    rerun_log error "ERROR: $*" >&2
    exit "${exit_status:-1}"
}

#
# - - -
#

# rerun_syntax_error - Print a syntax error and exit with code 2.
#
#     rerun_syntax_error ?message?
#
# Arguments:
#
# * message:     Text to print in message
#
# Notes:
#
# * Messages are written to stderr.
# * Use text effects if `RERUN_COLOR` environment variable set.
# * Message format:     `"SYNTAX : ?message?"`
# * Exit status returned to invoking command: 2
rerun_syntax_error() {
    rerun_log error "SYNTAX: $*"
    exit 2
}

#
# - - -
#

# _rerun_option_check_ - Check option has sufficent has an argument.
#
#     rerun_option_check nargs option
#
# Arguments:
#
# * nargs:     Number of arguments passed to option.
# * option:    Option name.
#
# Notes:
#
# * Return 0 if there is an argument.
# * Return 1 otherwise
rerun_option_check() {
    if (( "$1" < 2 ))
    then rerun_syntax_error "option requires argument: ${2:-}"
    else return 0
    fi
}

#
# - - -
#

# _rerun_option_usage_ - print usage summary and exit.
#
#     rerun_option_usage
#
# Arguments: _None_
#
# Notes:
#
# * Parses invoking shell script file for usage summary.
# * Format: `usage: ?text?`
# * Return 2
#
rerun_option_usage() {
    local message
    if [[ -f "$0" ]]
    then message=$(grep '^#/ usage:' <"$0" | cut -c4-)
    else message="usage: check command for usage."
    fi
    rerun_log error "$message"
    return 2
}

#
# - - -
#


# _rerun_options_parse_ - Parse the command arguments and set option variables.
#
#     rerun_options_parse "$@"
#
# Arguments:
#
# * the command options and their arguments.
#
# Notes:
#
# * Sets shell variables for any parsed options.
# * The "-?" help argument prints command usage and exits 2.
# * This function can be overriden by command scripts.
# * Set defaultable options.
# * Check required options are set
# * If option variables are declared exportable, export them.
# * Return 0 for successful option parse.
#
rerun_options_parse() {
    while (( "$#" > 0 )); do
        OPT="$1"
        case "$OPT" in
            -?) rerun_option_usage
                exit 2
                ;;
            *)
              break ; # end of options, just arguments left
        esac
        shift
    done
    return 0
}

#
# - - -
#

# _rerun_modules_ - List the modules by name.
#
#     rerun_modules path
#
# Arguments:
#
# * path:     Path to directories containing modules.
#
# Notes:
#
# * Returns a list of space separated module names.
#
rerun_modules() {
    (( ! $# == 1 )) && {
	    rerun_die 'wrong # args: should be: rerun_modules path'
    }
    local -a modules
    local module
    for dir in $(rerun_module_path_elements "$1")
    do
        [[ ! -d "$dir" ]] && rerun_die "directory not found: $dir"
        for f in $dir/*/metadata
        do
            if [[ -f "$f" ]]
            then
                module=$(basename "$(dirname "$f")")
                [[ -z "${modules:-}" ]] && modules=( $module ) || modules=( ${modules[*]} $module )
            fi
        done
    done
    echo "${modules[*]}" | sort | uniq
}

#
# - - -
#

# _rerun_get_module_home_dir_in_path_ - Get the directory for the module in the path
#
#     rerun_get_module_home_dir_in_path path module
#
# Arguments:
#
# * path:     Path to directories containing modules.
# * module:        Module name.
#
rerun_get_module_home_dir_in_path() {
    (( $# == 2 )) || {
	    rerun_die 'wrong # args: should be: rerun_get_module_home_dir_in_path path module'
    }
    for dir in $(rerun_module_path_elements "$1")
    do
        if [[ -f "$dir/$2/metadata" ]]
        then
            echo "$dir/$2"
            return 0
        fi
    done
    return 2
}


#
# - - -
#

# _rerun_commands_ - List the commands for the specified module.
#
#     rerun_commands directory module command
#
# Arguments:
#
# * path:     Path to directories containing modules.
# * module:        Module name.
# Notes:
#
# * Returns a list of space separated command names.
#
rerun_commands() {
    (( $# == 2 )) || {
	    rerun_die 'wrong # args: should be: rerun_commands path module'
    }
    local -r module_home=$(rerun_get_module_home_dir_in_path "$1" "$2")
    [[ -n $module_home ]] || rerun_die "module not found in path: $2 $1"
    local -a commands=()
    local command
	for c in $module_home/commands/*/metadata
	do
		if [[ -f $c ]]
		then
			command=$(basename "$(dirname "$c")")
			[[ -z "${commands:-}" ]] && commands=( $command ) || commands=( ${commands[*]} $command )
		fi
	done
    echo "${commands[*]:-}"
}

#
# - - -
#


# _rerun_options_ - List the options assigned to command.
#
#     rerun_options directory module command
#
# Arguments:
#
# * path:     Path to directories containing modules.
# * module:        Module name.
# * command:       Command name.
#
# Notes:
#
# * Returns a list of space separated option names.
# * Conditions: If metadata is not found, an empty list is returned.
#
rerun_options() {
    (( $# == 3 )) || {
	    rerun_die 'wrong # args: should be: rerun_options path module command'
    }
    local -r module_home=$(rerun_get_module_home_dir_in_path "$1" "$2")
    [[ -n $module_home ]] || rerun_die "module not found in path: $2 $1"
	if [[ -f "$module_home/commands/$3/metadata" ]]
	then
        # shellcheck source=/dev/null
		( . "$module_home/commands/$3/metadata" ; echo "${OPTIONS:-}" )
	else
		echo ""
	fi
}

#
# - - -
#

# _rerun_module_options_ - List the options for the specified module.
#
#     rerun_module_options directory module
#
# Arguments:
#
# * path:     Path to directories containing modules.
# * module:        Module name.
# Notes:
#
# * Returns a list of space separated option names.
#
rerun_module_options() {
    (( $# == 2 )) || {
	    rerun_die 'wrong # args: should be: rerun_module_options path module'
    }
    local -a options=(); local option module_home
    module_home=$(rerun_get_module_home_dir_in_path "$1" "$2")
    [[ -n $module_home ]] || rerun_die "module not found in path: $2 $1"
	for o in $module_home/options/*/metadata
	do
		if [[ -f "$o" ]]
		then
			option=$(basename "$(dirname "$o")")
			[[ -z "${options:-}" ]] && options=( $option ) || options=( ${options[*]} $option )
		fi
	done
    echo "${options[*]:-}"
}

#
# - - -
#

# _rerun_list_contains_ - Checks if element is contained in list.
#
#     rerun_list_contains element list
#
# Arguments:
#
# * element:     String element to check.
# * list:        A space separated list of elements.
#
# Notes:
#
# * Return 0 if element is contained in list.
# * Return 1 otherwise.


rerun_list_contains () {
    (( $# >= 2 )) || {
        rerun_die 'wrong # args: should be: rerun_list_contains element list'
    }
    local e
    for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
    return 1
}

#
# - - -
#

# _rerun_list_remove_ - remove element from list
#
#     rerun_list_remove element list
#
# Arguments:
#
# * element:     String element to remove.
# * list:        A space separated list of elements.
#
# Notes:
#
# * Returns  minus the element.
#
rerun_list_remove() {
    local -a retlist=() elements=(${@:2})
    for e in "${elements[@]:-}"
    do
        if [[ "$1" != "$e" ]]
        then
            [[ -z "${retlist:-}" ]] && retlist=( $e ) || retlist=( ${retlist[*]} "$e" )
        fi
    done
    echo "${retlist[@]:-}"
}

#
# - - -
#

# _rerun_list_index_ - get element index from list
#
#     rerun_list_index element list
#
# Arguments:
#
# * element:     String element to find.
# * list:        A space separated list of elements.
#
# Notes:
#
# * Returns  index number or -1 if not found.
#
rerun_list_index() {
    local element=$1
    local -a list=(${@:2})
    for ((index=0; index < ${#list[@]}; index++))
    do
        if [[ "${list[$index]}" == "$element" ]]
        then
            printf -- "%s" "$index"
            return 0
        fi
    done
    printf -- "-1"
}

#
# - - -
#

#
# _rerun_path_absolute_ - Returns the file name's absolute path.
#
#     rerun_absoluatePath file
#
# Arguments:
#
# * file:     File name.
#
# Notes:
#
# * File name can be relative.

rerun_path_absolute() {
    local -r infile="${1:-$0}"
    {
        if [[ "${infile#/}" = "${infile}" ]]; then
            echo "$(pwd)/${infile}"
        else
            echo "${infile}"
        fi
    } | sed '
    :a
    s;/\./;/;g
    s;//;/;g
    s;/[^/][^/]*/\.\./;/;g
    ta'
}

#
# - - -
#

# _rerun_property_get_ - Print the value for the specified metadata property.
#
#     rerun_property_get path  property
#
# Arguments:
#
# * directory:     Directory containing metadata.
# * property:      Property name.
# * expand:        Evaluate the property value in the environment. true|false (optional)
#
# Notes:
#
# * Prints property value.
# * Die, if directory not found.
# * Conditions: If metadata not found, nothing is returned.
#

rerun_property_get() {
    (( $# >= 2 )) || {
        rerun_die 'wrong # args: should be: rerun_property_get path property ?expand?'
    }
    local -r directory="$1" property="$2" expand="${3:-true}"
    [[ ! -f ${directory}/metadata ]] && rerun_die "metadata not found: ${directory}/metadata"

    if ! prop=$(grep "^$property=" "${directory}/metadata")
    then return 2; # Property does not exist in the metadata file.
    fi

    if [[ "$expand" == "true" ]]
    then (set +u; . "${directory}/metadata"; eval echo \$${property:-}; set -u)
    else echo "${prop#*=}"
    fi

    return 0
}

#
# - - -
#

# _rerun_property_set_ - Set the value for the specified metadata property.
#
#     rerun_property_set directory  property=value ?property=value?
#
# Arguments:
#
# * directory:     Directory containing metadata.
# * property:      Property name to assign value.
# * value:         A property value.
#
# Notes:
#
# * Multiple property assignments are made by specifying additional property=value bindings.
#
rerun_property_set() {
    (( $# < 2 )) && {
        rerun_die 'wrong # args: should be: rerun_property_set directory property=value ?property=value?'
    }
    local -r directory=$1
    local -a sed_patts=()
    shift ;
    while (( "$#" > 0 ))
    do
        local property=${1%=*} value=${1#*=} pattern

        if grep "^$property=" "$directory/metadata" >/dev/null
        then
            pattern=$(printf -- "-e s,%s=.*,%s=\"%s\"," "$property" "$property" "$value")
            [[ -z "${sed_patts:-}" ]] && sed_patts=( "$pattern" ) || sed_patts=( ${sed_patts[@]} "$pattern" )
        else
            echo "$property=\"$value\"" >> "$directory/metadata" || rerun_die "Failed adding property: $property"
        fi
        shift; # move to next property=value binding.
    done

    if (( ${#sed_patts[*]} > 0 ))
    then
        sed "${sed_patts[@]}" "$directory/metadata" \
            > "$directory/metadata.$$" || rerun_die  "Failed updating property data"
        mv "$directory/metadata.$$" "$directory/metadata" || rerun_die "Failed updating property data"
    fi

}


#
# - - -
#

# _rerun_script_lookup_ - Resolve the command script for specified command in module.
#
#     rerun_script_lookup directory command
#
# Arguments:
#
# * directory:     Module directory
# * command:       Command name
#
# Notes:
#
# * Returns path to command script, if one is found.
# * Searches for files in directory named `script`.
#   * Backwards compatability list: `default.sh`
rerun_script_lookup() {
    (( $# != 2 )) && {
        rerun_die 'wrong # args: should be: rerun_script_lookup directory command'
    }
    [[ ! -d $1 ]] && rerun_die "directory not found: $1"

    local -r module_dir="$1" command="$2"
    local -r command_dir="$module_dir/commands/${command}"

    local -a searchlist=( "$command_dir/script"  "$command_dir/default.sh" )
    for file in ${searchlist[*]}
    do
        if [[ -f  "$file" ]]
        then
            echo "$file"
            return 0
        fi
    done
    return 1
}

#
# - - -
#

# _rerun_script_exists_ - Checks resolved script for command exists.
#
#     rerun_script_exists directory command
#
# Arguments:
#
# * directory:     Module directory.
# * command:       Command name.
#
# Notes:
#
# * Return 0 if command script exists.
# * Return 1 otherwise.
#
rerun_script_exists() {
    (( $# != 2 )) && {
        rerun_die 'wrong # args: should be: rerun_script_exists directory command'
    }
    local -r module_dir="$1" command="$2"
    if [[ -f $(rerun_script_lookup "$module_dir" "$command") ]]
    then return 0
    else return 1
    fi
}

#
# ---
#

# _rerun_module_path_elements_
#
#     rerun_module_path_elements
#
# Arguments: Colon-separated directory search path.
#
rerun_module_path_elements() {
    (( $# != 1 )) && {
        rerun_die 'wrong # args: should be: rerun_module_path_elements path'
    }
    local path=${1}
    sed ':loop
{h
s/:.*//
p
g
s/[^:]*://
t loop
d
}' <<< "$path"

}

#
# - - -
#

# _rerun_module_exists_ - Searches for module and returns its directory if found.
#
#     rerun_module_exists module
#
# Arguments:
#
# * module:     Module name
#
# Notes:
#
# * It's a module if it has a `metadata` file in the subdirectory.
# * Give precedence to finding the module in $RERUN_MODULES.
# * If running an installed version of Rerun check the system location for the module:
rerun_module_exists() {
    (( $# != 1 )) && {
        rerun_die 'wrong # args: should be: rerun_module_exists module'
    }
    local -r module="$1"

    for path_element in $(rerun_module_path_elements "$RERUN_MODULES")
    do
        if [[ -f "$path_element/$module/metadata" ]]
        then
           echo "$path_element/$module"
           return 0
        fi
    done

    if [[ "${RERUN_LOCATION:-}" = "${RERUN_DEFAULT_BINDIR}" \
        && -f "${RERUN_DEFAULT_LIBDIR}/rerun/modules/$module/metadata" ]]
    then
       echo "${RERUN_DEFAULT_LIBDIR}/rerun/modules/$module"
       return 0
    fi

    echo ""
    return 1
}

#
# - - -
#

# _rerun_command_execute_ - Lookup command script and execute it.
#
#     rerun_command_execute module comand ?options?
#
# Arguments:
#
# * module:     Module name.
# * command:    Command name.
# * option:     Command options
# Notes:
#
# * Exit non zero, if command script is not found.
# * Command options are not required.
#
# Command scripts see the following environment variables:
#   RERUN, RERUN_VERSION, RERUN_MODULES, RERUN_MODULE_DIR, RERUN_COMMAND_DIR
#
# User specified a command that did not exist in the RERUN_MODULES directory.
#
# __Execution__
#
# Execute the command script if it is executable
# otherwise run it using the same shell as rerun.
# Return the command script's exit code as the result.
#

rerun_command_execute() {
    (( $# >= 2 )) || {
        rerun_die "wrong # args: should be: rerun_command_execute module command options"
    }
    local -r module="$1"
    local -r command="$2"
    shift; shift; # options are the remaining positional parameters.
    # Default the sudo command string
    local -r sudo_command="sudo -E"; # Needed for RERUN context variables and perhaps user's too.
                                  # The security policy may return an error if the user does
                                  # not have permission to preserve the environment.

    RERUN_MODULE_DIR=$(rerun_module_exists "$module") || rerun_syntax_error "module not found: \"$module\""

    rerun_script_exists "${RERUN_MODULE_DIR:-}" "$command" || {
        rerun_syntax_error "command not found: \"$module:$command\""
    }
    bash_shell=$(rerun_property_get "$RERUN_MODULE_DIR" SHELL)
    : "${command_exec:=$(which bash)}"; # default bash when module metadata does not declare SHELL.

    local -r RERUN_COMMAND_DIR=$RERUN_MODULE_DIR/commands/$command
    local -r RERUN_MODULE_VERSION=$(rerun_property_get "$RERUN_MODULE_DIR" VERSION)
    local -r script=$(rerun_script_lookup "$RERUN_MODULE_DIR" "$command")

    export RERUN RERUN_VERSION RERUN_MODULES RERUN_MODULE_DIR RERUN_MODULE_VERSION RERUN_COMMAND_DIR RERUN_COLOR RERUN_LOG_LEVEL

    local -a invocation_string

    if [[ -n "${RERUN_VERBOSE:-}" ]]
    then
        invocation_string=("$bash_shell" "$RERUN_VERBOSE" "$script" "$@")
    else
        if [[ -x "$script" ]]
        then
            invocation_string=("$script" "$@")
        else
            invocation_string=($bash_shell "$script" "$@")
        fi
    fi
    if [[ -n "${SUDO_USER:-}" ]]
    then
        invocation_string=("$sudo_command" -u "$SUDO_USER" "${invocation_string[@]}")
    fi
    #
    # Execute the command
    #
    "${invocation_string[@]}"
    return $?
}

#
# - - -
#

#
#
#  _- End public function library_.
#

# Check if this file is being sourced, or executed.
# If not being executed, return now.
if [[ "${BASH_SOURCE:-}" != "$0" && "$0" != "bash" ]]
then
    return; # Stop sourcing the file here.
fi

# The default system install directories.

RERUN_DEFAULT_BINDIR="/usr/bin"
RERUN_DEFAULT_LIBDIR="/usr/lib"


#
# Enable a stringent exeuction environment.
#
set -u ; # Exit if unassigned variable accessed.
set -e ; # Exit if command execution fails.


# - - -
# Private helper functions:
#

#
# __rerun_options_populate_ - generate a command argument string populating them with answer values
#
#
_rerun_options_populate() {
    (( $# < 2 )) && {
        echo >&2 "usage: _rerun_options_populate: module command ?answers?"
        return 2
    }
    local -r module=$1 command=$2 answers=${3:-}
    local -r module_dir=$(rerun_module_exists "$module") || rerun_syntax_error "module not found: \"$module\""
    local argline=() metadata option
    for cmd_option in $(rerun_options "$(dirname "$module_dir")" "$module" "$command")
    do
        metadata=$(dirname "$module_dir")/$module/options/$cmd_option/metadata
        local varname arg argval
        option=$(
            # shellcheck source=/dev/null
            . "$metadata"; # source the option metadata
            [[ -n "$LONG" ]] && flag="$LONG" || flag="$NAME"
            if [[ -r "$answers" ]]
            then
                varname=$(echo "$NAME" | tr a-z A-Z | tr "-" "_")
                arg=$(grep "^${varname}=" "$answers")
                argval=${arg#*=}
            fi
            [[ -n "$arg" ]] && printf -- "--%s %s" "$flag" "${argval}"
        )
        argline+=("$option")
    done
    echo "${argline[@]:-}"
}



#
# __rerun_banner_ - Prints logo and version info with a rainbow of colors!
#
# Notes:
#
# * Prints ANSI color codes into your output
_rerun_banner() {
    if [[ -n "${RERUN_COLOR:-}" ]]
    then
    echo $(tput setaf 1) " _ __ ___ _ __ _   _ _ __"
    echo $(tput setaf 2) "| '__/ _ \ '__| | | | '_ \ "
    echo $(tput setaf 3) "| | |  __/ |  | |_| | | | |"
    echo $(tput setaf 4) "|_|  \___|_|   \__,_|_| |_|"
    echo $(tput setaf 5) "Version: ${RERUN_VERSION:-}. License: Apache 2.0."$(tput sgr0)
    else
    echo " _ __ ___ _ __ _   _ _ __"
    echo "| '__/ _ \ '__| | | | '_ \ "
    echo "| | |  __/ |  | |_| | | | |"
    echo "|_|  \___|_|   \__,_|_| |_|"
    echo "Version: ${RERUN_VERSION:-}. License: Apache 2.0."
    fi
}


#
# __rerun_examples_ - Print usage examples
#
#
_rerun_examples() {
    (( $# != 1 )) && {
        rerun_die "wrong # args: should be: _rerun_examples prog"
    }
    local -r prog=$1
    echo >&2 "Examples:"
echo "
| # List installed modules:
| \$ $prog
| # List  commands:
| \$ $prog stubbs
| # Execute a command:
| \$ $prog stubbs:add-module --module freddy"
}

#
# __rerun_man_page_ - Show man page for the module
#
# Notes:
#
# * Each module can have a Unix man page.
# * Use stubbs:docs to generate the man page if one doesn't
# already exist. Display the man page with `nroff`.

_rerun_man_page() {
    (( $# != 1 )) && {
        rerun_die "wrong # args: should be: _rerun_man module"
    }
    local -r module=$1
    for path_element in $(rerun_module_path_elements "$RERUN_MODULES")
    do
        if [[ ! -f "$path_element/$module/$module.1"
                && -f "$path_element/stubbs/commands/docs/script" ]]
        then ${RERUN:-rerun} stubbs:docs --module "$module"
        fi
        if [[ -f "$path_element/$module/$module.1" ]]
        then nroff -man "$path_element/$module/$module.1" | ${PAGER:-more}
        else echo >&2 "Manual could not be generated."
        fi
    done
}

PAD="  "

# __rerun_module_summary_ - Print a module summary.
#
# Arguments
#
# * directory: Module directory
#
_rerun_module_summary() {
    (( $# != 1 )) && {
        rerun_die "wrong # args: should be: _rerun_module_summary module_dir"
    }
    local -r module_dir=$1
    local module_name module_desc module_vers
    if rerun_module_exists "$(basename "$module_dir")"
    then
        module_name=$(basename "$module_dir")
        module_desc=$(rerun_property_get "$module_dir" DESCRIPTION)
        module_vers=$(rerun_property_get "$module_dir" VERSION) || module_vers=""
        printf "%s%s: \"%s\" - %s (%s)\n" "${PAD:-}" \
            "$(rerun_color yellow "$module_name")" \
            "$(rerun_color bold "${module_desc}")" \
            "$module_vers" \
            "$module_dir"
    fi
}

# __rerun_modules_summary_ - List the modules.
#
# Arguments
#
# * path: Path to directories containing modules
#
# Notes:
#
# * When rerun is installed in the system location
# and rerun modules is different to the system location,
# then list the system installed ones separately.
#
_rerun_modules_summary() {
    (( $# != 1 )) && {
        rerun_die "wrong # args: should be: _rerun_modules_summary directory"
    }
    printf "%s\n" "$(rerun_color blue "Available modules:")"

    shopt -s nullglob # enable
    set +u
    for directory in $(rerun_module_path_elements "$1")
    do
        for module in $directory/*
        do
            [[ -f "$module/metadata" ]] && _rerun_module_summary "$module"
        done
        if [[ ${RERUN_LOCATION:-} = "${RERUN_DEFAULT_BINDIR}"
                && $path_element != "${RERUN_DEFAULT_LIBDIR}/rerun/modules" ]]
        then
            echo
            printf "%s\n" "$(rerun_color blue "Available modules in \"${RERUN_DEFAULT_LIBDIR}/rerun/modules\":")"
            for module in ${RERUN_DEFAULT_LIBDIR}/rerun/modules/*
            do
               [[ -f "$module/metadata" ]] && _rerun_module_summary "$module"
            done
        fi
    done
    set -u
}

#
# __rerun_commands_summary_ - List commands
#
#
_rerun_commands_summary() {
    (( $# != 2 )) && {
        rerun_die "wrong # args: should be: _rerun_commands_summary directory module"
    }
    local -r directory=$1
    local -r module=$2

    local -r module_dir=$(rerun_module_exists "$module") || rerun_syntax_error "module not found: \"$module\""
    printf "%s\n" "$(rerun_color blue "Available commands in module, \"$module\":")"
    shopt -s nullglob # enable
    local cmd_name metadata
    for cmd in $module_dir/commands/*/metadata
	do
        cmd_name=$(basename "$(dirname "$cmd")")
        metadata=$module_dir/commands/${cmd_name}/metadata
        [[ -f "$metadata" ]] && cmd_desc=$(rerun_property_get "$(dirname "$cmd")" DESCRIPTION)
        printf "%s\n" "$(rerun_color bold "${cmd_name}: \"${cmd_desc}\"")"
        if [[ -d "$module_dir/commands/${cmd_name}" ]]
        then
            #
            # List the command options
            local -a options=( $(rerun_options "$(dirname "$module_dir")" "$module" "$cmd_name") )
            [[ -z "${options:-}" ]] && continue
            for opt in "${options[@]}"
            do
                local opt_metadata=$module_dir/options/${opt}/metadata
                if [[ -r "$opt_metadata" ]]
                then
                (   set +u
                    argstring="" summary=""
                    # shellcheck source=/dev/null
                    . "$opt_metadata" ; # Read the option's metadata.
                    if [[ -n "${SHORT}" ]]; then
                       argstring=$(printf ' --%s|-%s'  "$NAME" "$SHORT")
                    else
                       argstring=$(printf " --%s" "$NAME" )
                    fi
                    [[ "$ARGUMENTS" == "true" ]] && {
                        # Lookup the default but set expand=false to not evalute possible variable.
                        DEFAULT=$(rerun_property_get "$module_dir/options/${opt}" DEFAULT false)
                        argstring=$(printf "%s <%s>" "$argstring" "$(rerun_color ul "${DEFAULT}")")
                    }
                    if [[ "$REQUIRED" != "true" ]]; then
                        summary=$(printf "[%s]: \"%s\"" "${argstring}" "$DESCRIPTION")
                    else
                        summary=$(printf "%s: \"%s\"" "${argstring}" "$DESCRIPTION")
                    fi
                    echo -e "$PAD $summary"
                    set -u
                )
                else
                    # limited usage summary.
                    echo -e "$PAD --$opt <>: \"no description\"";
                fi
            done
        fi
    done

}


# Parse rerun command line options
# --------------------------------

export RERUN_VERBOSE=

# There are two sets of options, `rerun` specific arguments
# and command options.

while (( "$#" > 0 )); do
    OPT="$1"
    case "$OPT" in
	-h*|--h*)
        _rerun_banner
        ! rerun_option_usage
        _rerun_examples "$(basename "$0")"
        exit 0
	    ;;
	--banner)  _rerun_banner ; exit 0
	    ;;
  	-G)
	    export RERUN_COLOR="true"
	    ;;
	-v)
        RERUN_VERBOSE="-vx"
	    ;;
    -x)
        RERUN_VERBOSE="-x"
        ;;
  	-V)
	    RERUN_VERBOSE="-vx"
	    set -vx
	    ;;
  	--version)
	    echo >&2 "$RERUN_VERSION"
            exit 0
	    ;;
	--man*)
	    rerun_option_check "$#" "$1"
	    _rerun_man_page "$2"
	    exit 0
	    ;;
	--loglevel)
            rerun_option_check "$#" "$1"
            rerun_log level "$2"
            shift
            ;;
	-M)
	    rerun_option_check "$#" "$1"
	    RERUN_MODULES=$(rerun_path_absolute "$2")
	    shift
	    ;;
	-A|--answer[s]*)
	    rerun_option_check "$#" "$1"
	    ANSWERS="$2"
        [[ ! -f $ANSWERS ]] && rerun_syntax_error "answers file not found: $ANSWERS"
	    shift
	    ;;
	-S|--sudo-user)
            rerun_option_check "$#" "$1"
            SUDO_USER="$2"
            shift
            ;;
	*)
	    break;# Ignore remaining arguments as they are for the module.
    esac
    shift
done


# Set the absolute path to this invocation of the rerun script. Drives the Linux FSH usage convention where
# modules located in ${RERUN_DEFAULT_LIBDIR}/rerun/modules are appended to the modules in RERUN_MODULES.
RERUN_LOCATION="$(cd "$(dirname "${BASH_SOURCE[0]:-}" )" && pwd)"
# fix issue #206
if [[ -x /usr/bin/readlink && "$(uname)" == 'Linux' ]]; then
    RERUN_LOCATION=$(/usr/bin/readlink -f "$RERUN_LOCATION")
fi

# Default the RERUN_MODULES environment variable.
# If it is not set, then default it to either the system
# install location or relative to the rerun executable.
# TODO: add a unit test for this.

if [[ -z "${RERUN_MODULES:-}" ]]
then
    if [[ "$RERUN_LOCATION" = "${RERUN_DEFAULT_BINDIR}" ]]
    then
      RERUN_MODULES="${RERUN_DEFAULT_LIBDIR}/rerun/modules";
    else
      RERUN_MODULES=${RERUN_LOCATION}/modules; # Set module directory relative to the `rerun` script:
    fi
fi


# Ensure the modules directory path is defined and at least one element is a directory.
#
[[ -n "${RERUN_MODULES:-}" ]] || {
    rerun_die "RERUN_MODULES is not defined"
}
__rerun_module_has_valid_dir__=1
for path_element in $(rerun_module_path_elements "$RERUN_MODULES")
do
    if [[ -d "$path_element" ]]
    then
        __rerun_module_has_valid_dir__=0
        break
    fi
done
[[ $__rerun_module_has_valid_dir__ = 0 ]] || {
    rerun_die "RERUN_MODULES does not contain any valid directories: $RERUN_MODULES"
}

# Clear MODULE and COMMAND in case they were incidentally declared in the environment.

MODULE="" COMMAND=""

# Parse rerun command and their options.
# Use regex to split up command strings.
if [[ "$@" =~ ([^:]+)([:]?[ ]?)([-A-Za-z0-9_]*)([ ]*)(.*) ]]
then
    MODULE=${BASH_REMATCH[1]};     # module
    [ "${BASH_REMATCH[2]}" == ': ' ] && shift ; # eat the extra space char
    COMMAND=${BASH_REMATCH[3]/ /}; # command
    #- BASH_REMATCH[4] contains the whitespace separating command and options.
    #- BASH_REMATCH[5] contains command options.
else
    [[ -n "${1:-}" ]] && MODULE=${1/:/};   # module (minus colon)
fi
# Shift over so the remaining arguments are left to the command options.
(( "$#" > 0 )) && shift;

# Read answer file and set positional parameters from them.
if [[ -n "${ANSWERS:-}" && -f "${ANSWERS:-}" ]]
then
    eval set -- "$@" "$(_rerun_options_populate "$MODULE" "$COMMAND" "$ANSWERS")"
fi




#
# Execute rerun
# ===============

# Summary: module or command
# --------------------------
#
# **rerun** provides two listing modes: module and commands.
# If a user specifies `rerun` without arguments, a listing
# of module names and their descriptions is displayed.
# If a user specifies a module name: `rerun <module>`,
# then a listing of commands and their options are displayed.
#
# If no module or command are specified, display a listing of modules, showing each
# module's name and description. Modules are read from the directory referenced
# using the `$RERUN_MODULES` environment variable.

if [[ -z "$MODULE" && -z "$COMMAND" ]]
then

    _rerun_modules_summary "$RERUN_MODULES"

    exit 0

# If a module name is specified, show the command set.
# For each command, show that command's option list in summary form
# displaying requirement, name, flags, defaults and description.

elif [[ -n "$MODULE" && -z "$COMMAND" ]]
then

    _rerun_commands_summary "$RERUN_MODULES" "$MODULE"

    exit 0

fi

#
# - - -
#

# Execute script
# ----------------
#
# Set the `RERUN` environment variable so subsequent
# invocations can use the same executable.
#
RERUN=$(rerun_path_absolute "$0")
export RERUN
#

#
# Execute the specified command.
# The remaining positional parameters are passed as command options.
#
rerun_command_execute "$MODULE" "$COMMAND" "$@"

#
# Exit rerun with the script execution's exit code.
exit $?
# - - -
# Done!


# More
# ----

# _(c) 2012-2018 Alex Honor - Apache 2 License_
]==]
