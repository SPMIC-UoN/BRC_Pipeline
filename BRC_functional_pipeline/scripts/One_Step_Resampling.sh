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
ScoutInput=`getopt1 "--scoutin" $@`  # "${15}"
ScoutInputgdc=`getopt1 "--scoutgdcin" $@`  # "${15}"
T1w2StdImage=`getopt1 "--t12std" $@`  # "$3"
T1wBrainMask=`getopt1 "--t1brainmask" $@`  # "${12}"
GradientDistortionField=`getopt1 "--gdfield" $@`  # "${14}"
FinalfMRIResolution=`getopt1 "--fmriresout" $@`  # "$4"
fMRIToStructuralInput=`getopt1 "--fmri2structin" $@`  # "$6"
StructuralToStandard=`getopt1 "--struct2std" $@`  # "$7"
ScoutOutput=`getopt1 "--oscout" $@`  # "${16}"
OutputTransform=`getopt1 "--owarp" $@`  # "$8"
OutputInvTransform=`getopt1 "--oiwarp" $@`
JacobianOut=`getopt1 "--ojacobian" $@`  # "${18}"
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                    START: One Step Resampling                          +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "ScoutInput:$ScoutInput"
log_Msg 2 "ScoutInputgdc:$ScoutInputgdc"
log_Msg 2 "T1w2StdImage:$T1w2StdImage"
log_Msg 2 "T1wBrainMask:$T1wBrainMask"
log_Msg 2 "GradientDistortionField:$GradientDistortionField"
log_Msg 2 "FinalfMRIResolution:$FinalfMRIResolution"
log_Msg 2 "fMRIToStructuralInput:$fMRIToStructuralInput"
log_Msg 2 "StructuralToStandard:$StructuralToStandard"
log_Msg 2 "ScoutOutput:$ScoutOutput"
log_Msg 2 "OutputTransform:$OutputTransform"
log_Msg 2 "OutputInvTransform:$OutputInvTransform"
log_Msg 2 "JacobianOut:$JacobianOut"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

#BiasFieldFile=`basename "$BiasField"`
T1w2StdImageFile=`basename $T1w2StdImage`
T1wBrainMaskFile=`basename "$T1wBrainMask"`

if [ -e ${WD} ] ; then
    ${RUN} rm -r ${WD}
fi
mkdir -p $WD

########################################## DO WORK ##########################################

log_Msg 3 "Create fMRI resolution standard space files for T1w image, wmparc, and brain mask"
if [ ${FinalfMRIResolution} = "2" ] ; then
    ResampRefIm=$FSLDIR/data/standard/MNI152_T1_2mm
    ResampRefImMask=${ResampRefIm}_brain_mask
elif [ ${FinalfMRIResolution} = "1" ] ; then
    ResampRefIm=$FSLDIR/data/standard/MNI152_T1_1mm
    ResampRefImMask=${ResampRefIm}_brain_mask
else
    ${FSLDIR}/bin/flirt -interp spline -in ${T1w2StdImage} -ref ${T1w2StdImage} -applyisoxfm $FinalfMRIResolution -out ${WD}/${T1w2StdImageFile}.${FinalfMRIResolution}
    ResampRefIm=${WD}/${T1w2StdImageFile}.${FinalfMRIResolution}
fi

${FSLDIR}/bin/applywarp --rel --interp=spline -i ${T1w2StdImage} -r ${ResampRefIm} --premat=$FSLDIR/etc/flirtsch/ident.mat -o ${WD}/${T1w2StdImageFile}.${FinalfMRIResolution}

${FSLDIR}/bin/applywarp --rel --interp=nn -i ${T1wBrainMask}.nii.gz -r ${T1w2StdImage} --premat=$FSLDIR/etc/flirtsch/ident.mat -o ${WD}/${T1w2StdImageFile}_mask.nii.gz
${FSLDIR}/bin/applywarp --rel --interp=nn -i ${T1wBrainMask}.nii.gz -r ${T1w2StdImage} -w ${StructuralToStandard} -o ${WD}/${T1w2StdImageFile}_mask.nii.gz

