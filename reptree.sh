#!/bin/bash
# Date: 2023-12-20
# Author: Kevin Repking
# version: 4.1.0 - added eval with array to account for file/dir names with spaces.
# 


help_doc() {
  echo "Usage: reptree [OPTIONS] [directory]"
  echo ""
  echo "OPTIONS:"
  echo "  -d <n>	depth or layers of directory tree to display;"
  echo "		n is any positive integer (default with -d is 3)"
  echo ""
  echo "  -a		display hidden files and directories (excluding . ..)"
  echo ""
  echo "  -f		diplay facl (permission) values for files and directories."
  echo ""
  echo "  -h		displays this help information"
  echo ""
  echo "directory:"
  echo "  any directory using full path that is accessible by current user"
  echo "  (default uses current working directory)"
  echo ""
  echo "reptree is an attermpt to recreate the tree command which displays"
  echo "the file system in a branching (tree) pattern."
  echo ""
  exit 33
}

#
# Display a specific error message when it appears users attempted
# to give invalid options or directory.
#
arg_error() {
  echo ""
  echo "*ERROR: $1 is not a valid directory or option"
  echo "try -h for help"
  echo ""
  exit 2
}

#
# Set defaults for variables when no options or directory are given.
# note: DEPTH is set to double the actual/intended depth because the
# value is also used as the indentation size through the recursion.
#
ls_option=''
TEMP_TREE_START_LOC="."
TEMP_TREE_MAX_DEPTH=6

#
# Check for option and/or directory arguments, and set
# variables accordingly.
#
while [ $# -gt 0 ];
  do
  case $1 in
    (-a)
      ls_option='A';
      shift;
      ;;
    (-d)
      [ -n "${2##*[!0-9]*}" ] \
        && { TEMP_TREE_MAX_DEPTH=$(( $2 * 2 )); shift; shift; } \
	|| { echo "Incorrect or No Depth value given."; \
             echo " try -h for help."; exit 2; }
        ;;
    (-h)
      help_doc;
      ;;
#    (-f)
#      facl_setting='1';
#      shift;
#      ;;
    (-*)
      arg_error "$1";
      ;;
    (*)
      ls "$1" &> /dev/null \
      && { TEMP_TREE_START_LOC=$1; shift; } \
      || arg_error "$1";
      ;;
  esac
  done

#
# This is the recursive function that will walk through the file system
# sub-directories. It will check if a file is a directory and also if
# that directory is accessible. If those check pass and the depth limit
# has not been reached, the function will get called again with that
# directory as the main argument.
# If the directory is not accessible by the current user, it will be
# displayed in red and identified as such.
# If the file is not a directory, it will simply display the current
# file and move on to the next file for checking.
# The default color for directory is 33.
# The default color for innaccessible directory is 31.
# The default color for regular file is 36.
# The default color for tree unicode is 35.
# Directories are denoted with \u2515 (L shaped unicode character)
# with \u2509 (thick dotted line).  A '~' at the end assists
# with readability.
# Regular files are denoted with \u251c (sideways T shaped unicode
# character) with \u2508 (thin dotted line).
# * Latest update adds array 'dirs' with eval to detect quoted
# strings from ls command.  Shell quoting option is used for eval.
# Previously we just used the ls command in the initial for loop.
# This produced errors for files/directories with spaces in the
# name (shouldn't exist anyway). Directories were being seen as
# multiple regular files, and single regular files were being
# split into as many files as space separated words in the file name.
#
recursive_tree() {
  [ $TEMP_TREE_MAX_DEPTH == $2 ] && return
  eval dirs=(`ls -1 --quoting-style=shell ${ls_option} "${1}"`);
  for i in "${dirs[@]}";
  do [ -d "$1/${i}" ] && ! [ -L "$1/${i}" ] && {
    ls "$1/${i}" &> /dev/null \
      && {
        printf %$2.0s"\033[35m┕┉"; \
        printf "\033[33m"; echo "${i} ~"; \
        recursive_tree "$1/${i}" $(( $2 + 2 )); \
      } \
      || {
        printf %$2.0s"033[35m┕┉"; \
        printf "\033[31m"; echo "${i} ~ directory inaccessible"; \
      }
    } || {
        printf %$2.0s"\033[35m├┈"; \
        printf "\033[36m"; echo "${i}"; \
    }
  done
}

#recursive_tree() {
#  [ $TEMP_TREE_MAX_DEPTH == $2 ] && return
#  for i in `ls ${ls_option} "$1"`;
#  do [ -d "$1/${i}" ] && ![ -L "$1/${i}" ] && {
#    ls "$1/${i}" &> /dev/null \
#      && {
#        printf %2.0s"\033[35m┕┉"; display_facl "$1/${i}"; \
#        printf "\033[33m"; echo ${i}" ~"; \
#        recursive_tree "$1/{i}" $(( $2 + 2 )); \
#      } \
#      || {
#        printf %2.0s"033[35m┕┉"; display_facl "$1/${i}"; \
#        printf "\033[31m"; echo ${i}" ~ directory inaccessible"; \
#      }
#    } || {
#        printf %2.0s"\033[35m├┈"; display_facl "$1/${i}"; \
#        printf "\033[36m"; echo ${i}; \
#    }
#  done
#}


#
# This is the main call to the function. '0' is given as the initial
# second argument as this value is used in the function to test how
# "deep" the recursion has gone in comparison to the value set
# by TEMP_TREE_MAX_DEPTH.
#
recursive_tree $TEMP_TREE_START_LOC 0

#
# This sets character colorization back to 0.
#
printf "\033[0m"

#
# Successful completion of program
#
exit 0

#EOF
