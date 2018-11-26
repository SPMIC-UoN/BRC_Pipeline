#!/bin/bash
# Last update: 08/10/2018

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
WD=`getopt1 "--workingdir" $@`
InputfMRI=`getopt1 "--infmri" $@`
FWHM=`getopt1 "--fwhm" $@`
MotionParam=`getopt1 "--motionparam" $@`
fmriName=`getopt1 "--fmriname" $@`
fMRI2StructMat=`getopt1 "--fmri2structin" $@`
Struct2StdWarp=`getopt1 "--struct2std" $@`
MotionCorrectionType=`getopt1 "--motioncorrectiontype" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+    START: Spatial Smoothing and Artifact/Physiological Noise Removal   +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "InputfMRI:$InputfMRI"
log_Msg 2 "FWHM:$FWHM"
log_Msg 2 "MotionParam:$MotionParam"
log_Msg 2 "fmriName:$fmriName"
log_Msg 2 "fMRI2StructMat:$fMRI2StructMat"
log_Msg 2 "Struct2StdWarp:$Struct2StdWarp"
log_Msg 2 "MotionCorrectionType:$MotionCorrectionType"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

########################################## DO WORK ##########################################

RepetitionTime=`${FSLDIR}/bin/fslval ${InputfMRI} pixdim4 | cut -d " " -f 1`

${FSLDIR}/bin/imcp ${InputfMRI} ${WD}/${fmriName}

log_Msg 3 "calculate the mean across time ..."
${FSLDIR}/bin/fslmaths ${WD}/${fmriName} -Tmean ${WD}/${fmriName}_mean

# Perform bet2 on the mean_func data, use a threshold of .3 (.225 used for anatomical)
log_Msg 3 "Perform bet2 on the mean_func data ..."
${FSLDIR}/bin/bet2 ${WD}/${fmriName}_mean ${WD}/${fmriName}_brain -f 0.3 -n -m

# Perform bet2 on the mean_func data, use a threshold of .3 (.225 used for anatomical)
#echo "calculate the mask ..."
#${FSLDIR}/bin/fslmaths ${WD}/${fmriName}_mean -thr 1 -bin ${WD}/${fmriName}_mask

# Mask the motion corrected functional data with the mask to create the masked (bet) motion corrected functional data
log_Msg 3 "Mask the input functional data ..."
${FSLDIR}/bin/fslmaths ${WD}/${fmriName} -mas ${WD}/${fmriName}_brain_mask ${WD}/${fmriName}_bet

# Calculate the difference between the 98th and 2nd percentile (the region between the tails) and use that range as a threshold minimum on the prefiltered, motion corrected, masked functional data - so we are eliminating
# intensities outside that are below 2nd percentile, and above 98th percentile.

# Use fslstats to output the 2nd and 98th percentile
log_Msg 3 "Calculate the 98th and 2nd percentile ..."
lowerp=`${FSLDIR}/bin/fslstats ${WD}/${fmriName}_bet -p 2`
upperp=`${FSLDIR}/bin/fslstats ${WD}/${fmriName}_bet -p 98`
BBTHRESH=10       # Brain background threshold

# The brain/background threshold (to distinguish between brain and background is 10% - so we divide by 10)
# Anything above this value, then, is activation between the 2nd and 98th percentile that is likely to be
# brain activation and not noise or something else!
thresholdp=`echo "scale=6; (${upperp} - ${lowerp}) / ${BBTHRESH}" | bc`

# Use fslmaths to threshold the brain extracted data based on the highpass filter above
log_Msg 3 "threshold the brain extracted data based on the highpass filter ..."
# use "mask" as a binary mask, and Tmin to specify we want the minimum across time
${FSLDIR}/bin/fslmaths ${WD}/${fmriName}_bet -thr $thresholdp -Tmin -bin ${WD}/${fmriName}_mask -odt char

# Take the motion corrected functional data, and using "mask" as a mask (the -k option)
# output the 50th percentile (the mean?)
# We will need this later to calculate the intensity scaling factor
meanintensity=`${FSLDIR}/bin/fslstats ${WD}/${fmriName} -k ${WD}/${fmriName}_mask -p 50`
log_Msg 3 "meanintensity: $meanintensity"

# IM NOT SURE WHAT WE DO WITH THIS?
# difF is a spatial filtering option that specifies maximum filtering of all voxels
# I don't completely understand why we would filter one image with itself...
${FSLDIR}/bin/fslmaths ${WD}/${fmriName}_mask -dilF ${WD}/${fmriName}_mask

# We are now masking the motion corrected functional data with the mask to produce
# functional data that is motion corrected and thresholded based on the highpass filter
${FSLDIR}/bin/fslmaths ${WD}/${fmriName} -mas ${WD}/${fmriName}_mask ${WD}/${fmriName}_thresh

# We now take this functional data that is motion corrected, high pass filtered, and
# create a "mean_func" image that is the mean across time (Tmean)
${FSLDIR}/bin/fslmaths ${WD}/${fmriName}_thresh -Tmean ${WD}/${fmriName}_mean

# To run susan, FSLs tool for noise reduction, we need a brightness threshold.  Here is how to calculate:
# After thresholding, the values in the image are between $upperp-lowerp and $thresholdp
# If we set the expected noise level to .66, then anything below (($upperp-$lowerp)-$thresholdp)/0.66 should be noise.
# This is saying that we want the brightness threshold to be 66% of the median value.
# Note that the FSL "standard" is 75% (.75)
# This is the value that we use for bt, the "brightness threshold" in susan
log_Msg 3 "calculate brightness threshold"
uppert=`echo "scale=6; ${upperp} - ${lowerp}" | bc`

#thresholdpdifft=`echo "scale=8; ${uppert} - ${thresholdp}" | bc`
thresholdpdifft=`echo "scale=8; (${meanintensity} - ${lowerp}) * 0.75" | bc`

log_Msg 3 "brightness threshold: ${thresholdpdifft}"

# We also need to calculate the spatial size based on the smoothing.
# FWHM = 2.355*spatial size. So if desired FWHM = 6mm, spatial size = 2.54...
log_Msg 3 "calculate the spatial size based on the smoothing"
ssize=`echo "scale=11; ${FWHM} / 2.355" | bc`

log_Msg 3 "spatial size: ${ssize}"

# susan uses nonlinear filtering to reduce noise
# by only averaging a voxel with local voxels which have similar intensity
log_Msg 3 "Nonlinear filtering to reduce noise using 3D smmoothing, local median filter"
log_Msg 3 "determine the smoothing area from 1 secondary image"

${FSLDIR}/bin/susan ${WD}/${fmriName}_thresh $thresholdpdifft $ssize 3 1 1 ${WD}/${fmriName}_mean $thresholdpdifft ${WD}/${fmriName}_thresh_smooth
#${FSLDIR}/bin/imcp ${WD}/${fmriName} ${WD}/${fmriName}_thresh_smooth
#${FSLDIR}/bin/fslmaths ${WD}/${fmriName} -kernel gauss $ssize -fmean ${WD}/${fmriName}_thresh_smooth_fslmaths


# 3 means 3D smoothing
# 1 says to use a local median filter
# 1 says that we determine the smoothing area from 1 secondary image, "mean_func" and then we use the same brightness threshold for the secondary image.
# prefiltered_func_data_smooth is the output image

${FSLDIR}/bin/fslmaths ${WD}/${fmriName}_thresh_smooth -mas ${WD}/${fmriName}_mask ${WD}/${fmriName}_thresh_smooth


if [ -e ${WD}/ICA_AROMA ] ; then
    ${RUN} rm -r ${WD}/ICA_AROMA
fi


MC_arg="-in ${WD}/${fmriName}_thresh_smooth.nii.gz -out ${WD}/ICA_AROMA -tr ${RepetitionTime} -mc ${MotionParam} -m ${WD}/${fmriName}_mask.nii.gz -affmat ${fMRI2StructMat} -warp ${Struct2StdWarp}"


${RUN} python2.7 ${BRC_FMRI_SCR}/ICA_AROMA/ICA_AROMA.py ""$MC_arg""


log_Msg 3 ""
log_Msg 3 "      END: Spatial Smoothing and Artifact/Physiological Noise Removal"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

${FSLDIR}/bin/imrm ${WD}/${fmriName}
${FSLDIR}/bin/imrm ${WD}/${fmriName}_bet
${FSLDIR}/bin/imrm ${WD}/${fmriName}_mean
${FSLDIR}/bin/imrm ${WD}/${fmriName}_thresh
${FSLDIR}/bin/imrm ${WD}/${fmriName}_brain_mask
