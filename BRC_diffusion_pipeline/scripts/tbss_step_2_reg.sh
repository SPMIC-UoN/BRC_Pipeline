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
regFolder=`getopt1 "--regfolder" $@`
regT1Folder=`getopt1 "--regt1folder" $@`
TARGET=`getopt1 "--target" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "tbss_step_2_reg"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

cd FA

input="dti_FA"
output="${input}_to_MNI"
invOutput="MNI_to_${input}"

log_Msg 3 "Concatenating dMRI-to-T1 and T1-to-standard registrations"
${FSLDIR}/bin/convertwarp --relout --ref=${TARGET} --premat=${regFolder}/diff_2_T1.mat \
    --warp1=${regT1Folder}/T1_2_std_warp_field --out=${output}_warp

log_Msg 3 "Applying combined warp to FA"
${FSLDIR}/bin/applywarp --rel --interp=trilinear --in=${input} --ref=${TARGET} \
    -w ${output}_warp --out=${output}

# Remove negative intensity values
${FSLDIR}/bin/fslmaths ${output} -thr 0 ${output}

${FSLDIR}/bin/invwarp --rel -w ${output}_warp -r ${input} -o ${invOutput}_warp
