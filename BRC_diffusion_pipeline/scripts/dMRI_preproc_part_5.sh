#!/bin/bash
# Last update: 10/04/2025

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham

set -e

source $BRC_GLOBAL_SCR/log.shlib  # Logging related functions

# function for parsing options
getopt1()
{
    sopt="$1"
    shift 1

    for fn in $@ ; do
        if [ `echo $fn | grep -- "^${sopt}=" | wc -w` -gt 0 ] ; then
            echo $fn | sed "s/^${sopt}=//"
            return 0
        fi
    done
}

# parse arguments
dataFolder=`getopt1 "--datafolder" $@`
bedpostxFolder=`getopt1 "--bedpostxfolder" $@`
regFolder=`getopt1 "--regfolder" $@`
tbssFolder=`getopt1 "--tbssfolder" $@`
autoptxFolder=`getopt1 "--autoptxfolder" $@`
xtractFolder=`getopt1 "--xtractfolder" $@`
do_AUTOPTX=`getopt1 "--doautoptx" $@`
do_XTRACT=`getopt1 "--doxtract" $@`
Start_Time=`getopt1 "--start" $@`
Subject=`getopt1 "--subject" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "dataFolder:     ${dataFolder}"
log_Msg 2 "bedpostxFolder: ${bedpostxFolder}"
log_Msg 2 "regFolder:      ${regFolder}"
log_Msg 2 "tbssFolder:     ${tbssFolder}"
log_Msg 2 "autoptxFolder:  ${autoptxFolder}"
log_Msg 2 "xtractFolder:   ${xtractFolder}"
log_Msg 2 "do_AUTOPTX:     ${do_AUTOPTX}"
log_Msg 2 "do_XTRACT:      ${do_XTRACT}"
log_Msg 2 "Start_Time:     ${Start_Time}"
log_Msg 2 "Subject:        ${Subject}"
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

#=====================================================================================
###                  Step 4: AutoPtx Tractography (if requested)
#=====================================================================================

if [[ $do_AUTOPTX == "yes" ]]; then

    log_Msg 3 "Step 4: Running AutoPtx automated probabilistic tractography"

    ${BRC_DMRI_SCR}/brc_autoptx.sh \
        --datafolder=${dataFolder} \
        --bedpostxfolder=${bedpostxFolder} \
        --tbssfolder=${tbssFolder} \
        --autoptxfolder=${autoptxFolder} \
        --logfile=${LogFile}

fi

#=====================================================================================
###                  Step 5: XTRACT Tractography (if requested)
#=====================================================================================

if [[ $do_XTRACT == "yes" ]]; then

    log_Msg 3 "Step 5: Running XTRACT automated white matter tractography"

    ${BRC_DMRI_SCR}/brc_xtract.sh \
        --bedpostxfolder=${bedpostxFolder} \
        --regfolder=${regFolder} \
        --xtractfolder=${xtractFolder} \
        --logfile=${LogFile}

fi

END_Time="$(date -u +%s)"

${BRCDIR}/Show_version.sh \
      --showdiff="yes" \
      --start=${Start_Time} \
      --end=${END_Time} \
      --subject=${Subject} \
      --type=2 \
      --logfile=${LogFile}

logDir="$(dirname "$LogFile")"
touch "${logDir}/.DIFF_SUCCESS"
