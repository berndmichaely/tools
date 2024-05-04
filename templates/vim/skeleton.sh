#!/usr/bin/env bash

# Set a sane/secure path
PATH='/usr/local/bin:/bin:/usr/bin'
# It's almost certainly already marked for export, but make sure
\export PATH

# Clear all aliases. Important: leading \ inhibits alias expansion.
\unalias -a

# Clear the command path hash
hash -r

# Set the core dump limit to 0
ulimit -S -c 0 --

# Set a sane/secure IFS (note this is bash & ksh93 syntax only--not portable!)
IFS=$' \t\n'

# Set a sane/secure umask variable and use it
# Note this does not affect files already redirected on the command line
# 022 results in 0755 perms, 077 results in 0700 perms, etc.
UMASK=027
umask $UMASK

until [ -n "$temp_dir" -a ! -d "$temp_dir" ]; do
    temp_dir="/tmp/${USER}/meaningful_prefix.${RANDOM}${RANDOM}${RANDOM}"
done
mkdir -p -m 0700 $temp_dir \
  || { echo "FATAL: Failed to create temp dir '$temp_dir': $?" ; exit 100 ; }

# Do our best to clean up temp files no matter what
# Note $temp_dir must be set before this, and must not change!
cleanup="rm -rf $temp_dir"
trap "$cleanup" ABRT EXIT HUP INT QUIT

# Expand patterns, which match no files, to a null string, rather than themselves
shopt -s nullglob

# color code definitions:
declare -A colors
colors[gray]='\e[90m'
colors[red]='\e[91m'
colors[green]='\e[92m'
colors[orange]='\e[33m'
colors[blue]='\e[94m'
colors[magenta]='\e[95m'
colors[cyan]='\e[96m'
colors[reset]='\e[0m'

# Usage: color [-n] <color-code> arg ...
# Echo arguments in a given color
# -n works like for echo
function color
{
	newline=true
	if [ "$1" = '-n' ] ; then
		newline=false
		shift
	fi
	echo -ne "${colors[$1]}"
	shift
	echo -ne "$@${colors[reset]}"
	if $newline ; then
		echo
	fi
}

# Check availability of command »$1«.
# Optionally retrieve version of this command by either:
# parameters to the command »$1« given as »$2..$n« or:
# a shell function in »$2«.
function check_cmd
{
	if [ $# -ge 1 ] ; then
		if [ "`type -t -- $1`" = 'builtin' ] ; then
			color -n gray '· Using builtin' ; color orange " $1"
		else
			cmd="`type -p $1`"
			cmd_ver=''
			if [ -n "$cmd" ] ; then
				if [ $# -ge 2 ] ; then
					shift
					if [ "`type -t -- $1`" = 'function' ] ; then
						cmd_ver=" (`$@`)"
					else
						cmd_ver=" (`$cmd $@`)"
					fi
				fi
				color -n gray '· Using' ; echo -n " ${cmd}" ; color gray "${cmd_ver}"
			else
				echo "»${1}« not found! Please install first. Stop."
				exit 254
			fi
		fi
	else
		echo "Warning: function »check_cmd«: you gave me nothing to check, ignoring…"
	fi
}

# check availability of commands needed by the script:

# examples:

function get_ffmpeg_version
{
	# select third word of output
	ffmpeg -version | head -n 1 | sed -E 's/^(\S+\s+){2}(\S+).*/\2/'
}

function check_necessary_commands
{
	check_cmd svn --version --quiet
	check_cmd ffmpeg get_ffmpeg_version
	check_cmd getopt
	check_cmd getopts
	check_cmd true
	check_cmd false
}

function show_usage
{
	color -n orange 'USAGE: '
	color gray "`basename $0` [options]"
	echo '       Show a greeting on stdout.'
	echo
	color orange 'OPTIONS:'
	echo
	color -n blue '-h : ' ; echo 'show this help message'
	color -n blue '-r : ' ; echo 'run the action'
	color -n blue '-v : ' ; echo 'be verbose'
	color -n blue '-V : ' ; echo 'show script version and exit'
}

function show_version
{
	version='1.0'
	if $be_verbose ; then
		echo "`basename $0` ${version}"
	else
		echo "$version"
	fi
	exit
}

# example script action:
function greeting
{
	if [ $verbosity_level -ge 2 ] ; then
		echo "Hello ${USER^}, hello world!"
	else
		echo "Hello ${USER^}!"
	fi
	if $be_verbose ; then
		echo "Available colors:"
		for c in ${!colors[@]} ; do
		if [ $c != reset ] ; then
			color $c "· $c"
		fi
		done
	fi
	exit
}

# global verbosity level:
be_verbose=false
verbosity_level=0

# script specific action:
declare action

while getopts 'hrvV' arg
do
	case "$arg" in
		h) action=show_usage ;;
		r) action=greeting ;;
		v) be_verbose=true ; ((verbosity_level++)) ;;
		V) action=show_version ;;
		?)
			show_usage
			exit 1
			;;
	esac
done
shift $(($OPTIND - 1))

if $be_verbose ; then
	check_necessary_commands
fi

# run the script specific action:

if [ -n "$action" ] ; then
	$action
else
	show_usage
	exit 1
fi
