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
regFolder=`getopt1 "--regfolder" $@`
regT1Folder=`getopt1 "--regt1folder" $@`
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
log_Msg 2 "regFolder:$regFolder"
log_Msg 2 "regT1Folder:$regT1Folder"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 3 `date`

TARGET="${FSLDIR}/data/standard/FSL_HCP1065_FA_1mm"
SKELETON="${BRC_GLOBAL_DIR}/templates/FSL_HCP1065_FA_skeleton_1mm"

if [ `${FSLDIR}/bin/imtest ${TARGET}` != 1 ] ; then
    echo ""
    echo "TBSS target template not found: ${TARGET}"
    echo ""
    exit 1
fi

if [ `${FSLDIR}/bin/imtest ${SKELETON}` != 1 ] ; then
    echo ""
    echo "TBSS target skeleton not found: ${SKELETON}"
    echo ""
    exit 1
fi

direc="$PWD"
cd "${tbssdir}"

if [ ! -f dti_FA.nii.gz ] ; then
    ln ${datadir}/data.dti/dti_FA.nii.gz dti_FA.nii.gz
fi

${BRC_DMRI_SCR}/tbss_step_1_preproc.sh \
                  --data="dti_FA" \
                  --logfile=${LogFile}

"${BRC_DMRI_SCR}"/tbss_step_2_reg.sh \
                  --regfolder=${regFolder} \
                  --regt1folder=${regT1Folder} \
                  --target=${TARGET} \
                  --logfile=${LogFile}

"${BRC_DMRI_SCR}"/tbss_step_3_postreg.sh \
                  --target=${TARGET} \
                  --skeleton=${SKELETON} \
                  --logfile=${LogFile}

"${BRC_DMRI_SCR}"/tbss_step_4_prestats.sh \
                  --thresh=0.2 \
                  --logfile=${LogFile}

"${BRC_DMRI_SCR}"/tbss_non_FA.sh \
                  --datadir=${datadir} \
                  --target=${TARGET} \
                  --logfile=${LogFile}

cd "${direc}"
