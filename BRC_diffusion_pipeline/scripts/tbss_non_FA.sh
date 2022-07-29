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
datadir=`getopt1 "--datadir" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "tbss_non_FA"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

cd stats

dtifitDir=${datadir}

suffix="L1 L2 L3 MO MD"

for elem in ${suffix} ; do
    ${FSLDIR}/bin/applywarp --rel -i ${dtifitDir}/data.dti/dti_${elem} -o all_${elem} -r ${FSLDIR}/data/standard/FMRIB58_FA_1mm -w ../FA/dti_FA_to_MNI_warp
    ${FSLDIR}/bin/fslmaths all_${elem} -mas mean_FA_skeleton_mask all_${elem}_skeletonised
    ${FSLDIR}/bin/fslstats -K ${FSLDIR}/data/atlases/JHU/JHU-ICBM-labels-1mm all_${elem}_skeletonised.nii.gz -M >JHUrois_${elem}.txt
done

suffix="ICVF ISOVF ODI"

for elem in ${suffix} ; do
    ${FSLDIR}/bin/applywarp --rel -i ${dtifitDir}/data.noddi/NODDI_${elem} -o all_${elem} -r ${FSLDIR}/data/standard/FMRIB58_FA_1mm -w ../FA/dti_FA_to_MNI_warp
    ${FSLDIR}/bin/fslmaths all_${elem} -mas mean_FA_skeleton_mask all_${elem}_skeletonised
    ${FSLDIR}/bin/fslstats -K ${FSLDIR}/data/atlases/JHU/JHU-ICBM-labels-1mm all_${elem}_skeletonised.nii.gz -M >JHUrois_${elem}.txt
done

cd ..
