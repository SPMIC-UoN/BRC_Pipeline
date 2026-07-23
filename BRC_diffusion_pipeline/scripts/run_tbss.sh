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
workingdir=`getopt1 "--workingdir" $@`
tbssdir=`getopt1 "--tbssfolder" $@`
datadir=`getopt1 "--datafolder" $@`
TBSS_Reg_Method=`getopt1 "--tbssregmethod" $@`
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
log_Msg 2 "TBSS_Reg_Method:$TBSS_Reg_Method"
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
                  --tbssregmethod=${TBSS_Reg_Method} \
                  --logfile=${LogFile}

"${BRC_DMRI_SCR}"/tbss_step_3_postreg.sh \
                  --tbssregmethod=${TBSS_Reg_Method} \
                  --logfile=${LogFile}

"${BRC_DMRI_SCR}"/tbss_step_4_prestats.sh \
                  --thresh=2000 \
                  --logfile=${LogFile}

"${BRC_DMRI_SCR}"/tbss_non_FA.sh \
                  --datadir=${datadir} \
                  --tbssregmethod=${TBSS_Reg_Method} \
                  --logfile=${LogFile}

cd "${direc}"
