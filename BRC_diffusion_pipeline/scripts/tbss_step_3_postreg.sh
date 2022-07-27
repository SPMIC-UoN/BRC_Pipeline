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
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "tbss_step_3_postreg"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

SKELETON=1

cd FA

/bin/rm -f all.msf

best=MNI

echo ${best} > best.msf

mkdir -p ../stats

f='dti_FA'

${FSLDIR}/bin/applywarp -i ${f} -o ${f}_to_MNI -r MNI -w ${f}_to_MNI_warp --rel

log_Msg 3 "merging all upsampled FA images into single 4D image"
cd ../stats
${FSLDIR}/bin/imcp ../FA/dti_FA_to_MNI all_FA

# create mean FA
log_Msg 3 "creating valid mask and mean FA"
${FSLDIR}/bin/fslmaths all_FA -bin -mul ${FSLDIR}/data/standard/FMRIB58_FA_1mm -bin mean_FA_mask
${FSLDIR}/bin/fslmaths all_FA -mas mean_FA_mask all_FA
${FSLDIR}/bin/fslmaths ${FSLDIR}/data/standard/FMRIB58_FA_1mm -mas mean_FA_mask mean_FA
${FSLDIR}/bin/fslmaths ${FSLDIR}/data/standard/FMRIB58_FA-skeleton_1mm -mas mean_FA_mask mean_FA_skeleton
