#!/bin/bash

# xStatix - the second simplest static website generator in bash
# based on: https://gist.github.com/plugnburn/c2f7cc3807e8934b179e { (c) Revoltech 2015 }
# see LICENSE


# stubs

ROUTEFILE='routes.conf'
TPLDIR='templates/'
OUTDIR='out/'
ASSETDIR='assets/'
GENROUTES=true
DRAFTSDIR='drafts/'

# routines

function showHelp {
	echo "xStatix"
	echo "  syntax: xstatix [-w|-d|-p|-h]"
	echo "  options:"
	echo "    w	write"
	echo "    d	delete"
	echo "    p	publish"
	echo "    h	print this help"
	exit 0
}

function prerenderTemplate {
	local TPLFILE="${TPLDIR}/$1"
	local TPLCONTENT="$(<$TPLFILE)"
	local L=''
	local INCLUDES=$(grep -Po '<!--\s*#include:.*?-->' "$TPLFILE")
	OLDIFS="$IFS"
	IFS=$'\n'
	for L in $INCLUDES; do
		local INCLFNAME=$(echo -n "$L"|grep -Po '(?<=#include:).*?(?=-->)')
		local INCLFCONTENT="$(prerenderTemplate ${INCLFNAME})"
		TPLCONTENT="${TPLCONTENT//$L/$INCLFCONTENT}"
	done
	IFS="$OLDIFS"
	echo -n "$TPLCONTENT"
}

function renderTemplate {
	local TPLTEXT="$(prerenderTemplate $1)"
	local SETS=$(echo -n "$TPLTEXT"|grep -Po '<!--#set:.*?-->')
	local L=''
	OLDIFS="$IFS"
	IFS=$'\n'
	for L in $SETS; do
		local SET=$(echo -n "$L"|grep -Po '(?<=#set:).*?(?=-->)')
		local SETVAR="${SET%%=*}"
		local SETVAL="${SET#*=}"
		TPLTEXT="${TPLTEXT//$L/}"
		TPLTEXT="${TPLTEXT//<!--@${SETVAR}-->/${SETVAL}}"
	done
	IFS="$OLDIFS"
	echo -n "$TPLTEXT"
}

function makeProjectTree {
	mkdir -p "$TPLDIR"
	mkdir -p "$ASSETDIR"
	mkdir -p "$DRAFTSDIR"
	rm -rf "${OUTDIR}"/*

	if [[ "$ASSETDIR" ]]; then 
		cp -rd "$ASSETDIR" "${OUTDIR}/";
	fi

	touch "$ROUTEFILE"
}

function loadRoutes {

	if [ "$GENROUTES" == true ]; then
		rm "$ROUTEFILE"
		touch "$ROUTEFILE"

		local list=$(ls "$TPLDIR")
		for file in $list; do	
			name="${file%.*}"
			if [ "$name" == "index" ]; then name=''; fi
			echo "$file:$name/" >> "$ROUTEFILE"
		done
	fi

	ROUTELIST="$(<$ROUTEFILE)"
	
}

function generate {
	OLDIFS="$IFS"
	IFS=$'\n'

	for ROUTE in $ROUTELIST; do
		TPLNAME="${ROUTE%%:*}"
		TPLPATH="${ROUTE#*:}"
		if [[ "$TPLNAME" && "$TPLPATH" ]]; then
			mkdir -p "${OUTDIR}${TPLPATH}"
			renderTemplate "$TPLNAME" > "${OUTDIR}${TPLPATH}index.html"
		fi
	done

	IFS="$OLDIFS"
}

function writeDraft {
	loadRoutes

	echo "choose template"
	local template=$(ls "$TPLDIR" | fzy)
	
	# @TODO: loop
	echo "choose variable"
	cat "$TPLDIR/$template" | grep "<!--@" | fzy
	echo "set to: "
	read tmp
	echo "$tmp" > "${DRAFTSDIR}${template}"
}

function deletePage {
	echo "delete stub"
}

function publishPage {
	echo "publish stub"
}

# read options

while getopts ":wdph" opt; do
	case ${opt} in
	w ) writeDraft ;;
	d ) deletePage ;;
	p ) publishPage ;;
	h ) showHelp ;;
	\? ) echo "Invalid option: $OPTARG" 1>&2; exit 1 ;;
	esac
done
shift $((OPTIND -1))

# main

makeProjectTree
loadRoutes
generate
echo "Website saved at $OUTDIR"
