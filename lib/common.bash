#!/usr/bin/env bash

function is_windows() {
  [[ "$OSTYPE" =~ ^(win|msys|cygwin) ]]
}