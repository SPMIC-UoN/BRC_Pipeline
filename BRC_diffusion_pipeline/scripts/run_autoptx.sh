#!/bin/bash
# Last update: 09/04/2025

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
set -e

source $BRC_GLOBAL_SCR/log.shlib  # Logging related functions

# function for parsing options
getopt1()
{
    local sopt="$1"
    shift 1
    local fn
    for fn in "$@" ; do
        case "$fn" in
            "${sopt}"=*) printf '%s\n' "${fn#*=}"; return 0 ;;
        esac
    done
}

# parse arguments
dataFolder=`getopt1 "--datafolder" $@`
bedpostxFolder=`getopt1 "--bedpostxfolder" $@`
tbssFolder=`getopt1 "--tbssfolder" $@`
autoptxFolder=`getopt1 "--autoptxfolder" $@`
Start_Time=`getopt1 "--start" $@`
Subject=`getopt1 "--subject" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                        START: AutoPtx Pipeline                         +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "dataFolder:     ${dataFolder}"
log_Msg 2 "bedpostxFolder: ${bedpostxFolder}"
log_Msg 2 "tbssFolder:     ${tbssFolder}"
log_Msg 2 "autoptxFolder:  ${autoptxFolder}"
log_Msg 2 "Start_Time:     ${Start_Time}"
log_Msg 2 "Subject:        ${Subject}"
log_Msg 2 "LogFile:        ${LogFile}"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 3 `date`

#=====================================================================================
###                         Run AutoPtx tractography
#=====================================================================================

log_Msg 3 "Running AutoPtx automated probabilistic tractography"

${BRC_DMRI_SCR}/brc_autoptx.sh \
    --datafolder=${dataFolder} \
    --bedpostxfolder=${bedpostxFolder} \
    --tbssfolder=${tbssFolder} \
    --autoptxfolder=${autoptxFolder} \
    --logfile=${LogFile}

END_Time="$(date -u +%s)"

${BRCDIR}/Show_version.sh \
      --showdiff="yes" \
      --start=${Start_Time} \
      --end=${END_Time} \
      --subject=${Subject} \
      --type=2 \
      --logfile=${LogFile}
