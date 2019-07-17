#!/bin/bash
# Last update: 15/10/2018

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

################################################## OPTION PARSING #####################################################

# parse arguments
WD=`getopt1 "--workingdir" $@`  # "$1"
InputfMRI=`getopt1 "--infmri" $@`  # "$2"
GradientDistortionField=`getopt1 "--gdfield" $@`  # "${14}"
ScoutInputgdc=`getopt1 "--scoutgdcin" $@`  # "${15}"
T1w2StdImage=`getopt1 "--t12std" $@`  # "$3"
FinalfMRIResolution=`getopt1 "--fmriresout" $@`  # "$4"
MotionCorrectionType=`getopt1 "--motioncorrectiontype" $@`  # "${18}"
MotionMatrixFolder=`getopt1 "--motionmatdir" $@`  # "$9"
MotionMatrixPrefix=`getopt1 "--motionmatprefix" $@`  # "${10}"
OutputfMRI=`getopt1 "--ofmri" $@`  # "${11}"
OutputTransform=`getopt1 "--owarp" $@`  # "$8"
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                    START: Final Transformation                         +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "InputfMRI:$InputfMRI"
log_Msg 2 "GradientDistortionField:$GradientDistortionField"
log_Msg 2 "ScoutInputgdc:$ScoutInputgdc"
log_Msg 2 "T1w2StdImage:$T1w2StdImage"
log_Msg 2 "FinalfMRIResolution:$FinalfMRIResolution"
log_Msg 2 "MotionCorrectionType:$MotionCorrectionType"
log_Msg 2 "MotionMatrixFolder:$MotionMatrixFolder"
log_Msg 2 "MotionMatrixPrefix:$MotionMatrixPrefix"
log_Msg 2 "OutputfMRI:$OutputfMRI"
log_Msg 2 "OutputTransform:$OutputTransform"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

########################################## DO WORK ##########################################

T1w2StdImageFile=`basename $T1w2StdImage`
MotionMatrixFile=`basename "$MotionMatrixFolder"`

#Save TR for later
TR_vol=`${FSLDIR}/bin/fslval ${InputfMRI} pixdim4 | cut -d " " -f 1`
NumFrames=`${FSLDIR}/bin/fslval ${InputfMRI} dim4`


if [ -e ${WD}/Movement_RelativeRMS.txt ] ; then
    /bin/rm -v ${WD}/Movement_RelativeRMS.txt
fi

if [ -e ${WD}/Movement_AbsoluteRMS.txt ] ; then
    /bin/rm -v ${WD}/Movement_AbsoluteRMS.txt
fi

if [ -e ${WD}/Movement_RelativeRMS_mean.txt ] ; then
    /bin/rm -v ${WD}/Movement_RelativeRMS_mean.txt
fi

if [ -e ${WD}/Movement_AbsoluteRMS_mean.txt ] ; then
    /bin/rm -v ${WD}/Movement_AbsoluteRMS_mean.txt
fi
###Add stuff for RMS###

mkdir -p ${WD}/prevols
mkdir -p ${WD}/postvols
mkdir -p ${WD}/${MotionMatrixFile}

# Apply combined transformations to fMRI (combines gradient non-linearity distortion, motion correction, and registration to T1w space, but keeping fMRI resolution)
${FSLDIR}/bin/fslsplit ${InputfMRI} ${WD}/prevols/vol -t

FrameMergeSTRING=""
FrameMergeSTRINGII=""

