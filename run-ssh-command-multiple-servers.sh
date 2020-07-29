#!/bin/bash

#
# For a faster run please copy your ssh public key to the remote servers
#
# A list of servers needs to be create prior using this script. The name of the file is sever_list and 
# it should contain one entry/line (either server ip or hostname)
#
# If you want to run a specific command and pipe multiple arguments to it use the example bellow:
# ./run-ssh-everywhere.sh -u ssh_user "rpm -qa | grep kernel"
#
# A password can be supplied as argument while executing the script (in case you don't have a ssh key 
# and to avoid being prompted to enter password
# ./run-ssh-everywhere.sh -u ss_huser -p ssh_password "rpm -qa | grep kernel"
# 

# list of servers, one server ip/hostname per line
SERVER_LIST='server_list'

# some additional options for the ssh command
SSH_OPTIONS='-o ConnectTimeout=3 -o StrictHostKeyChecking=no'

# get current user
USER="$(whoami)"

usage() {
  # display usage and exit
  echo "Usage: ${0} [-nsv] [-u USER] [-f FILE] COMMAND" >&2
  echo 'Executes COMMAND as a single command on every server.' >&2
  echo "  -f FILE  Use FILE for the list of servers. Default: ${SERVER_LIST}." >&2
  echo "  -u USER  Connect via ssh with the specifid user rather than localuser. Default: ${USER}." >&2
  echo "  -p PASS  Connect via SSH with the password provided as argument to the script. Default: ${PASS}." >&2
  echo '  -n       Dry run mode. Display the COMMAND that would have been executed and exit.' >&2
  echo '  -s       Execute the COMMAND using sudo on the remote server.' >&2
  echo '  -v       Verbose mode. Displays the server name before executing COMMAND.' >&2
  exit 1
}

# make sure the script is not being executed with superuser privileges.
if [[ "${UID}" -eq 0 ]]
then
  echo 'Do not execute this script as root. Use the -s option instead.' >&2
  usage
fi

# parse script options
while getopts f:u:p:nsv OPTION
do
  case ${OPTION} in
    f) SERVER_LIST="${OPTARG}" ;;
	u) USER="${OPTARG}" ;;
    p) PASS="${OPTARG}" ;;
    n) DRY_RUN='true' ;;
    s) SUDO='sudo' ;;
    v) VERBOSE='true' ;;
    ?) usage ;;
  esac
done

# if no user is specified (-u user) then login via ssh as the current user
if [[ ! -e "${USER}" ]]
then
  USER="$USER"
fi

# remove the options while leaving the remaining arguments
shift "$(( OPTIND - 1 ))"

# if no argument is supplied print help
if [[ "${#}" -lt 1 ]]
then
  usage
fi

# anything that remains on the command line is to be treated as a single command.
COMMAND="${*}"

# make sure SERVER_LIST file does exist
if [[ ! -e "${SERVER_LIST}" ]]
then
  echo "Cannot open server list file ${SERVER_LIST}." >&2
  exit 1
fi

# define exit status as 0 (successfull)
EXIT_STATUS='0'

# loop through the SERVER_LIST
for SERVER in $(cat "${SERVER_LIST}")
do
  # if script runs in verbose mode, additionally print server ip/hostname
  if [[ "${VERBOSE}" = 'true' ]]
  then
    echo "${SERVER}"
  fi

  # if no password supplied, just execute the ssh command  
  if [[ "${PASS}" == "" ]]
  then
	SSH_COMMAND="ssh ${SSH_OPTIONS} ${USER}@${SERVER} ${SUDO} ${COMMAND}"
  else
    # use sshpass to provide the password while executing the ssh command
  	PASS="$PASS"
  	SSH_COMMAND="sshpass -p $PASS ssh ${SSH_OPTIONS} ${USER}@${SERVER} ${SUDO} ${COMMAND}"
  fi

  # if it's a dry run, don't execute anything, just echo it.
  if [[ "${DRY_RUN}" = 'true' ]]
  then
    echo "DRY RUN: ${SSH_COMMAND}"
  else
    ${SSH_COMMAND}
    SSH_EXIT_STATUS="${?}"

    # capture any non-zero exit status from the SSH_COMMAND and report to the user.
    if [[ "${SSH_EXIT_STATUS}" -ne 0 ]]
    then
      EXIT_STATUS=${SSH_EXIT_STATUS}
      echo "Execution on ${SERVER} failed." >&2
    fi
  fi
done

# exit with exit status captured from script run
exit ${EXIT_STATUS}
