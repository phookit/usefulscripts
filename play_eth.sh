#!/bin/bash

###############################################################################
#
# Keeps multiple pcap files playing in sync.
#
# Usage: 
#   $ play_eth.sh <replay_params> <iface> <[iface:]file> <[iface:]file> ...
#
# <replay_params> is optional parameters to pass to tcpreplay. if no tcpreplay
#                 parameters are required pass "-".
# <iface> is the default interface to play on.
# 
# Files can optionally be prepended with an interface. Any further files
# will then be played on that interface.
# i.e.
# 
#   $ play_eth.sh "--pps=100000" eth3 file1 eth4:file2 file3 eth5:file4
#
#   file1 will be played on eth3
#   file2 will be played on eth4
#   file3 will be played on eth4
#   file4 will be played on eth5
#
#   All files will be played at 100k pps.
#
###############################################################################

REPLAY_PARAMS=
if [ $1 != "-" ]
then
  REPLAY_PARAMS=$1
fi
shift

DEFAULT_IFACE=$1
shift

IFACE=$DEFAULT_IFACE

REPLAY_PIDS=

tidy_up() {
  # user aborted (CTRL-C) 
  # kill any running tcpreplays
  for p in $REPLAY_PIDS; do
    kill $p
  done
  REPLAY_PIDS=
  exit 1
}
trap 'tidy_up' SIGINT

while true
do 
  # start files on the default interface
  IFACE=$DEFAULT_IFACE
  for f in $@
  do
    file_to_play=$f
    IFS=':' read -a iface_file <<< "$f"
    if [ ! -z ${iface_file[1]} ]; then # we have iface:file
      IFACE=${iface_file[0]}
      file_to_play=${iface_file[1]}
    fi
    tcpreplay -i $IFACE $REPLAY_PARAMS $file_to_play &
    pid=$!
    echo "tcpreplay -i $IFACE $REPLAY_PARAMS $file_to_play & ($pid)"
    REPLAY_PIDS="$REPLAY_PIDS $pid"
  done
  echo "playing..."
  wait
  # tcpreplays have all finished
  REPLAY_PIDS=
  sleep 0.1
done

exit 0
