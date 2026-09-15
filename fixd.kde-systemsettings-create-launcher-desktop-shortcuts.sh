#!/usr/bin/env bash

set -euo pipefail
############################################################
TS=$(date +%s)
TMPdir="/tmp/fixd__settings-modules-extraction/${TS}"
listComplete="${TMPdir}/${TS}_modules__COMPLETE"
listFinalFormatted="${TMPdir}/${TS}_modules__FINAL.list"

# List of binaries used to invoke individual settings management guis
# kcmshell6 has all the settings, systemsettings only has a partial set,
# I designed this to extract from both commands but was not neccessary.
# Leaving it for potential future need

#KDE_SETTINGS_BINS=("systemsettings" "kcmshell6")
KDE_SETTINGS_BINS=("kcmshell6")
BIN_OPTS="--list"
GREP_Filter='kwin\|kcm'

############################################
#INPUT_FILE="${1}"
MENU_REFRESH_CMD="kbuildsycoca6 --noincremental"
INPUT_FILE="${listFinalFormatted}"
CUSTOM_PREFIX="Fixd"
OUTPUT_DIR="${HOME}/.local/share/applications/${CUSTOM_PREFIX}"
##################################################

mkdir -p "${OUTPUT_DIR}"
mkdir -p "${TMPdir}"

modList_sanitize() {

	listToSort="$1"
	listRemovedLines="$(grep -siv "${GREP_Filter}" <"${listToSort}" | sort -u -r)"

	# Filter and sort
	grep -si "${GREP_Filter}" <"${listToSort}" | sort -u -o "${listComplete}"

	# Reformats lines for second part of program
	awk -v s1='${cmd}' -v s2='# ' -v s3="" '{print s1,$1}; { $1=""; print s2 $0 }; {print s3};' "${listComplete}" >>"${listFinalFormatted}"

	listCount="$(wc -l <"${listToSort}")"
	listComplete_Count="$(wc -l <"${listComplete}")"

	echo -e "COUNT: ${listCount}		-	Line Items Pre Sort & Dedupe"
	echo -e "COUNT: ${listComplete_Count}		-	Line Items Sorted & Deduped"

	echo -e "REMOVED THESE LINES FROM LIST: \n${listRemovedLines} \n\n "
	echo -e "Finalized list location: \n${listComplete}"
	echo -e "Final formatted list location: \n ${listFinalFormatted}"

}
modList_extract() {

	modList_COMBINED="${TMPdir}/${TS}_modules__COMBINED"

	for BIN in "${KDE_SETTINGS_BINS[@]}"; do
		# Set output file
		modList_OUT="${TMPdir}/${TS}_modules__${BIN}"

		# Save output to individual list and combined list for processing
		#"${BIN}" "${BIN_OPTS}" | tee -a "${modList_COMBINED}" >"${modList_OUT}"
		"${BIN}" "${BIN_OPTS}" >"${modList_OUT}"
		"${BIN}" "${BIN_OPTS}" >>"${modList_COMBINED}"

		echo -e "Saved ${BIN} ${BIN_OPTS} to \n ${modList_OUT}\n"

	done

	modList_sanitize "${modList_COMBINED}"

}

createLauncherDesktopShortcuts() {
	while read -r line; do
		if [[ "${line}" =~ \$\{cmd\}\ (.*) ]]; then
			module="${BASH_REMATCH[1]}"
			read -r comment_line

			desc=$(echo "${comment_line}" | sed 's/^#[[:space:]]*//')
			desc="${desc:-${module}}"

			cat <<EOF >"${OUTPUT_DIR}/${CUSTOM_PREFIX}_${module}.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=${CUSTOM_PREFIX} - Settings for ${module}
GenericName=${desc}
Comment=Direct settings for ${module} ${desc}
Exec=kcmshell6 ${module}
Icon=starred
Terminal=false
Categories=${CUSTOM_PREFIX} Settings;
EOF
			chmod +x "${OUTPUT_DIR}/${CUSTOM_PREFIX}_${module}.desktop"
			echo -e "Created ${OUTPUT_DIR}/${CUSTOM_PREFIX}_${module}.desktop"
		fi
	done <"${INPUT_FILE}"
}

modList_extract

createLauncherDesktopShortcuts
${MENU_REFRESH_CMD}
