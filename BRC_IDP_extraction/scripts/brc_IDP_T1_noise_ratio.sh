#!/bin/bash
# Last update: 17/03/2021

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
tempFolderName="temp"
dataFolderName="data"

origDir=`pwd`
scriptName=`basename "$0"`
direc=$1

T1wSubjFolder=${direc}/${AnalysisFolderName}/${AnatMRIFolderName}/${T1FolderName}
DataSubjFolder=${T1wSubjFolder}/${processedFolderName}/${dataFolderName}
FastSubjFolder=${T1wSubjFolder}/${processedFolderName}/seg/tissue/sing_chan

#Setting the string of NaN in case there is a problem.
numVars="2"
result="";
for i in $(seq 1 $numVars) ; do
    result="NaN $result" ;
done

if [ -f ${FastSubjFolder}/T1_pveseg.nii.gz ] ; then
    ${FSLDIR}/bin/fslmaths ${FastSubjFolder}/T1_pveseg -thr 2 -uthr 2 -ero ${T1wSubjFolder}/${tempFolderName}/temp
    TheGrey=`${FSLDIR}/bin/fslstats ${DataSubjFolder}/T1 -k ${T1wSubjFolder}/${tempFolderName}/temp -m`
    ${FSLDIR}/bin/fslmaths ${FastSubjFolder}/T1_pveseg -thr 3 -uthr 3 -ero ${T1wSubjFolder}/${tempFolderName}/temp
    TheWhite=`${FSLDIR}/bin/fslstats ${DataSubjFolder}/T1 -k ${T1wSubjFolder}/${tempFolderName}/temp -m`
    ${FSLDIR}/bin/imrm ${T1wSubjFolder}/${tempFolderName}/temp
    TheBrain=`echo "1 k ${TheGrey} ${TheWhite} + 2 / p" | dc -`
    TheContrast=`echo "1 k ${TheWhite} ${TheGrey} - p" | dc -`
    TheThresh=`echo "${TheBrain} 10 / p" | dc -`
    TheNoise=`${FSLDIR}/bin/fslstats ${DataSubjFolder}/T1 -l 0.001 -u ${TheThresh} -s`
    TheSNRrecip=`echo "10 k ${TheNoise} ${TheBrain}    / p" | dc -`
    TheCNRrecip=`echo "10 k ${TheNoise} ${TheContrast} / p" | dc -`
    result="${TheSNRrecip} ${TheCNRrecip}"
fi

echo $result > ${direc}/${AnalysisFolderName}/IDP_files/${scriptName%.*}.txt
echo $result
