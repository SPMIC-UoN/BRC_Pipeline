#!/bin/bash
# Last update: 28/09/2018

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
WD=`getopt1 "--workingdir" $@`  # "$1"
PhaseEncodeOne=`getopt1 "--phaseone" $@`  # "$2" #SCRIPT ASSUMES PhaseOne is the 'negative' direction when setting up the acqparams.txt file for TOPUP
PhaseEncodeTwo=`getopt1 "--phasetwo" $@`  # "$3" #SCRIPT ASSUMES PhaseTwo is the 'positive' direction when setting up the acqparams.txt file for TOPUP
ScoutInputName=`getopt1 "--scoutin" $@`  # "$4"
EchoSpacing=`getopt1 "--echospacing" $@`  # "$5"
UnwarpDir=`getopt1 "--unwarpdir" $@`  # "$6"
DistortionCorrectionWarpFieldOutput=`getopt1 "--owarp" $@`  # "$7"
DistortionCorrectionMagnitudeOutput=`getopt1 "--ofmapmag" $@`
DistortionCorrectionMagnitudeBrainOutput=`getopt1 "--ofmapmagbrain" $@`
DistortionCorrectionFieldOutput=`getopt1 "--ofmap" $@`
JacobianOutput=`getopt1 "--ojacobian" $@`  # "$8"
GradientDistortionCoeffs=`getopt1 "--gdcoeffs" $@`  # "$9"
TopupConfig=`getopt1 "--topupconfig" $@`  # "${11}"
OutFolder=`getopt1 "--outfolder" $@`  # "${11}"
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+         START: Topup Field Map Generation and Gradient Unwarping       +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "PhaseEncodeOne:$PhaseEncodeOne"
log_Msg 2 "PhaseEncodeTwo:$PhaseEncodeTwo"
log_Msg 2 "ScoutInputName:$ScoutInputName"
log_Msg 2 "EchoSpacing:$EchoSpacing"
log_Msg 2 "UnwarpDir:$UnwarpDir"
log_Msg 2 "DistortionCorrectionWarpFieldOutput:$DistortionCorrectionWarpFieldOutput"
log_Msg 2 "DistortionCorrectionMagnitudeOutput:$DistortionCorrectionMagnitudeOutput"
log_Msg 2 "DistortionCorrectionMagnitudeBrainOutput:$DistortionCorrectionMagnitudeBrainOutput"
log_Msg 2 "DistortionCorrectionFieldOutput:$DistortionCorrectionFieldOutput"
log_Msg 2 "JacobianOutput:$JacobianOutput"
log_Msg 2 "GradientDistortionCoeffs:$GradientDistortionCoeffs"
log_Msg 2 "TopupConfig:$TopupConfig"
log_Msg 2 "OutFolder:$OutFolder"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

mkdir -p $WD
########################################## DO WORK ##########################################

#check dimensions of phase versus sbref images
#should we also check spacing info? could be off by tiny fractions, so probably not

if [[ `${FSLDIR}/bin/fslhd $PhaseEncodeOne | grep '^pixdim[123]'` != `${FSLDIR}/bin/fslhd $ScoutInputName | grep '^pixdim[123]'` ]]
then
    log_Msg 3 "Error: Spin echo fieldmap (Neg) has different pixel size than scout image, this requires a manual fix"
    log_Msg 3 "For example using this command: flirt -in <SE fieldmap (Neg)> -ref <fMRI data> -applyxfm -out <resliced fieldmap>"
    exit 1
fi
if [[ `${FSLDIR}/bin/fslhd $PhaseEncodeOne | grep '^dim[123]'` != `${FSLDIR}/bin/fslhd $ScoutInputName | grep '^dim[123]'` ]]
then
    log_Msg 3 "Error: Spin echo fieldmap has different dimensions than scout image, this requires a manual fix"
    exit 1
fi
#for kicks, check that the spin echo images match
if [[ `${FSLDIR}/bin/fslhd $PhaseEncodeOne | grep '^dim[123]'` != `${FSLDIR}/bin/fslhd $PhaseEncodeTwo | grep '^dim[123]'` ]]
then
    log_Msg 3 "Error: Spin echo fieldmap images have different dimensions!"
    exit 1
fi

# Set up text files with all necessary parameters
txtfname=${WD}/acqparams.txt
if [ -e $txtfname ] ; then
    rm $txtfname
fi

# Calculate the readout time and populate the parameter file appropriately

# X direction phase encode
${BRC_FMRI_SCR}/Generate_Parameter_File.sh \
              --workingdir=${WD} \
              --phaseone=${PhaseEncodeOne} \
              --phasetwo=${PhaseEncodeTwo} \
              --unwarpdir=${UnwarpDir} \
              --echospacing=${EchoSpacing} \
              --out=${txtfname}

