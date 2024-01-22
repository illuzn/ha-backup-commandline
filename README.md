# Home Assistant Backup Shell
A bash script to be used with the Shell extension in Home Assistant to deal with your backups.

Use this inconjunction with the Google Drive, Onedrive or your cloud backup solution of choice to implement your 3-2-1 backup strategy. 3 copies of backups. 2 on different storage media. 1 offsite backup.

## Installation
1. Download `remote-backup.sh` into your /config folder
2. Ensure that it has the appropriate execute permissions: `chmod a+x remote-backup.sh` from terminal.
3. Edit `remote-backup.sh`. The configuration options are at the top of the file.
4. Include the following in your `configuration.yaml`
```yaml
shell_command:
  remote-backup: '/bin/bash /config/remote-backup.sh'
```
5. Restart Home Assistant

If successful you should have a new service called `shell_command.remote-backup`. Call this from your automations to run your secondary backup and automatically cleanup your backups.

## Configuration
Variable | Description
---------|-------------
local_dir | Where to look for local backups. Leave it as /backup/ if you are using a default installation.
remote_dir | Where to copy backups to a secondary drive (where you have mounted your samba share). Typically in HA this will be `/share/[name]`. Do not mount your samba share as a backup directory - HA will use this for primary backups instead. Instead, use the `Share` option.
local_backups | How many local backups to keep. N.B. This script cannot differentiate between full and partial backups. 0 is infinite and will skip this option.
remote_backups | How many remote backups to keep. N.B. This script cannot differentiate between full and partial backups. 0 is infinite and will skip this option.
local_expire | How many days until local backups are considered expired and deleted. 0 is infinite and will skip this option.
remote_expire | How many days until remote backups are considered expired and deleted. 0 is infinite and will skip this option.

## Tips and Tricks

### Only remove expired backups

Set `local_backups=0` and `local_expire` to your desired days. Similarly for the remote settings.

### Interaction of local_backups and local_expire

These operate on an **OR** basis.

For example, if `local_backups=50` and `local_expire=90`. Any backup that is 51st and so-on (sorted from newest to oldest) or older than 90 days will be deleted.

### I want a sensor for how many backups I have

This is easily done using the command_line integration.

```yaml
command_line:
  - sensor:
      name: Local Backups
      unique_id: sensor.command_line_local_backups
      icon: mdi:backup-restore
      unit_of_measurement: backup(s)
      command: 'ls /backup/ | wc -l' # List files/ directories in your backup folder. Note this is naive and assumes everything in your backups folder is a backup
      state_class: measurement
      scan_interval: 3600 # Scan every hour because this doesn't need to update that quickly
  - sensor:
      name: Remote Backups
      unique_id: sensor.command_line_remote_backups
      icon: mdi:backup-restore
      unit_of_measurement: backup(s)
      command: 'ls /share/remotebackup/ | wc -l' # List files/ directories in your remote backup folder. Note this is naive and assumes everything in your backups folder is a backup
      state_class: measurement
      scan_interval: 3600 # Scan every hour because this doesn't need to update that quickly
  - sensor:
      name: Latest Local Backup
      unique_id: sensor.command_line_latest_local_backup
      command: 'find /backup/ -type f -exec stat -c "%Y" {} \+ | sort -nr | head -n 1' # List files/ directories in your remote backup folder. Note this is naive and assumes everything in your backups folder is a backup
      value_template: '{{ as_datetime(value|replace(" ","*",1)|replace(" ","")|replace("*"," ")) }}' # Hack to deal with output not being a python datetime object
      device_class: timestamp
      scan_interval: 3600 # Scan every hour because this doesn't need to update that quickly
  - sensor:
      name: Latest Remote Backup
      unique_id: sensor.command_line_latest_remote_backup
      command: 'find /share/remotebackup/ -type f -exec stat -c "%Y" {} \+ | sort -nr | head -n 1' # List files/ directories in your remote backup folder. Note this is naive and assumes everything in your backups folder is a backup
      value_template: '{{ as_datetime(value|replace(" ","*",1)|replace(" ","")|replace("*"," ")) }}' # Hack to deal with output not being a python datetime object
      device_class: timestamp
      scan_interval: 3600 # Scan every hour because this doesn't need to update that quickly
```