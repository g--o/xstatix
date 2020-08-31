#!/usr/bin/bash

echo "====== clean ======="
./xstatix -d index
./xstatix -u index

echo "====== demo ======="
echo ">> create draft of the page block, set title"
./xstatix -t index -w index
echo ">> add content (edit)"
./xstatix -s =@title="a title" -e index
./xstatix -s +@content="hello " -e index
./xstatix -s +@content="world" -e index
echo ">> publish"
./xstatix -p index
echo ">> demo done; check output at ./out"