dimtOne=`${FSLDIR}/bin/fslval ${PhaseEncodeOne} dim4`
dimtTwo=`${FSLDIR}/bin/fslval ${PhaseEncodeTwo} dim4`

${FSLDIR}/bin/imcp $ScoutInputName ${WD}/SBRef.nii.gz

cp ${WD}/PhaseOne.nii.gz ${WD}/PhaseOne_gdc.nii.gz
cp ${WD}/PhaseTwo.nii.gz ${WD}/PhaseTwo_gdc.nii.gz
${FSLDIR}/bin/fslmerge -t ${WD}/BothPhases ${WD}/PhaseOne_gdc ${WD}/PhaseTwo_gdc
${FSLDIR}/bin/fslmaths ${WD}/PhaseOne_gdc.nii.gz -mul 0 -add 1 ${WD}/Mask

#Pad in Z by one slice if odd so that topup does not complain (slice consists of zeros that will be dilated by following step)
numslice=`${FSLDIR}/bin/fslval ${WD}/BothPhases dim3`


# Extrapolate the existing values beyond the mask (adding 1 just to avoid smoothing inside the mask)
${FSLDIR}/bin/fslmaths ${WD}/BothPhases -abs -add 1 -mas ${WD}/Mask -dilM -dilM -dilM -dilM -dilM ${WD}/BothPhases

# RUN TOPUP
${FSLDIR}/bin/topup --imain=${WD}/BothPhases \
                    --datain=$txtfname \
                    --config=${TopupConfig} \
                    --out=${WD}/Coefficents \
                    --iout=${WD}/Magnitudes \
                    --fout=${WD}/TopupField \
                    --dfout=${WD}/WarpField \
                    --rbmout=${WD}/MotionMatrix \
                    --jacout=${WD}/Jacobian \
                    --verbose


# UNWARP DIR = x,y
if [[ $UnwarpDir = "x" || $UnwarpDir = "y" ]] ; then
    # select the first volume from PhaseTwo
    VolumeNumber=$(($dimtOne + 1))
    vnum=`${FSLDIR}/bin/zeropad $VolumeNumber 2`

    # register scout to SE input (PhaseTwo) + combine motion and distortion correction
    ${FSLDIR}/bin/flirt -dof 6 -interp spline -in ${WD}/SBRef.nii.gz -ref ${WD}/PhaseTwo_gdc -omat ${WD}/SBRef2PhaseTwo_gdc.mat -out ${WD}/SBRef2PhaseTwo_gdc
    ${FSLDIR}/bin/convert_xfm -omat ${WD}/SBRef2WarpField.mat -concat ${WD}/MotionMatrix_${vnum}.mat ${WD}/SBRef2PhaseTwo_gdc.mat
    ${FSLDIR}/bin/convertwarp --relout --rel -r ${WD}/PhaseTwo_gdc --premat=${WD}/SBRef2WarpField.mat --warp1=${WD}/WarpField_${vnum} --out=${WD}/WarpField.nii.gz
    ${FSLDIR}/bin/imcp ${WD}/Jacobian_${vnum}.nii.gz ${WD}/Jacobian.nii.gz

    SBRefPhase=Two

# UNWARP DIR = -x,-y
elif [[ $UnwarpDir = "x-" || $UnwarpDir = "-x" || $UnwarpDir = "y-" || $UnwarpDir = "-y" ]] ; then
    # select the first volume from PhaseOne
    VolumeNumber=$((0 + 1))
    vnum=`${FSLDIR}/bin/zeropad $VolumeNumber 2`

    # register scout to SE input (PhaseOne) + combine motion and distortion correction
    ${FSLDIR}/bin/flirt -dof 6 -interp spline -in ${WD}/SBRef.nii.gz -ref ${WD}/PhaseOne_gdc -omat ${WD}/SBRef2PhaseOne_gdc.mat -out ${WD}/SBRef2PhaseOne_gdc
    ${FSLDIR}/bin/convert_xfm -omat ${WD}/SBRef2WarpField.mat -concat ${WD}/MotionMatrix_${vnum}.mat ${WD}/SBRef2PhaseOne_gdc.mat
    ${FSLDIR}/bin/convertwarp --relout --rel -r ${WD}/PhaseOne_gdc --premat=${WD}/SBRef2WarpField.mat --warp1=${WD}/WarpField_${vnum} --out=${WD}/WarpField.nii.gz
    ${FSLDIR}/bin/imcp ${WD}/Jacobian_${vnum}.nii.gz ${WD}/Jacobian.nii.gz

    SBRefPhase=One
fi

