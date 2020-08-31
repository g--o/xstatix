#!/bin/bash

# xStatix - the second simplest static website generator in bash
# based on: https://gist.github.com/plugnburn/c2f7cc3807e8934b179e { (c) Revoltech 2015 }
# see LICENSE


# stubs

ROUTEFILE='routes.conf'
BLOCKSDIR='blocks/'
SRCDIR="$BLOCKSDIR"
OUTDIR='out/'
ASSETDIR='assets/'
DRAFTSDIR='drafts/'
GENROUTES=true
VERBOSE=false

## routines

# internal

function logVerbose {
	if [ "$VERBOSE" == true ]; then
		echo "[$1]"
	fi
}

function prerenderBlock {
	local blockFile="${SRCDIR}${1}"
	local blockContent="$(<${blockFile})"
	local L=''
	local includes=$(grep -Po '<!--\s*#include:.*?-->' "$blockFile")
	OLDIFS="$IFS"
	IFS=$'\n'
	for L in $includes; do
		local includedFileName=$(echo -n "$L"| grep -Po '(?<=#include:).*?(?=-->)')
		local includedFile="$includedFileName.html"
		# set src to block & render
		local oldSrc="$SRCDIR"
		SRCDIR="$BLOCKSDIR"
		local includedContent="$(prerenderBlock ${includedFile})"
		SRCDIR="$oldSrc"
		# continue (src restored)
		blockContent="${blockContent//$L/$includedContent}"
	done
	IFS="$OLDIFS"
	echo -n "$blockContent"
}

function renderBlock {
	local blockText="$(prerenderBlock $1)"
	local sets=$(echo -n "$blockText"|grep -Po '<!--#set:.*?-->')
	local L=''
	OLDIFS="$IFS"
	IFS=$'\n'
	for L in $sets; do
		local set=$(echo -n "$L" | grep -Po '(?<=#set:).*?(?=-->)')
		local setvar="${set%%=*}"
		local setval="${set#*=}"

		blockText="${blockText//$L/}"
		blockText="${blockText//<!--@${setvar}-->/${setval}}"
		blockText="${blockText//<!--+@${setvar}-->/${setval}<!--+@${setvar}-->}"
	done
	IFS="$OLDIFS"
	echo -n "$blockText"
}

function loadRoutes {
	if [ "$GENROUTES" == true ]; then
		rm "$ROUTEFILE"
		touch "$ROUTEFILE"

		# get list
		local list=( "${1}" )
		[ -z "$list" ] && list=$(ls "$SRCDIR")

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

	for route in $ROUTELIST; do
		local blockname="${route%%:*}"
		local blockpath="${route#*:}"
		if [[ "$blockname" && "$blockpath" ]]; then
			mkdir -p "${OUTDIR}${blockpath}"
			renderBlock "$blockname" > "${OUTDIR}${blockpath}index.html"
		fi
	done

	IFS="$OLDIFS"
}

function insertInclude {
	# read template
	local template="${TEMPLATE}"

	if [ ! -z "$template" ]; then
		if [ ! -f "${BLOCKSDIR}${template}.html" ]; then
			echo "no such template as ${TEMPLATE}"
			exit 1
		fi
		# write draft
		echo "<!--#include:$template-->" >> ${1}
	fi
}

# user end

function showHelp {
	echo "xStatix"
	echo "  syntax: xstatix [-s|-t|-v|-g|-h|-w|-e|-d|-p|-u]"
	echo "  options:"
	echo "    s	set variable"
	echo "    t	use specified block as template"
	echo "    v	verbose"
	echo "    g	generate project tree"
	echo "    h	print this help"
	echo "    w	write"
	echo "    e	edit"
	echo "    d	delete"
	echo "    p	publish"
	echo "    u	unpublish"
	echo "  default:"
	echo "    generates default project file tree"
	echo "  note:"
	echo "    use the options in the order you want them!"
	exit 0
}

function makeProjectTree {
	mkdir -p "$BLOCKSDIR"
	mkdir -p "$ASSETDIR"
	mkdir -p "$DRAFTSDIR"
	rm -rf "${OUTDIR}"/*

	if [[ "$ASSETDIR" ]]; then 
		cp -rd "$ASSETDIR" "${OUTDIR}/"
	fi

	touch "$ROUTEFILE"
	logVerbose "created project tree"
}

function writeDraft {
	loadRoutes

	# read name
	local name="${1}.html"
	local dest="${DRAFTSDIR}${name}"

	insertInclude "${dest}"
	touch "${dest}"

	# done
	echo "draft $dest written"
}

function deleteDraft {
	local dest="${DRAFTSDIR}${1}"
	if [ "$dest" == "${DRAFTSDIR}" ] || [ ! -f "${dest}.html" ]; then
		exit 1
	fi

	rm "${dest}.html"
	echo "deleted ${dest}"
	exit 0
}

function publishPage {
	SRCDIR="${DRAFTSDIR}"

	#loadRoutes "${1}.html"
	loadRoutes
	generate

	echo "published draft ${1}"
	exit 0
}

function unpublishPage {
	local dest=${OUTDIR}${1}.html
	if [ "$dest" == "${OUTDIR}.html" ]; then
		exit 1
	fi

	rm -rf "${dest}"

	echo "unpublished ${dest}"
	exit 0
}

function editDraft {
	local draft="${1}.html"
	local dest=${DRAFTSDIR}${draft}
	SRCDIR="$DRAFTSDIR"

	# insert template block
	insertInclude "${dest}"

	# variable settings
	# local choice=$(prerenderBlock "${draft}" | grep -Po "(.?@).*?(?=-->)")
	local setline="${SETOPTION}"
	local prefix="${setline:0:1}" # +/-
	local rest="${setline:2}"
	local varname="${rest%%=*}"
	local varval="${rest#*=}"
	local setText="<!--#set:${varname}=${varval}-->"
	local matchRegex="<!--#set:${varname}=.*-->"

	if [ "$prefix" == "+" ]; then
		echo "$setText" >> ${dest}
	elif [ "$prefix" == "=" ]; then
		local match=$(grep "$matchRegex" ${dest})
		if [ -z "$match" ]; then
			echo "$setText" >> ${dest}
		else
			sed -i -E "s/${matchRegex}/${setText}/" ${dest}
		fi
	elif [ "$prefix" == "-" ]; then
		local result=$(tac ${dest} | sed "0,/${matchRegex}/{s/${matchRegex}//}" | tac)
		echo "$result" > ${dest}
	elif [ "$prefix" == "r" ]; then
		sed -i -E "s/$matchRegex//" ${dest}
	else
		logVerbose "unknown prefix"
	fi

	echo "edit complete"
	exit 0
}

# main
# read options

while getopts ":s:t:vghw:e:d:p:u:" opt; do
	case ${opt} in
	s ) SETOPTION=${OPTARG} ;;
	t ) TEMPLATE=${OPTARG} && logVerbose "using template ${OPTARG}" ;;
	v ) VERBOSE=true ;;
	g ) makeProjectTree ;;
	h ) showHelp ;;
	w ) writeDraft ${OPTARG} ;;
	e ) editDraft ${OPTARG} ;;
	d ) deleteDraft ${OPTARG} ;;
	p ) publishPage ${OPTARG} ;;
	u ) unpublishPage ${OPTARG} ;;
	\? ) echo "Invalid option: $OPTARG" 1>&2; exit 1 ;;
	esac
done
shift $((OPTIND -1))