#!/bin/bash
# Last update: 10/10/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
set -e

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

# parse arguments
WD=`getopt1 "--workingdir" $@`
AtlasFile=`getopt1 "--atlas" $@`
LabelList=`getopt1 "--labellist" $@`
fMRIFile=`getopt1 "--infmri" $@`
DataResolution=`getopt1 "--dataresolution" $@`
GroupMapsFolder=`getopt1 "--groupmaps" $@`

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+                                                                        +"
echo "+                      START: Extract Label Maps                         +"
echo "+                                                                        +"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

SelectedLabels=""

if [ ${DataResolution} = "2" ] ; then
    ResampRefIm=$FSLDIR/data/standard/MNI152_T1_2mm
    ResampRefIm_mask=${ResampRefIm}_brain_mask
elif [ ${DataResolution} = "1" ] ; then
    ResampRefIm=$FSLDIR/data/standard/MNI152_T1_1mm
    ResampRefIm_mask=${ResampRefIm}_brain_mask
else
    ${FSLDIR}/bin/flirt -interp spline -in $FSLDIR/data/standard/MNI152_T1_1mm -ref $FSLDIR/data/standard/MNI152_T1_1mm -applyisoxfm $DataResolution -out ${WD}/MNI152_T1_${DataResolution}mm
    ${FSLDIR}/bin/flirt -interp spline -in $FSLDIR/data/standard/MNI152_T1_1mm_brain_mask -ref $FSLDIR/data/standard/MNI152_T1_1mm -applyisoxfm $DataResolution -out ${WD}/MNI152_T1_${DataResolution}mm_brain_mask
    ResampRefIm=${WD}/MNI152_T1_${DataResolution}mm
    ResampRefIm_mask=${ResampRefIm}_brain_mask
fi

if [ ! -d "${WD}/vols" ]; then mkdir ${WD}/vols; fi

for Label in $(cat $LabelList) ; do
    LABELS="$LABELS $Label"

    ${FREESURFER_HOME}/bin/mri_binarize --i $AtlasFile --o ${WD}/vols/label_`${FSLDIR}/bin/zeropad $Label 4`.nii.gz --match $Label
    ${FSLDIR}/bin/fslmaths ${WD}/vols/label_`${FSLDIR}/bin/zeropad $Label 4`.nii.gz -mul 10 -add ${ResampRefIm_mask} ${WD}/vols/label_`${FSLDIR}/bin/zeropad $Label 4`.nii.gz
done

${FSLDIR}/bin/fslmerge -tr ${WD}/Image_4D ${WD}/vols/label_* 1

SelectedLabels="--match ${LABELS}"

${FREESURFER_HOME}/bin/mri_binarize --i $AtlasFile --o ${WD}/temp_atlas.nii.gz $SelectedLabels
${FSLDIR}/bin/fslmaths $AtlasFile -mul ${WD}/temp_atlas ${WD}/temp_atlas

if [ -e ${GroupMapsFolder} ] ; then
    rm -r ${GroupMapsFolder}
fi
mkdir -p $GroupMapsFolder
${FSLDIR}/bin/slices_summary ${WD}/Image_4D 4 ${ResampRefIm} ${GroupMapsFolder}

echo ""
echo "                        START: Extract Label Maps"
echo "                    END: `date`"
echo "=========================================================================="
echo "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

rm -r ${WD}/vols
