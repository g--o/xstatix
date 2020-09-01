#!/usr/bin/bash

echo "====== clean ======="
rm -rf drafts/ out/ assets/

echo "====== demo ======="
echo ">> create blog"
./scripts/setup.sh
echo ">> post"
./scripts/post.sh
echo ">> publish"
./scripts/publish.sh
echo ">> show"
./scripts/show.sh
echo "check your browser for result"