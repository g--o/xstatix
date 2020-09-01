#!/usr/bin/bash

CONFIGFILE="blog.conf"

read -p "enter blog name: " name
echo "creating project tree..."
./xstatix -g
mkdir -p drafts/posts
echo "generating main page..."
./xstatix -i +@blocks/index.html -w index
./xstatix -s =@title="$name" -e index
./xstatix -p index
echo "creating configuration file"
echo "0" > $CONFIGFILE
echo "done"