log_Msg 3 "Create brain masks in this space (changing resolution)"
#${FSLDIR}/bin/applywarp --rel --interp=nn -i ${T1wBrainMask}.nii.gz -r ${WD}/${T1w2StdImageFile}.${FinalfMRIResolution} --premat=$FSLDIR/etc/flirtsch/ident.mat -o ${WD}/${T1wBrainMaskFile}.${FinalfMRIResolution}.nii.gz
#${FSLDIR}/bin/flirt  -interp nearestneighbour -in ${T1wBrainMask}.nii.gz -ref ${WD}/${T1w2StdImageFile}.${FinalfMRIResolution} -out ${WD}/${T1wBrainMaskFile}.${FinalfMRIResolution}.nii.gz -omat ${WD}/${T1wBrainMaskFile}.${FinalfMRIResolution}.mat
#${FSLDIR}/bin/flirt  -interp nearestneighbour -in ${WD}/${T1w2StdImageFile}_mask.nii.gz -ref ${WD}/${T1w2StdImageFile}.${FinalfMRIResolution} -out ${WD}/${T1wBrainMaskFile}.${FinalfMRIResolution}.nii.gz -omat ${WD}/${T1wBrainMaskFile}.${FinalfMRIResolution}.mat

${FSLDIR}/bin/applywarp --rel --interp=nn -i ${WD}/${T1w2StdImageFile}_mask.nii.gz -r ${WD}/${T1w2StdImageFile}.${FinalfMRIResolution} --premat=$FSLDIR/etc/flirtsch/ident.mat -o ${WD}/${T1wBrainMaskFile}.${FinalfMRIResolution}.nii.gz


#echo "Create versions of the biasfield (changing resolution)"
#${FSLDIR}/bin/applywarp --rel --interp=spline -i ${BiasField} -r ${WD}/${T1wBrainMaskFile}.${FinalfMRIResolution}.nii.gz --premat=$FSLDIR/etc/flirtsch/ident.mat -o ${WD}/${BiasFieldFile}.${FinalfMRIResolution}
#${FSLDIR}/bin/fslmaths ${WD}/${BiasFieldFile}.${FinalfMRIResolution} -thr 0.1 ${WD}/${BiasFieldFile}.${FinalfMRIResolution}

log_Msg 3 "Downsample warpfield (fMRI to standard) to increase speed"
${FSLDIR}/bin/convertwarp --relout --rel --warp1=${fMRIToStructuralInput} --warp2=${StructuralToStandard} --ref=${WD}/${T1w2StdImageFile}.${FinalfMRIResolution} --out=${OutputTransform}

###Add stuff for RMS###
${FSLDIR}/bin/invwarp -w ${OutputTransform} -o ${OutputInvTransform} -r ${ScoutInputgdc}
${FSLDIR}/bin/applywarp --rel --interp=nn -i ${WD}/${T1wBrainMaskFile}.${FinalfMRIResolution}.nii.gz -r ${ScoutInputgdc} -w ${OutputInvTransform} -o ${ScoutInputgdc}_mask.nii.gz

${FSLDIR}/bin/convertwarp --relout --rel --ref=${WD}/${T1w2StdImageFile}.${FinalfMRIResolution} --warp1=${GradientDistortionField} --warp2=${OutputTransform} --out=${WD}/Scout_gdc_MNI_warp.nii.gz
#${FSLDIR}/bin/applywarp --rel --interp=spline --in=${ScoutInput} -w ${WD}/Scout_gdc_MNI_warp.nii.gz -r ${WD}/${T1w2StdImageFile}.${FinalfMRIResolution} -o ${ScoutOutput}
${FSLDIR}/bin/applywarp --rel --interp=spline --in=${ScoutInputgdc} -w ${WD}/Scout_gdc_MNI_warp.nii.gz -r ${WD}/${T1w2StdImageFile}.${FinalfMRIResolution} -o ${ScoutOutput}


log_Msg 3 "Create spline interpolated version of Jacobian  (T1w space, fMRI resolution)"
${FSLDIR}/bin/convertwarp --relout --rel --ref=${fMRIToStructuralInput} --warp1=${GradientDistortionField} --warp2=${fMRIToStructuralInput} -o ${WD}/gdc_dc_warp --jacobian=${WD}/gdc_dc_jacobian
#but, convertwarp's jacobian is 8 frames - each combination of one-sided differences, so average them
${FSLDIR}/bin/fslmaths ${WD}/gdc_dc_jacobian -Tmean ${WD}/gdc_dc_jacobian

#and resample it to MNI space
${FSLDIR}/bin/applywarp --rel --interp=spline -i ${WD}/gdc_dc_jacobian -r ${WD}/${T1w2StdImageFile}.${FinalfMRIResolution} -w ${StructuralToStandard} -o ${JacobianOut}

log_Msg 3 ""
log_Msg 3 "                        END: One Step Resampling"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "


################################################################################################
## Cleanup
################################################################################################
