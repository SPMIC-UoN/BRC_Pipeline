#!/bin/bash
# Last update: 15/07/2021

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
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
workingdir=`getopt1 "--workingdir" $@`
tbssdir=`getopt1 "--tbssfolder" $@`
datadir=`getopt1 "--datafolder" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                         START: TBSS Analysis                           +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "workingdir:$workingdir"
log_Msg 2 "tbssdir:$tbssdir"
log_Msg 2 "datadir:$datadir"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 3 `date`

direc="$PWD"
cd "${tbssdir}"

if [ ! -f dti_FA.nii.gz ] ; then
    ln ${datadir}/data.dti/dti_FA.nii.gz dti_FA.nii.gz
fi

${BRC_DMRI_SCR}/tbss_step_1_preproc.sh \
                  --data="dti_FA" \
                  --logfile=${LogFile}

"${BRC_DMRI_SCR}"/tbss_step_2_reg.sh \
                  --logfile=${LogFile}

"${BRC_DMRI_SCR}"/tbss_step_3_postreg.sh \
                  --logfile=${LogFile}

"${BRC_DMRI_SCR}"/tbss_step_4_prestats.sh \
                  --thresh=2000 \
                  --logfile=${LogFile}

"${BRC_DMRI_SCR}"/tbss_non_FA.sh \
                  --datadir=${datadir} \
                  --logfile=${LogFile}

cd "${direc}"
