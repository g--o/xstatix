#!/usr/bin/bash

postsdir="posts"
outdir="out"
postspath="drafts/${postsdir}"

echo "select post to delete: "
postfile=$( ls "$postspath" | fzy)
postblock="${postfile%.*}"
./xstatix -d "$postsdir/$postblock"
./xstatix -s -@content="<!--#include:out\/$postblock\/index.html-->" -e index