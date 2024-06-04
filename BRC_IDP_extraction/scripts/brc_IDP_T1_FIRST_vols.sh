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
segFolderName="seg"
subFolderName="sub"
shapeFolderName="shape"

origDir=`pwd`
scriptName=`basename "$0"`
direc=$1

T1wSubjFolder=${direc}/${AnalysisFolderName}/${AnatMRIFolderName}/${T1FolderName}

#Setting the string of NaN in case there is a problem.
numVars="15"
result="";
for i in $(seq 1 ${numVars}) ; do
    result="NaN $result" ;
done

filename=${T1wSubjFolder}/${processedFolderName}/${segFolderName}/${subFolderName}/${shapeFolderName}/T1_first_all_fast_firstseg.nii.gz
if [ -f ${filename} ] ; then
    result=`${FSLDIR}/bin/fslstats ${filename} -H 58 0.5 58.5 | sed 's/\.000000//g' | awk 'BEGIN { ORS = " " } { print }'| awk '{print $10 " " $49 " " $11 " " $50 " " $12 " " $51 " " $13 " " $52 " " $17 " " $53 " " $18 " " $54 " " $26 " " $58 " " $16 }' `
fi

echo $result > ${direc}/${AnalysisFolderName}/IDP_files/${scriptName%.*}.txt
echo $result
