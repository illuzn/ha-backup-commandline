#!/bin/bash

# Customisations
local_dir=/backup/ # Where to look for backups (if not default)
remote_dir=/share/network/ # Where to copy backups to a secondary drive (where you have mounted your smb share)
local_backups=50 # How many local backups to keep. N.B. This script cannot differentiate between full and partial backups. 0 is infinite and will skip this option.
remote_backups=100 # How many remote backups to keep. N.B. This script cannot differentiate between full and partial backups. 0 is infinite and will skip this option.
local_expire=30 # How many days until local backups are considered expired and deleted. 0 is infinite and will skip this option.
remote_expire=90 # How many days until remote backups are considered expired and deleted. 0 is infinite and will skip this option.

# Do not edit below here unless you know what you are doing.

# Abort script on common failure modes.

set -o errexit -o noclobber -o nounset -o pipefail

# Purge local by number
if [ ! $local_backups -eq 0 ]; then
  n=0
  while IFS= read -r -d '' -u 9
  do
    let ++n
    if [ "$n" -gt "$local_backups" ]
    then
      rm -f "$REPLY"
    fi
  done 9<  <( find $local_dir -maxdepth 1 -type f -print0 | sort -rz )
fi

# Purge local by days
if [ ! $local_expire -eq 0 ]; then
  find $local_dir -type f -mtime $local_expire -exec rm -f {} \;
fi

# Purge remote by number
if [ ! $remote_backups -eq 0 ]; then
  n=0
  while IFS= read -r -d '' -u 9
  do
    let ++n
    if [ "$n" -gt "$remote_backups" ]
    then
      rm -f "$REPLY"
    fi
  done 9<  <( find  $remote_dir -maxdepth 1 -type f -print0 | sort -rz )
fi

# Purge remote by days
if [ ! $remote_expire -eq 0 ]; then
  find $remote_dir -type f -mtime $remote_expire -exec rm -f {} \;
fi

# Naive copy (no rsync) based upon file date only.
cp -ur $local_dir $remote_dir