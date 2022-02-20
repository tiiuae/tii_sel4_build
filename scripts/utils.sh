#!/bin/sh

#set -xe
set -e

# Sources/inspirations for these functions:
# https://www.etalabs.net/sh_tricks.html
# https://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html
#

# Boilerplate utilities
#
yell() { printf "%s: %s\n" "$0" "$*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

# Function to test number of input arguments.
# First parameter is the number of arguments
# required, and second is all arguments "$@".
# This will use the shell builtin(s) to get
# number of input arguments, and test if there
# are enough arguments given. If not, this
# will print an error message to stderr and
# exits with an error code.
#
# Usage:
#
# min_args <required-num-of-args> "$@"
#
min_args()
{
    local MIN="$1"
    local NUM="$(($# - 1))"
    if test $NUM -lt $MIN; then
        die "Not enough arguments, "$NUM" < "$MIN""
    fi
}

# Function to save arguments to an array. 
# Standard POSIX shell does not have array type, 
# so it's extremely cumbersome to store arbitrary 
# number of arguments in an array and restoring
# them later. This function generates the "array"
# automatically for any number of args.
# 
# Usage:
#
# myargs=$(save_args "$@")
# ...
# Restoring args:
# 
# eval "set -- $myargs"
#
# save_args() 
# {
#     # Brief sed-to-english:
#     #
#     # First substitution:
#     # Escape all single quotes, and wrap the 
#     # escaped quote in single quotes (' -> '\'').
#     #
#     # Second substitution:
#     # Insert single quote to the start of the
#     # argument string (ONLY on the first line 
#     # of argument).
#     # 
#     # Third substitution:
#     # Insert single quote, space and a slash 
#     # to the end of the argument string 
#     # (ONLY on the last line of argument).
#     #
#     for arg in "$@"; do
#         # printf %s\\n "$arg" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/' \\\\/"
#         printf %s\\n "$arg" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"
#     done
#     # echo " "
# }

# Function to parse arguments.
# 
# Usage:
# parse_args <parsed-args> <other-args> -s <search-1> -s <search-2> ARGS
#
# * parsed-args: Array nameref where to return successfully parsed args.
# * other-args:  Array nameref where to return unmatched args.
# * -s search-1: String to search for in the passed arguments.
# * -s search-1: String to search for in the passed arguments.
# * ARGS:        Argument list to parse.
#
# Multiple search strings can be defined with the -s option. At least 1
# search string must be defined.
#
# The function searches the ARGS array, and if a string passed with -s
# option is found within the ARGS, the search string value is stored into
# the parsed-args array. All other args which did not match any string 
# value(s), are store into the other-args array.
#
# parse_args()
# {
#     local -n FOUND_ARGS=$1
#     shift
#     local -n OTHER_ARGS=$1
#     shift
# 
#     local SEARCH_PATTERNS=()
#     local INPUT_ARGS=()
#     local SKIP=false
# 
#     for ARG in "$@"; do
#       if $SKIP; then 
#         SKIP=false
#         continue
#       fi
#       case "$ARG" in
#         -s)
#           shift
#           if test -z "$1"; then
#             die "ERROR: option -s needs non-empty argument"
#           fi
#           SEARCH_PATTERNS+=("$1")
#           SKIP=true
#           ;;
#         *)
#           INPUT_ARGS+=("$ARG")
#           ;;
#       esac
#       shift
#     done
# 
#     local GREP_PATTERN=$(IFS="|$IFS"; printf '%s\n' "${SEARCH_PATTERNS[*]}")
#     
#     for ARG in "${INPUT_ARGS[@]}"; do
#       if printf '%s\n' "$ARG" | grep -xqE "$GREP_PATTERN"; then
#         FOUND_ARGS+=("$ARG")
#       else
#         OTHER_ARGS+=("$ARG")
#       fi
#     done
# }