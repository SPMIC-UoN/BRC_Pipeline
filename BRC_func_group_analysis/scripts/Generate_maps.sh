#!/bin/bash
# Last update: 10/10/2018

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
          # if [ ] ; then Usage ; echo " " ; echo "Error:: option ${sopt} requires an argument"; exit 1 ; end
          return 0
      fi
  done
}

################################################## OPTION PARSING #####################################################

# parse arguments
WD=`getopt1 "--workingdir" $@`
AtlasFile=`getopt1 "--atlas" $@`
ResampRefIm=`getopt1 "--resamprefim" $@`
ResampRefIm_mask=`getopt1 "--resamprefimmask" $@`
LabelList=`getopt1 "--labellist" $@`
fMRIFile=`getopt1 "--infmri" $@`
DataResolution=`getopt1 "--dataresolution" $@`
GroupMapsFolder=`getopt1 "--groupmaps" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                      START: Extract Label Maps                         +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "AtlasFile:$AtlasFile"
log_Msg 2 "ResampRefIm:$ResampRefIm"
log_Msg 2 "ResampRefIm_mask:$ResampRefIm_mask"
log_Msg 2 "LabelList:$LabelList"
log_Msg 2 "fMRIFile:$fMRIFile"
log_Msg 2 "DataResolution:$DataResolution"
log_Msg 2 "GroupMapsFolder:$GroupMapsFolder"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

########################################## DO WORK ##########################################

SelectedLabels=""

if [ ! -d "${WD}/vols" ]; then mkdir ${WD}/vols; fi

log_Msg 3 "Extract individual label iamge"

for Label in $(cat $LabelList) ; do
    LABELS="$LABELS $Label"

    ${FREESURFER_HOME}/bin/mri_binarize --i $AtlasFile --o ${WD}/vols/label_`${FSLDIR}/bin/zeropad $Label 4`.nii.gz --match $Label
    ${FSLDIR}/bin/fslmaths ${WD}/vols/label_`${FSLDIR}/bin/zeropad $Label 4`.nii.gz -mul 10 -add ${ResampRefIm_mask} ${WD}/vols/label_`${FSLDIR}/bin/zeropad $Label 4`.nii.gz
done

${FSLDIR}/bin/fslmerge -tr ${WD}/Image_4D ${WD}/vols/label_* 1

SelectedLabels="--match ${LABELS}"

${FREESURFER_HOME}/bin/mri_binarize --i $AtlasFile --o ${WD}/temp_atlas.nii.gz $SelectedLabels
${FSLDIR}/bin/fslmaths $AtlasFile -mul ${WD}/temp_atlas ${WD}/temp_atlas

log_Msg 3 "Create summary image for each label mask"

if [ -e ${GroupMapsFolder} ] ; then
    rm -r ${GroupMapsFolder}
fi
mkdir -p $GroupMapsFolder
${FSLDIR}/bin/slices_summary ${WD}/Image_4D 4 ${ResampRefIm} ${GroupMapsFolder} -1

log_Msg 3 ""
log_Msg 3 "                         END: Extract Label Maps"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

rm -r ${WD}/vols
${FSLDIR}/bin/imrm ${WD}/Image_4D
