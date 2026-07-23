#!/bin/bash
# Last update: 30/03/2025

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
do_AUTOPTX=`getopt1 "--doautoptx" $@`
Start_Time=`getopt1 "--start" $@`
Subject=`getopt1 "--subject" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                        START: BedpostX Pipeline                        +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "dataFolder:     ${dataFolder}"
log_Msg 2 "bedpostxFolder: ${bedpostxFolder}"
log_Msg 2 "LogFile:        ${LogFile}"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 3 `date`

#=====================================================================================
###                         Step 1: Pre-bedpostX
#=====================================================================================

log_Msg 3 "Step 1: Preparing data for bedpostX"

${BRC_DMRI_SCR}/brc_pre_bedpostx.sh \
    --datafolder=${dataFolder} \
    --bedpostxfolder=${bedpostxFolder} \
    --logfile=${LogFile}

#=====================================================================================
###                         Step 2: Run bedpostX (GPU)
#=====================================================================================

log_Msg 3 "Step 2: Running bedpostX on GPU"

if [ ${CLUSTER_MODE} = "YES" ] ; then
    module load cuda-12.2.2
fi

${BRC_DMRI_SCR}/brc_bedpostx.sh \
    --datafolder=${dataFolder} \
    --bedpostxfolder=${bedpostxFolder} \
    --logfile=${LogFile}

if [ ${CLUSTER_MODE} = "YES" ] ; then
    module unload cuda-12.2.2
fi

#=====================================================================================
###                         Step 3: Post-bedpostX
#=====================================================================================

log_Msg 3 "Step 3: Post-processing bedpostX output"

${BRC_DMRI_SCR}/brc_post_bedpostx.sh \
    --datafolder=${dataFolder} \
    --bedpostxfolder=${bedpostxFolder} \
    --logfile=${LogFile}

if [[ $do_AUTOPTX != "yes" ]]; then

    END_Time="$(date -u +%s)"

    ${BRCDIR}/Show_version.sh \
          --showdiff="yes" \
          --start=${Start_Time} \
          --end=${END_Time} \
          --subject=${Subject} \
          --type=2 \
          --logfile=${LogFile}

fi
