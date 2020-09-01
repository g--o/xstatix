#!/usr/bin/bash

id=1
outdir="out"

read -p "enter your post: " content
./xstatix -i +@blocks/post.html -w posts/$id
./xstatix -s =@content="$content" -e posts/$id
./xstatix -s +@content="<!--#include:$outdir/$id/index.html-->" -e index
