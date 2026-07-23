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
datadir=`getopt1 "--datadir" $@`
TBSS_Reg_Method=`getopt1 "--tbssregmethod" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "tbss_non_FA"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

cd stats

dtifitDir=${datadir}

suffix="L1 L2 L3 MO MD"

for elem in ${suffix} ; do
    if [ -e ${dtifitDir}/data.dti/dti_${elem}.nii.gz ] ; then

        if [ "${TBSS_Reg_Method}" == "ants" ] ; then
            ${ANTSPATH}/antsApplyTransforms -d 3 \
                                            -n Linear \
                                            -i ${dtifitDir}/data.dti/dti_${elem}.nii.gz \
                                            -r ${FSLDIR}/data/standard/FMRIB58_FA_1mm.nii.gz \
                                            -o all_${elem}.nii.gz \
                                            -t ../FA/dti_FA_to_MNI_ants1Warp.nii.gz \
                                            -t ../FA/dti_FA_to_MNI_ants0GenericAffine.mat
        else
            ${FSLDIR}/bin/applywarp --rel -i ${dtifitDir}/data.dti/dti_${elem} -o all_${elem} -r ${FSLDIR}/data/standard/FMRIB58_FA_1mm -w ../FA/dti_FA_to_MNI_warp
        fi
        ${FSLDIR}/bin/fslmaths all_${elem} -mas mean_FA_skeleton_mask all_${elem}_skeletonised
        ${FSLDIR}/bin/fslstats -K ${FSLDIR}/data/atlases/JHU/JHU-ICBM-labels-1mm all_${elem}_skeletonised.nii.gz -M >JHUrois_${elem}.txt

    fi
done

suffix="ICVF ISOVF ODI"

for elem in ${suffix} ; do
    if [ -e ${dtifitDir}/data.noddi/NODDI_${elem}.nii.gz ] ; then

        if [ "${TBSS_Reg_Method}" == "ants" ] ; then
            ${ANTSPATH}/antsApplyTransforms -d 3 \
                                            -n Linear \
                                            -i ${dtifitDir}/data.noddi/NODDI_${elem}.nii.gz \
                                            -r ${FSLDIR}/data/standard/FMRIB58_FA_1mm.nii.gz \
                                            -o all_${elem}.nii.gz \
                                            -t ../FA/dti_FA_to_MNI_ants1Warp.nii.gz \
                                            -t ../FA/dti_FA_to_MNI_ants0GenericAffine.mat
        else
            ${FSLDIR}/bin/applywarp --rel -i ${dtifitDir}/data.noddi/NODDI_${elem} -o all_${elem} -r ${FSLDIR}/data/standard/FMRIB58_FA_1mm -w ../FA/dti_FA_to_MNI_warp
        fi
        ${FSLDIR}/bin/fslmaths all_${elem} -mas mean_FA_skeleton_mask all_${elem}_skeletonised
        ${FSLDIR}/bin/fslstats -K ${FSLDIR}/data/atlases/JHU/JHU-ICBM-labels-1mm all_${elem}_skeletonised.nii.gz -M >JHUrois_${elem}.txt

    fi
done

cd ..
