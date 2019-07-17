#!/bin/bash
# Last update: 05/07/2019

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
GradientDistortionCoeffs=`getopt1 "--gdc" $@`
rfMRIrawFolder=`getopt1 "--rfmrirawfolder" $@`
OrigTCSName=`getopt1 "--origtcsname" $@`
gdcFolder=`getopt1 "--gdcfolder" $@`
NameOffMRI=`getopt1 "--nameoffmri" $@`
OrigScoutName=`getopt1 "--origscoutname" $@`
ScoutName=`getopt1 "--scoutname" $@`
DistortionCorrection=`getopt1 "--distortioncorrection" $@`
DCFolder=`getopt1 "--dcfolder" $@`
topupFolderName=`getopt1 "--topupfoldername" $@`
SpinEchoPhaseEncodeNegative=`getopt1 "--spinechophaseencodenegative" $@`
SpinEchoPhaseEncodePositive=`getopt1 "--spinechophaseencodepositive" $@`
EchoSpacing=`getopt1 "--echospacing" $@`
UnwarpDir=`getopt1 "--unwarpdir" $@`
logFile=`getopt1 "--logfile" $@`

log_SetPath "${logFile}"

#=====================================================================================
###                                   DO WORK
#=====================================================================================

log_Msg 3 "Gradient Distortion Correction of fMRI"
if [ ! $GradientDistortionCoeffs = "NONE" ] ; then
    log_Msg 3 "PERFORMING GRADIENT DISTORTION CORRECTION"
else
    log_Msg 3 "NOT PERFORMING GRADIENT DISTORTION CORRECTION"

    ${RUN} ${FSLDIR}/bin/imcp ${rfMRIrawFolder}/${OrigTCSName} ${gdcFolder}/${NameOffMRI}_gdc
    ${RUN} ${FSLDIR}/bin/fslroi ${gdcFolder}/${NameOffMRI}_gdc ${gdcFolder}/${NameOffMRI}_gdc_warp 0 3
    ${RUN} ${FSLDIR}/bin/fslmaths ${gdcFolder}/${NameOffMRI}_gdc_warp -mul 0 ${gdcFolder}/${NameOffMRI}_gdc_warp
    ${RUN} ${FSLDIR}/bin/imcp ${rfMRIrawFolder}/${OrigScoutName} ${gdcFolder}/${ScoutName}_gdc
    #make fake jacobians of all 1s, for completeness
    ${RUN} ${FSLDIR}/bin/fslmaths ${rfMRIrawFolder}/${OrigScoutName} -mul 0 -add 1 ${gdcFolder}/${ScoutName}_gdc_warp_jacobian
    ${RUN} ${FSLDIR}/bin/fslroi ${gdcFolder}/${NameOffMRI}_gdc_warp ${gdcFolder}/${NameOffMRI}_gdc_warp_jacobian 0 1
    ${RUN} ${FSLDIR}/bin/fslmaths ${gdcFolder}/${NameOffMRI}_gdc_warp_jacobian -mul 0 -add 1 ${gdcFolder}/${NameOffMRI}_gdc_warp_jacobian
fi


log_Msg 3 "EPI Distortion Correction"
if [ ! $DistortionCorrection = "NONE" ] ; then
    log_Msg 3 "Performing EPI Distortion Correction"

    ${RUN} ${BRC_FMRI_SCR}/EPI_Distortion_Correction.sh \
           --workingdir=${DCFolder} \
           --topupfoldername=${topupFolderName} \
           --scoutin=${gdcFolder}/${ScoutName}_gdc \
           --SEPhaseNeg=${SpinEchoPhaseEncodeNegative} \
           --SEPhasePos=${SpinEchoPhaseEncodePositive} \
           --echospacing=${EchoSpacing} \
           --unwarpdir=${UnwarpDir} \
           --gdcoeffs=${GradientDistortionCoeffs} \
           --method=${DistortionCorrection} \
           --logfile=${logFile}
else
    log_Msg 3 "NOT Performing EPI Distortion Correction"

    ${RUN} ${FSLDIR}/bin/fslroi ${gdcFolder}/${NameOffMRI}_gdc ${DCFolder}/WarpField.nii.gz 0 3
    ${RUN} ${FSLDIR}/bin/fslmaths ${DCFolder}/WarpField.nii.gz -mul 0 ${DCFolder}/WarpField.nii.gz

    ${RUN} ${FSLDIR}/bin/fslroi ${DCFolder}/WarpField.nii.gz ${DCFolder}/Jacobian.nii.gz 0 1
    ${RUN} ${FSLDIR}/bin/fslmaths ${DCFolder}/Jacobian.nii.gz -mul 0 -add 1 ${DCFolder}/Jacobian.nii.gz

    ${FSLDIR}/bin/imcp ${gdcFolder}/${ScoutName}_gdc ${DCFolder}/SBRef_dc
    ${RUN} ${FSLDIR}/bin/fslmaths ${DCFolder}/SBRef_dc -mul 0 -add 1 ${DCFolder}/PhaseOne_gdc_dc
    ${RUN} ${FSLDIR}/bin/fslmaths ${DCFolder}/SBRef_dc -mul 0 -add 1 ${DCFolder}/PhaseTwo_gdc_dc
fi
