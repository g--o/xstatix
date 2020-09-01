#!/usr/bin/bash

echo "====== clean ======="
rm -rf drafts/ out/ assets/

echo "====== demo ======="
echo ">> create blog"
./setup.sh
echo ">> post"
./post.sh
echo ">> publish"
./publish.sh
echo ">> show"
./show.sh
echo "check your browser for result"