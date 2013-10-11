#!/bin/sh
yes | knife cookbook bulk delete '.*' --purge
