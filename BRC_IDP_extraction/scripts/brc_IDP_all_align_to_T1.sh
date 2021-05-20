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
T2FolderName="T2"
processedFolderName="processed"
preprocFolderName="preproc"
tempFolderName="temp"
dataFolderName="data"
regFolderName="reg"

origDir=`pwd`
scriptName=`basename "$0"`
direc=$1
MC="-schedule $FSLDIR/etc/flirtsch/measurecost1.sch"

T1wSubjFolder=${direc}/${AnalysisFolderName}/${AnatMRIFolderName}/${T1FolderName}
T2wSubjFolder=${direc}/${AnalysisFolderName}/${AnatMRIFolderName}/${T2FolderName}
T1DataSubjFolder=${T1wSubjFolder}/${processedFolderName}/${dataFolderName}
T2DataSubjFolder=${T2wSubjFolder}/${processedFolderName}/${dataFolderName}

#baseT1="T1"
#baseT2_FLAIR="T2_FLAIR"
#baseFieldmap="fieldmap"
#baseSWI="SWI"
#basefMRI="fMRI/"
#baserfMRI="$basefMRI/rfMRI.ica/"
#basetfMRI="$basefMRI/tfMRI.feat/"

#for i in $baseT2_FLAIR/T2_FLAIR_brain $baseFieldmap/fieldmap_iout_to_T1 $baseSWI/SWI_TOTAL_MAG_to_T1 $baserfMRI/reg/example_func2highres $basetfMRI/reg/example_func2highres ; do
for i in ${T2DataSubjFolder}/T2_brain ; do
    if [ -f ${i}.nii.gz ] ; then
        result="$result `flirt -ref ${T1DataSubjFolder}/T1_brain -in $i ${MC} -refweight ${T1DataSubjFolder}/T1_brain_mask | head -1 | cut -f1 -d' ' `"
    else
        result="$result NaN"
    fi
done

#echo $result > ${direc}/${AnalysisFolderName}/IDP_files/${scriptName}.txt
echo $result > ${direc}/${AnalysisFolderName}/IDP_files/${scriptName%.*}.txt
echo $result
