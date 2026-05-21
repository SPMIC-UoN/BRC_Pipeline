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
IDP_folder_name=$2

T1wSubjFolder=${direc}/${AnalysisFolderName}/${AnatMRIFolderName}/${T1FolderName}

#Setting the string of NaN in case there is a problem.
numVars="15"
result="";
for i in $(seq 1 ${numVars}) ; do
    result="NaN $result" ;
done

filename=${T1wSubjFolder}/${processedFolderName}/${segFolderName}/${subFolderName}/${shapeFolderName}/T1_first_all_fast_firstseg.nii.gz
if [ -f ${filename} ] ; then
    dx=`${FSLDIR}/bin/fslval ${filename} pixdim1`
    dy=`${FSLDIR}/bin/fslval ${filename} pixdim2`
    dz=`${FSLDIR}/bin/fslval ${filename} pixdim3`
    result=`${FSLDIR}/bin/fslstats ${filename} -H 58 0.5 58.5 | sed 's/\.000000//g' | awk 'BEGIN { ORS = " " } { print }' | awk -v dx="$dx" -v dy="$dy" -v dz="$dz" '{vv=dx*dy*dz; print $10*vv " " $49*vv " " $11*vv " " $50*vv " " $12*vv " " $51*vv " " $13*vv " " $52*vv " " $17*vv " " $53*vv " " $18*vv " " $54*vv " " $26*vv " " $58*vv " " $16*vv}' `
fi

echo $result > ${direc}/${AnalysisFolderName}/${IDP_folder_name}/${scriptName%.*}.txt
echo $result
