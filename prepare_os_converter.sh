#!/bin/bash
#
# #########################
# Server script to initiate the update on multiple clients
# #########################

# File containing a list of client IP addresses or hostnames
CLIENT_LIST_FILE="client_list.txt"

# Destination directory on the clients
CLIENT_DST=/puc/igelos-upgrade

# Source directory on the server
SERVER_SRC=/puc/igelos-upgrade

function errorExit {
  exit 1
}

function checkCheckSum {
  # Check checksums
  for sum in *.sha512 ; do
      echo "Computing checksum: $sum"
      if ! sha512sum -c $sum ; then
          echo "Error, checksum did not match: $sum"
          errorExit
      fi
  done
}

# Check checksums on the server
cd $SERVER_SRC
checkCheckSum

# Read the client list from the file
readarray -t CLIENT_LIST < "$CLIENT_LIST_FILE"

export SSH_ASKPASS="$SERVER_SRC/pass"
export DISPLAY; DISPLAY=dummy

for client in "${CLIENT_LIST[@]}"; do
    # Create the directory on the client
    echo "Creating directory /puc/igelos-upgrade..."
    setsid ssh -oStrictHostKeyChecking=no $client "mkdir -p $CLIENT_DST" 

    # Copy files to the client
    echo "Copy files to /puc/igelos-upgrade..."
    setsid scp -oStrictHostKeyChecking=no -r $SERVER_SRC/* $client:$CLIENT_DST/

    # Execute the script on the client
    echo "Executing OS Converter Script on Client..."
    setsid ssh -oStrictHostKeyChecking=no $client "bash $CLIENT_DST/os_converter.sh"
done
