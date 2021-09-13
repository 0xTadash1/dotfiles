#!/usr/bin/env zsh

(){
  local PSQL_HOME=${PSQL_HOME:-"$PSQL_HOME"}
  [[ -d "$PSQL_HOME" ]] && {
    print "already exist: $PSQL_HOME"
    return 1
  }

  mkdir -pv "$PSQL_HOME"
  chattr +C "$PSQL_HOME"
  btrfs property set "$PSQL_HOME" compression ""
}
