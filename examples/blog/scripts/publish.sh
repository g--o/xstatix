#!/usr/bin/bash

# remove
./xstatix -u index 2>/dev/null
# 1st pass
./xstatix -p index 2>/dev/null
# 2nd pass
./xstatix -p index 2>/dev/null