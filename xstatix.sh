#!/bin/bash

# xStatix - the second simplest static website generator in bash
# based on: https://gist.github.com/plugnburn/c2f7cc3807e8934b179e { (c) Revoltech 2015 }
# see LICENSE


# stubs

ROUTEFILE='routes.conf'
TPLDIR='templates/'
SRCDIR="$TPLDIR"
OUTDIR='out/'
ASSETDIR='assets/'
DRAFTSDIR='drafts/'
GENROUTES=true
VERBOSE=false

# routines

function logVerbose {
	if [ "$VERBOSE" == true ]; then
		echo "$1"
	fi
}

function pickFromDir {
	local selection=$(ls "$1" | fzy)
	echo -n "${1}${selection}"
}

function showHelp {
	echo "xStatix"
	echo "  syntax: xstatix [-w|-d|-p|-u|-v|-h]"
	echo "  options:"
	echo "    w	write"
	echo "    d	delete"
	echo "    p	publish"
	echo "    u	unpublish"
	echo "    v	verbose"
	echo "    h	print this help"
	echo "  default:"
	echo "    generates default project file tree"
	exit 0
}

function prerenderTemplate {
	local TPLFILE="${SRCDIR}/$1"
	local TPLCONTENT="$(<$TPLFILE)"
	local L=''
	local INCLUDES=$(grep -Po '<!--\s*#include:.*?-->' "$TPLFILE")
	OLDIFS="$IFS"
	IFS=$'\n'
	for L in $INCLUDES; do
		local INCLFNAME=$(echo -n "$L"|grep -Po '(?<=#include:).*?(?=-->)')
		local oldSrc="$SRCDIR"
		SRCDIR="$TPLDIR"
		local INCLFCONTENT="$(prerenderTemplate ${INCLFNAME})"
		SRCDIR="$oldSrc"
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
	logVerbose "[created project tree]"
}

function loadRoutes {
	if [ "$GENROUTES" == true ]; then
		rm "$ROUTEFILE"
		touch "$ROUTEFILE"

		local list=$(ls "$SRCDIR")
		for file in $list; do	
			name="${file%.*}"
			if [ "$name" == "index" ]; then name=''; fi
			echo "$file:$name/" >> "$ROUTEFILE"
		done
		logVerbose "[generated default routes]"
	fi

	ROUTELIST="$(<$ROUTEFILE)"
	logVerbose "[loaded routes]"
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

	# template selection
	echo "choose template"
	local template=$(ls "$TPLDIR" | fzy)

	# read name
	echo "draft name [default: template name]"
	read name
	if [ -z "$name" ]; then
		name="${template}"
	else
		name="${name}.html"
	fi	
	local dest="${DRAFTSDIR}${name}"
	
	# variable settings
	# @TODO: loop
	echo "choose variable"
	local varname=$(cat "$TPLDIR/$template" | grep -Po "(?<=@).*?(?=-->)" | fzy)
	echo "set to: "
	read varval

	# write draft
	echo "<!--#include:$template-->" > ${dest}
	echo "<!--#set:$varname=$varval-->" >> ${dest}

	# done
	echo "draft $dest written"
	exit 0
}

function deleteDraft {
	echo "delete draft:"
	local dest=$(pickFromDir "${DRAFTSDIR}")
	if [ "$dest" == "${DRAFTSDIR}" ]; then
		exit 1
	fi

	rm "${dest}"
	echo "deleted ${dest}"
	exit 0
}

function publishPage {
	# template selection
	echo "publish draft"
	local draft=$(ls "$DRAFTSDIR" | fzy)
	local dest="${DRAFTSDIR}${draft}"
	SRCDIR="${DRAFTSDIR}"
	loadRoutes
	generate
	exit 0
}

function unpublishPage {
	echo "unpublish page:"
	local dest=$(pickFromDir "${OUTDIR}")
	if [ "$dest" == "${OUTDIR}" ]; then
		exit 1
	fi

	rm -rf "${dest}"
	echo "unpublished ${dest}"
	exit 0
}

# read options

while getopts ":wdpuvh" opt; do
	case ${opt} in
	w ) writeDraft ;;
	d ) deleteDraft ;;
	p ) publishPage ;;
	u ) unpublishPage ;;
	v ) VERBOSE=true ;;
	h ) showHelp ;;
	\? ) echo "Invalid option: $OPTARG" 1>&2; exit 1 ;;
	esac
done
shift $((OPTIND -1))

# main

makeProjectTree