# PhaseTwo (first vol) - warp and Jacobian modulate to get distortion corrected output
VolumeNumber=$(($dimtOne + 1))
vnum=`${FSLDIR}/bin/zeropad $VolumeNumber 2`
${FSLDIR}/bin/applywarp --rel --interp=spline -i ${WD}/PhaseTwo_gdc -r ${WD}/PhaseTwo_gdc --premat=${WD}/MotionMatrix_${vnum}.mat -w ${WD}/WarpField_${vnum} -o ${WD}/PhaseTwo_gdc_dc
${FSLDIR}/bin/fslmaths ${WD}/PhaseTwo_gdc_dc -mul ${WD}/Jacobian_${vnum} ${WD}/PhaseTwo_gdc_dc_jac

# PhaseOne (first vol) - warp and Jacobian modulate to get distortion corrected output
VolumeNumber=$((0 + 1))
vnum=`${FSLDIR}/bin/zeropad $VolumeNumber 2`
${FSLDIR}/bin/applywarp --rel --interp=spline -i ${WD}/PhaseOne_gdc -r ${WD}/PhaseOne_gdc --premat=${WD}/MotionMatrix_${vnum}.mat -w ${WD}/WarpField_${vnum} -o ${WD}/PhaseOne_gdc_dc
${FSLDIR}/bin/fslmaths ${WD}/PhaseOne_gdc_dc -mul ${WD}/Jacobian_${vnum} ${WD}/PhaseOne_gdc_dc_jac

# Scout - warp and Jacobian modulate to get distortion corrected output
log_Msg 3 "create a spline interpolated image of scout (distortion corrected in same space)"
${FSLDIR}/bin/applywarp --rel --interp=spline -i ${WD}/SBRef.nii.gz -r ${WD}/SBRef.nii.gz -w ${WD}/WarpField.nii.gz -o ${WD}/SBRef_dc.nii.gz

log_Msg 3 "apply Jacobian correction to scout image"
${FSLDIR}/bin/fslmaths ${WD}/SBRef_dc.nii.gz -mul ${WD}/Jacobian.nii.gz ${WD}/SBRef_dc_jac.nii.gz

# Calculate Equivalent Field Map
${FSLDIR}/bin/fslmaths ${WD}/TopupField -mul 6.283 ${WD}/TopupField
${FSLDIR}/bin/fslmaths ${WD}/Magnitudes.nii.gz -Tmean ${WD}/Magnitude.nii.gz
${FSLDIR}/bin/bet ${WD}/Magnitude ${WD}/Magnitude_brain -f 0.35 -m #Brain extract the magnitude image

#copy images to specified outputs
if [ ! -z ${DistortionCorrectionWarpFieldOutput} ] ; then
    ${FSLDIR}/bin/imcp ${WD}/WarpField.nii.gz ${DistortionCorrectionWarpFieldOutput}.nii.gz
fi
if [ ! -z ${JacobianOutput} ] ; then
    ${FSLDIR}/bin/imcp ${WD}/Jacobian.nii.gz ${JacobianOutput}.nii.gz
fi
if [ ! -z ${DistortionCorrectionFieldOutput} ] ; then
    ${FSLDIR}/bin/imcp ${WD}/TopupField.nii.gz ${DistortionCorrectionFieldOutput}.nii.gz
fi
if [ ! -z ${DistortionCorrectionMagnitudeOutput} ] ; then
    ${FSLDIR}/bin/imcp ${WD}/Magnitude.nii.gz ${DistortionCorrectionMagnitudeOutput}.nii.gz
fi
if [ ! -z ${DistortionCorrectionMagnitudeBrainOutput} ] ; then
    ${FSLDIR}/bin/imcp ${WD}/Magnitude_brain.nii.gz ${DistortionCorrectionMagnitudeBrainOutput}.nii.gz
fi

${FSLDIR}/bin/imcp ${WD}/SBRef_dc ${OutFolder}/SBRef_dc
${FSLDIR}/bin/imcp ${WD}/PhaseOne_gdc_dc ${OutFolder}/PhaseOne_gdc_dc
${FSLDIR}/bin/imcp ${WD}/PhaseTwo_gdc_dc ${OutFolder}/PhaseTwo_gdc_dc

log_Msg 3 ""
log_Msg 3 "          END: Topup Field Map Generation and Gradient Unwarping"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

${FSLDIR}/bin/imrm ${WD}/PhaseOne
${FSLDIR}/bin/imrm ${WD}/PhaseOne_gdc
${FSLDIR}/bin/imrm ${WD}/PhaseTwo
${FSLDIR}/bin/imrm ${WD}/PhaseTwo_gdc
${FSLDIR}/bin/imrm ${WD}/SBRef
${FSLDIR}/bin/imrm ${WD}/Jacobian_*
${FSLDIR}/bin/imrm ${WD}/WarpField_*
rm ${WD}/SBRef2WarpField.mat
