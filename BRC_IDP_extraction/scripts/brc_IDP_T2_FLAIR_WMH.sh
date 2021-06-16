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
T2FolderName="T2"
preprocFolderName="preproc"
lesionsFolderName="lesions"

origDir=`pwd`
scriptName=`basename "$0"`
direc=$1

T2wSubjFolder=${direc}/${AnalysisFolderName}/${AnatMRIFolderName}/${T2FolderName}
LesionsSubjFolder=${T2wSubjFolder}/${preprocFolderName}/${lesionsFolderName}

#Setting the string of NaN in case there is a problem.
result="NaN"

if [ -f ${LesionsSubjFolder}/volume.txt ] ; then
    result=`cat ${LesionsSubjFolder}/volume.txt`
fi

echo $result > ${direc}/${AnalysisFolderName}/IDP_files/${scriptName%.*}.txt
echo $result
