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

log_Msg 3 "tbss_step_2_reg"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

TARGET="${FSLDIR}/data/standard/FMRIB58_FA_1mm"

$FSLDIR/bin/imcp "$TARGET" FA/MNI

cd FA

ref="MNI"
input="dti_FA"
parameterName="${BRC_GLOBAL_DIR}/config/oxford"
output="${input}_to_${ref}"
invOutput="${ref}_to_${input}"

if [ ! -f ${o}_warp.msf ] ; then

    #New Optimal Registration
    ${FSLDIR}/bin/flirt -ref "$ref" -in "$input" -inweight "$input"_mask -omat "$output"_affine.mat

    # perform FNIRT cascade of registrations
    $FSLDIR/bin/fnirt --ref="$ref" --in="$input" --cout="$output"_warp_s1 --config="$parameterName"_s1.cnf --aff="$output"_affine.mat --intout="$output"_int --logout="$logFile"_1.log
    $FSLDIR/bin/fnirt --ref="$ref" --in="$input" --cout="$output"_warp_s2 --config="$parameterName"_s2.cnf --inwarp="$output"_warp_s1 --intin="$output"_int.txt --logout="$logFile"_2.log
    $FSLDIR/bin/fnirt --ref="$ref" --in="$input" --cout="$output"_warp --iout="$output" --config="$parameterName"_s3.cnf --inwarp="$output"_warp_s2 --intin="$output"_int.txt --logout="$logFile"_3.log
    $FSLDIR/bin/invwarp -w "$output"_warp -r "$input" -o "$invOutput"_warp

    # now estimate the mean deformation
    ${FSLDIR}/bin/fslmaths "$output"_warp -sqr -Tmean "$output"_tmp
    ${FSLDIR}/bin/fslstats "$output"_tmp -M -P 50 > "$output"_warp.msf
    ${FSLDIR}/bin/imrm "$output"_tmp

fi
