#!/bin/bash
# Last update: 23/10/2024

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
dMRIFolderName="dMRI"
T1FolderName="T1"
T2FolderName="T2"
processedFolderName="processed"
dataFolderName="data"
data2strFolderName="data2str"

MC="-schedule $FSLDIR/etc/flirtsch/measurecost1.sch"

scriptName=`basename "$0"`
direc=$1
IDP_folder_name=$2

T1wSubjFolder=${direc}/${AnalysisFolderName}/${AnatMRIFolderName}/${T1FolderName}
T1wDataSubjFolder=${T1wSubjFolder}/${processedFolderName}/${dataFolderName}
T2wSubjFolder=${direc}/${AnalysisFolderName}/${AnatMRIFolderName}/${T2FolderName}
T2wDataSubjFolder=${T2wSubjFolder}/${processedFolderName}/${dataFolderName}
dMRISubjFolder=${direc}/${AnalysisFolderName}/${dMRIFolderName}
dMRIDataSubjFolder=${dMRISubjFolder}/${processedFolderName}/${data2strFolderName}


for i in ${T2wDataSubjFolder}/T2_brain ${dMRIDataSubjFolder}/nodif2str ; do
  if [ -f ${i}.nii.gz ] ; then
    result="$result `flirt -ref ${T1wDataSubjFolder}/T1_brain -in $i $MC -refweight ${T1wDataSubjFolder}/T1_brain_mask | head -1 | cut -f1 -d' ' `"
  else
    result="$result NaN"
  fi
done

echo $result > ${direc}/${AnalysisFolderName}/${IDP_folder_name}/${scriptName%.*}.txt
echo $result
