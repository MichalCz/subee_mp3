#!/bin/bash

perl -i.bak -e 's:\\:/:g' -e 's/W:/../g' "$1"