for ((k=0; k < $NumFrames; k++)); do
    log_Msg 3 "Volume No:$k"

    vnum=`${FSLDIR}/bin/zeropad $k 4`

    if [ $MotionCorrectionType == "MCFLIRT6" ] || [ $MotionCorrectionType == "MCFLIRT12" ] ; then
        rmsdiff ${MotionMatrixFolder}/${MotionMatrixPrefix}${vnum} ${MotionMatrixFolder}/${MotionMatrixPrefix}0000 ${ScoutInputgdc} ${ScoutInputgdc}_mask.nii.gz | tail -n 1 >> ${WD}/Movement_AbsoluteRMS.txt

        if [ $k -eq 0 ] ; then
            echo "0" >> ${WD}/Movement_RelativeRMS.txt
        else
            rmsdiff ${MotionMatrixFolder}/${MotionMatrixPrefix}${vnum} $prevmatrix ${ScoutInputgdc} ${ScoutInputgdc}_mask.nii.gz | tail -n 1 >> ${WD}/Movement_RelativeRMS.txt
        fi

        prevmatrix="${MotionMatrixFolder}/${MotionMatrixPrefix}${vnum}"

        ${FSLDIR}/bin/convertwarp --relout --rel --ref=${WD}/prevols/vol${vnum}.nii.gz --warp1=${GradientDistortionField} --postmat=${MotionMatrixFolder}/${MotionMatrixPrefix}${vnum} --out=${WD}/${MotionMatrixFile}/${MotionMatrixPrefix}${vnum}_gdc_warp.nii.gz
    else
        ${FSLDIR}/bin/convertwarp --relout --rel --ref=${WD}/prevols/vol${vnum}.nii.gz --warp1=${GradientDistortionField} --postmat=$FSLDIR/etc/flirtsch/ident.mat --out=${WD}/${MotionMatrixFile}/${MotionMatrixPrefix}${vnum}_gdc_warp.nii.gz
#        ${FSLDIR}/bin/imcp ${GradientDistortionField} ${WD}/${MotionMatrixFile}/${MotionMatrixPrefix}${vnum}_gdc_warp.nii.gz
    fi

    ${FSLDIR}/bin/convertwarp --relout --rel --ref=${WD}/${T1w2StdImageFile}.${FinalfMRIResolution} --warp1=${WD}/${MotionMatrixFile}/${MotionMatrixPrefix}${vnum}_gdc_warp.nii.gz --warp2=${OutputTransform} --out=${WD}/${MotionMatrixFile}/${MotionMatrixPrefix}${vnum}_all_warp.nii.gz
    ${FSLDIR}/bin/fslmaths ${WD}/prevols/vol${vnum}.nii.gz -mul 0 -add 1 ${WD}/prevols/vol${vnum}_mask.nii.gz
    ${FSLDIR}/bin/applywarp --rel --interp=spline --in=${WD}/prevols/vol${vnum}.nii.gz --warp=${WD}/${MotionMatrixFile}/${MotionMatrixPrefix}${vnum}_all_warp.nii.gz --ref=${WD}/${T1w2StdImageFile}.${FinalfMRIResolution} --out=${WD}/postvols/vol${vnum}.nii.gz
    ${FSLDIR}/bin/applywarp --rel --interp=nn --in=${WD}/prevols/vol${vnum}_mask.nii.gz --warp=${WD}/${MotionMatrixFile}/${MotionMatrixPrefix}${vnum}_all_warp.nii.gz --ref=${WD}/${T1w2StdImageFile}.${FinalfMRIResolution} --out=${WD}/postvols/vol${vnum}_mask.nii.gz

    FrameMergeSTRING="${FrameMergeSTRING}${WD}/postvols/vol${vnum}.nii.gz "
    FrameMergeSTRINGII="${FrameMergeSTRINGII}${WD}/postvols/vol${vnum}_mask.nii.gz "
done

# Merge together results and restore the TR (saved beforehand)
${FSLDIR}/bin/fslmerge -tr ${OutputfMRI} $FrameMergeSTRING $TR_vol

${FSLDIR}/bin/fslmerge -tr ${OutputfMRI}_mask $FrameMergeSTRINGII $TR_vol
fslmaths ${OutputfMRI}_mask -Tmin ${OutputfMRI}_mask

#${FSLDIR}/bin/applywarp --rel --interp=nn -i ${ScoutInputgdc}_mask.nii.gz -r ${ResampRefImMask} -w ${OutputTransform} -o ${OutputfMRI}_mask

if [ $MotionCorrectionType == "MCFLIRT6" ] || [ $MotionCorrectionType == "MCFLIRT12" ] ; then
    ###Add stuff for RMS###
    cat ${WD}/Movement_RelativeRMS.txt | awk '{ sum += $1} END { print sum / NR }' >> ${WD}/Movement_RelativeRMS_mean.txt
    cat ${WD}/Movement_AbsoluteRMS.txt | awk '{ sum += $1} END { print sum / NR }' >> ${WD}/Movement_AbsoluteRMS_mean.txt
fi

log_Msg 3 ""
log_Msg 3 "                       END: Final Transformation"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "


################################################################################################
## Cleanup
################################################################################################

rm -r ${WD}/postvols
rm -r ${WD}/prevols
rm -r ${WD}/${MotionMatrixFile}
