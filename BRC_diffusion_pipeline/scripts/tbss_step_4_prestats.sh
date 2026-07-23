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
thresh=`getopt1 "--thresh" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "tbss_step_4_prestats"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

cd stats

log_Msg 3  "creating skeleton mask using threshold ${thresh}"
log_Msg 3  ${thresh} > thresh.txt

${FSLDIR}/bin/fslmaths mean_FA_skeleton -thr ${thresh} -bin mean_FA_skeleton_mask
${FSLDIR}/bin/fslmaths all_FA -mas mean_FA_skeleton_mask all_FA_skeletonised
${FSLDIR}/bin/fslstats -K ${FSLDIR}/data/atlases/JHU/JHU-ICBM-labels-1mm all_FA_skeletonised.nii.gz -M >JHUrois_FA.txt
