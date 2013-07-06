#!/bin/sh
# reads stdin...useful in a pipeline
cat | sed -r 's/^\[[0-9].*] (DEBUG|INFO|WARN):/\1:/'
