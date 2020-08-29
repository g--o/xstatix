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
		echo "[$1]"
	fi
}

function pickFromDir {
	local selection=$(ls "$1" | fzy)
	echo -n "${1}${selection}"
}

function showHelp {
	echo "xStatix"
	echo "  syntax: xstatix [-w|-e|-d|-p|-u|-v|-h]"
	echo "  options:"
	echo "    w	write"
	echo "    e	edit"
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
	local tplFile="${SRCDIR}/$1"
	local tplContent="$(<$tplFile)"
	local L=''
	local includes=$(grep -Po '<!--\s*#include:.*?-->' "$tplFile")
	OLDIFS="$IFS"
	IFS=$'\n'
	for L in $includes; do
		local includedFile=$(echo -n "$L"|grep -Po '(?<=#include:).*?(?=-->)')
		# set src to templates & render
		local oldSrc="$SRCDIR"
		SRCDIR="$TPLDIR"
		local INCLFCONTENT="$(prerenderTemplate ${includedFile})"
		SRCDIR="$oldSrc"
		# continue (src restored)
		tplContent="${tplContent//$L/$INCLFCONTENT}"
	done
	IFS="$OLDIFS"
	echo -n "$tplContent"
}

function renderTemplate {
	local tplText="$(prerenderTemplate $1)"
	local sets=$(echo -n "$tplText"|grep -Po '<!--#set:.*?-->')
	local L=''
	OLDIFS="$IFS"
	IFS=$'\n'
	for L in $sets; do
		local set=$(echo -n "$L"|grep -Po '(?<=#set:).*?(?=-->)')
		local setvar="${set%%=*}"
		local setval="${set#*=}"

		tplText="${tplText//$L/}"
		tplText="${tplText//<!--@${setvar}-->/${setval}}"
		tplText="${tplText//<!--+@${setvar}-->/${setval}<!--+@${setvar}-->}"
	done
	IFS="$OLDIFS"
	echo -n "$tplText"
}

function makeProjectTree {
	mkdir -p "$TPLDIR"
	mkdir -p "$ASSETDIR"
	mkdir -p "$DRAFTSDIR"
	rm -rf "${OUTDIR}"/*

	if [[ "$ASSETDIR" ]]; then 
		cp -rd "$ASSETDIR" "${OUTDIR}/"
	fi

	touch "$ROUTEFILE"
	logVerbose "created project tree"
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
		logVerbose "generated default routes"
	fi

	ROUTELIST="$(<$ROUTEFILE)"
	logVerbose "loaded routes"
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
	
	# write draft
	echo "<!--#include:$template-->" > "${dest}"

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

function editDraft {
	echo "edit draft:"
	local draft=$(ls "${DRAFTSDIR}" | fzy)
	local dest=${DRAFTSDIR}${draft}
	SRCDIR="$DRAFTSDIR"	

	# variable settings
	# @TODO: loop
	echo "choose variable"
	local choice=$(prerenderTemplate "${draft}" | grep -Po "(.?@).*?(?=-->)" | fzy)
	local prefix="${choice:0:1}" # +/-
	local varname="${choice:2}"

	echo "$varname${prefix}= "
	read varval

	local setText="<!--#set:$varname=$varval-->"
	
	if [ "$prefix" == "+" ]; then
		echo "$setText" >> ${dest}
	elif [ "$prefix" == "-" ]; then
		local match=$(grep "<!--#set:${varname}" ${dest})
		if [ -z "$match" ]; then
			echo "$setText" >> ${dest}
		else
			sed -i -E "s/<!--#set:${varname}=.*-->/${setText}/" ${dest}
		fi
	else
		logVerblose "unknown prefix"
	fi

	vim ${dest}

	echo "edit complete"
	exit 0
}

# read options

while getopts ":wedpuvh" opt; do
	case ${opt} in
	w ) writeDraft ;;
	e ) editDraft ;;
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
