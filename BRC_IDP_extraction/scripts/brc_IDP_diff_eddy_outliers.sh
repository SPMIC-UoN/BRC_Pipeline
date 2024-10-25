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
dMRIFolderName="dMRI"
preprocFolderName="preproc"
eddyFolderName="eddy"

# origDir=`pwd`
scriptName=`basename "$0"`
direc=$1
IDP_folder_name=$2

basedMRI="dMRI"

dMRISubjFolder=${direc}/${AnalysisFolderName}/${dMRIFolderName}
dMRIDataSubjFolder=${dMRISubjFolder}/${preprocFolderName}/${eddyFolderName}

#Setting the string of NaN in case there is a problem.
numVars="1"
result="";
for i in $(seq 1 $numVars) ; do 
    result="NaN $result" ; 
done 

if [ -f ${dMRIDataSubjFolder}/eddy_unwarped_images.eddy_outlier_report ] ; then
    result=`wc -l ${dMRIDataSubjFolder}/eddy_unwarped_images.eddy_outlier_report | awk '{print $1}'`
fi

echo $result > ${direc}/${AnalysisFolderName}/${IDP_folder_name}/${scriptName%.*}.txt
echo $result
