#!/bin/bash
# Last update: 18/03/2021

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#

set -e

# --------------------------------------------------------------------------------
#  Usage Description Function
# --------------------------------------------------------------------------------

AnalysisFolderName="analysis"
AnatMRIFolderName="anatMRI"
T1FolderName="T1"
processedFolderName="processed"
preprocFolderName="preproc"
tempFolderName="temp"
dataFolderName="data"
data2stdFolderName="data2std"
regFolderName="reg"

ST=$FSLDIR/data/standard
MC=$FSLDIR/etc/flirtsch/measurecost1.sch

origDir=`pwd`
scriptName=`basename "$0"`
direc=$1

T1wSubjFolder=${direc}/${AnalysisFolderName}/${AnatMRIFolderName}/${T1FolderName}
DataSubjFolder=${T1wSubjFolder}/${processedFolderName}/${dataFolderName}
RegSubjFolder=${T1wSubjFolder}/${preprocFolderName}/${regFolderName}
Data2StdSubjFolder=${T1wSubjFolder}/${processedFolderName}/${data2stdFolderName}

baseT1="T1"

result1="NaN"
result2="NaN"
result3="NaN"

if [ -f ${DataSubjFolder}/T1_brain.nii.gz ] && [ -f ${RegSubjFolder}/T1_2_std.mat ] ; then
    result1=`${FSLDIR}/bin/flirt -in ${DataSubjFolder}/T1_brain -ref ${ST}/MNI152_T1_1mm_brain -refweight ${ST}/MNI152_T1_1mm_brain_mask -init ${RegSubjFolder}/T1_2_std.mat -schedule ${MC} | head -1 | cut -f1 -d' '`
fi

if [ -f ${Data2StdSubjFolder}/T1_2_std_brain_lin.nii.gz ] ; then
    result2=`${FSLDIR}/bin/flirt -in ${Data2StdSubjFolder}/T1_2_std_brain_lin -ref ${ST}/MNI152_T1_1mm_brain -refweight ${ST}/MNI152_T1_1mm_brain_mask -schedule ${MC} | head -1 | cut -f1 -d' ' `
fi

if [ -f ${RegSubjFolder}/T1_2_std_warp_jac.nii.gz ] ; then
    ${FSLDIR}/bin/fslmaths ${RegSubjFolder}/T1_2_std_warp_jac -sub 1 -sqr ${T1wSubjFolder}/${tempFolderName}/temp
    result3=`${FSLDIR}/bin/fslstats ${T1wSubjFolder}/${tempFolderName}/temp -k ${ST}/MNI152_T1_1mm_brain_mask -m `
    ${FSLDIR}/bin/imrm ${T1wSubjFolder}/${tempFolderName}/temp
fi

result="$result1 $result2 $result3"

echo $result > ${direc}/${AnalysisFolderName}/IDP_files/${scriptName%.*}.txt
echo $result
