#!/bin/sh
# xorriso-inspired parsing functions

XPARSE_DEBUG="${XPARSE_DEBUG:-0}"
[ "${XPARSE_DEBUG}" = "1" ] && set -eu

XPARSE_DEFAULTS="${XPARSE_DEFAULTS:-1}"

# EXAMPLES:
# xparse_add_option hello 0 do_hello
#     makes an option '-hello' that takes 0 args and runs do_hello
#
# xparse_add_option print 1 do_print
#     makes an option '-print' that takes 1 arg and runs do_print with it
#
# xparse_add_option add '*' do_add
#     makes an option '-add' that takes an arbitrary number of arguments up
#     until the separator in $XPARSE_SEPARATOR and runs do_add with them
#     (can be changed by user with '-list_delimiter')

XPARSE_FS="$(printf "\034")"
XPARSE_NL="$(printf "\nx")"
XPARSE_NL="${XPARSE_NL%x}"
XPARSE_SEPARATOR="--"

XPARSE_ARGS=""
# Convert positional args to a string
# args: ARG...
xparse_split_args() {
    # {{{
    XPARSE_ARGS=""
    for arg in "$@"; do
        XPARSE_ARGS="${XPARSE_ARGS}$( printf "%s%s" "${arg}" "${XPARSE_FS}" )"
    done
} # }}}

# Remove first NUM args from XPARSE_ARGS
# args: NUM
xparse_shift_args() {
    # {{{
    local NUM="${1}"
    for i in $(seq 1 "${NUM}"); do
        XPARSE_ARGS="$( printf "%s" "${XPARSE_ARGS}" | sed "s/^[^${XPARSE_FS}]*${XPARSE_FS}//" )"
    done
} # }}}

XPARSE_OPTIONS=""
# Add option signature
# args: OPT_NAME  ARGS_TYPE  FUNCTION
xparse_add_option() {
    # {{{
    local  OPT_NAME="${1}"
    local ARGS_TYPE="${2}"
    local  FUNCTION="${3}"

    { ! xparse_is_option "${OPT_NAME}"; } || \
        { printf "[E]: XParse: Option redefiniton: -%s\n" "${OPT_NAME}" >&2; exit 1; }

    XPARSE_OPTIONS="${XPARSE_OPTIONS}${ARGS_TYPE}:${OPT_NAME}:${FUNCTION}${XPARSE_NL}"
} # }}}

# Execute an option based on signature
# Notes: unsets IFS
# args: OPT_NAME
xparse_exec_option() {
    # {{{
    local OPT_NAME="${1}"

    local OPT_LINE
    OPT_LINE="$(printf "%s" "${XPARSE_OPTIONS}" | grep -F ":${OPT_NAME}:")"

    local ARGS_TYPE
    local  FUNCTION
    ARGS_TYPE="$(printf "%s\n" "${OPT_LINE}" | sed 's/:.*$//')"
     FUNCTION="$(printf "%s\n" "${OPT_LINE}" | sed 's/^.*://')"

    local FUNCTION_ARGS=""
    IFS="${XPARSE_FS}"

    if [ "${ARGS_TYPE}" != '*' ]; then
        local ARGS_NUM="${ARGS_TYPE}"
        local  ARG_IDX="0"

        for arg in ${XPARSE_ARGS}; do
            [ "${ARG_IDX}" -lt "${ARGS_NUM}" ] || break
            FUNCTION_ARGS="${FUNCTION_ARGS}${arg}${XPARSE_FS}"
            xparse_shift_args 1
            ARG_IDX="$((ARG_IDX + 1))"
        done

        [ "${ARG_IDX}" -ge "${ARGS_NUM}" ] || {
            printf "[E]: Wrong argument count! Expected %s, but got %s.\n" \
                "${ARGS_NUM}" "${ARG_IDX}" >&2
            exit 1
        }
    else
        local ARGS_TERMINATED="0"

        for arg in ${XPARSE_ARGS}; do
            [ "${arg}" != "${XPARSE_SEPARATOR}" ] || {
                ARGS_TERMINATED="1"
                xparse_shift_args 1
                break
            }

            FUNCTION_ARGS="${FUNCTION_ARGS}${arg}${XPARSE_FS}"
            xparse_shift_args 1
        done

        [ "${ARGS_TERMINATED}" = "1" ] || {
            printf "[E]: Argument list not terminated with \"%s\"!\n" "${XPARSE_SEPARATOR}" >&2
            exit 1
        }
    fi

    [ "${XPARSE_DEBUG}" = "1" ] && {
        printf "[I]: " >&2
        printf "%s " "${FUNCTION}" ${FUNCTION_ARGS} >&2
        printf "\n" >&2
    }

    "${FUNCTION}" ${FUNCTION_ARGS}

    unset IFS
} # }}}

# Check if a signature exists for an option
# args: OPT_NAME
xparse_is_option() {
    # {{{
    local OPT_NAME="${1}"
    printf "%s" "${XPARSE_OPTIONS}" |  grep -F ":${OPT_NAME}:" >/dev/null 2>&1
} # }}}

# Execute defined options on passed in args
# args: ARG...
xparse_execute_args() {
    # {{{
    xparse_split_args "$@"

    while true; do
        [ -n "${XPARSE_ARGS}" ] || break

        local OPT_NAME
        OPT_NAME="$(printf "%s" "${XPARSE_ARGS}" | sed "s/${XPARSE_FS}.*//")"
        OPT_NAME="${OPT_NAME#-}"
        xparse_shift_args 1

        if xparse_is_option "${OPT_NAME}"; then
            xparse_exec_option "${OPT_NAME}"
        else
            printf "[E]: Not an option!: %s\n" "${OPT_NAME}" >&2
        fi
    done
} # }}}

if [ "${XPARSE_DEFAULTS}" = "1" ]; then
    # NOTE: Default option
    # without it, the cli interface only accepts the default separator
    xparse_do_list_delimiter() { XPARSE_SEPARATOR="${1}"; }
    xparse_add_option list_delimiter  1 xparse_do_list_delimiter

    # NOTE: Default option
    # prints all defined options
    xparse_do_list_options() {
        printf "Options:\n"
        IFS="${XPARSE_FS}"
        for OPT_LINE in ${XPARSE_OPTIONS}; do
            printf "%s" "${OPT_LINE}" | \
                sed 's/^\([^:]\+\):\([^:]\+\):.*$/  -\2 (\1)/'
        done
        unset IFS
        exit 0
    }
    xparse_add_option list_options 0 xparse_do_list_options
fi
