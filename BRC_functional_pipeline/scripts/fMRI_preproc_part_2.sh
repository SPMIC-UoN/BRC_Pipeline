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
MotionCorrectionType=`getopt1 "--motioncorrectiontype" $@`
mcFolder=`getopt1 "--mcfolder" $@`
NameOffMRI=`getopt1 "--nameoffmri" $@`
regFolder=`getopt1 "--regfolder" $@`
fMRI2strOutputTransform=`getopt1 "--fmri2stroutputtransform" $@`
gdcFolder=`getopt1 "--gdcfolder" $@`
ScoutName=`getopt1 "--scoutname" $@`
MovementRegressor=`getopt1 "--movementregressor" $@`
MotionMatrixFolder=`getopt1 "--motionmatrixfolder" $@`
MotionMatrixPrefix=`getopt1 "--motionmatrixprefix" $@`
EddyFolder=`getopt1 "--eddyfolder" $@`
EddyOutput=`getopt1 "--eddyoutput" $@`
DistortionCorrection=`getopt1 "--dcmethod" $@`
topupFolderName=`getopt1 "--topupfodername" $@`
DCFolder=`getopt1 "--dcfolder" $@`
SpinEchoPhaseEncodeNegative=`getopt1 "--SEPhaseNeg" $@`
SpinEchoPhaseEncodePositive=`getopt1 "--SEPhasePos" $@`
UnwarpDir=`getopt1 "--unwarpdir" $@`
EchoSpacing=`getopt1 "--echospacing" $@`
EchoSpacing_fMRI=`getopt1 "--echospacingfmri" $@`
Slice2Volume=`getopt1 "--slice2vol" $@`
SliceSpec=`getopt1 "--slicespec" $@`
logFile=`getopt1 "--logfile" $@`

log_SetPath "${logFile}"

#=====================================================================================
###                                   DO WORK
#=====================================================================================

log_Msg 3 "MOTION CORRECTION"
case $MotionCorrectionType in

    MCFLIRT6 | MCFLIRT12)
#        STC_Input=${mcFolder}/${NameOffMRI}_mc
#        SSNR_motionparam=${mcFolder}/${NameOffMRI}_mc.par
#        fMRI_2_str_Input=${regFolder}/${fMRI2strOutputTransform}
#        OSR_Scout_In=${gdcFolder}/${ScoutName}_gdc

        ${RUN} ${BRC_FMRI_SCR}/MotionCorrection.sh \
              --workingdir=${mcFolder} \
              --inputfmri=${gdcFolder}/${NameOffMRI}_gdc \
              --scoutin=${gdcFolder}/${ScoutName}_gdc \
              --outputfmri=${mcFolder}/${NameOffMRI}_mc \
              --outputmotionregressors=${mcFolder}/${MovementRegressor} \
              --outputmotionmatrixfolder=${mcFolder}/${MotionMatrixFolder} \
              --outputmotionmatrixnameprefix=${MotionMatrixPrefix} \
              --motioncorrectiontype=${MotionCorrectionType} \
              --logfile=${logFile}

    ;;

    EDDY)
#        STC_Input=${EddyFolder}/${EddyOutput}
#        SSNR_motionparam=${EddyFolder}/${EddyOutput}.eddy_parameters
#        fMRI_2_str_Input=${EddyFolder}/${EddyOutput}
#        OSR_Scout_In=${EddyFolder}/SBRef_dc

        ${RUN} ${BRC_FMRI_SCR}/EddyPreprocessing.sh \
              --workingdir=${EddyFolder} \
              --inputfile=${gdcFolder}/${NameOffMRI}_gdc \
              --inscout=${gdcFolder}/${ScoutName}_gdc \
              --fmriname=${NameOffMRI} \
              --dcmethod=${DistortionCorrection} \
              --topupfodername=${topupFolderName} \
              --dcfolder=${DCFolder} \
              --SEPhaseNeg=${SpinEchoPhaseEncodeNegative} \
              --SEPhasePos=${SpinEchoPhaseEncodePositive} \
              --unwarpdir=${UnwarpDir} \
              --echospacing=${EchoSpacing} \
              --echospacingfmri=${EchoSpacing_fMRI} \
              --slice2vol=${Slice2Volume} \
              --slspec=${SliceSpec} \
              --output_eddy=${EddyOutput} \
              --outfolder=${DCFolder} \
              --logfile=${logFile}

    ;;

    *)
        log_Msg 3 "UNKNOWN MOTION CORRECTION METHOD: ${MotionCorrectionType}"
        exit 1
esac
