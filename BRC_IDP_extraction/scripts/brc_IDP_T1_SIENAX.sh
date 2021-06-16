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
preprocFolderName="preproc"
SienaxFolderName="SIENAX"

origDir=`pwd`
scriptName=`basename "$0"`
direc=$1

T1wSubjFolder=${direc}/${AnalysisFolderName}/${AnatMRIFolderName}/${T1FolderName}

#Setting the string of NaN in case there is a problem.
numVars="11"
result="";
for i in $(seq 1 $numVars) ; do
    result="NaN $result" ;
done

filepath=${T1wSubjFolder}/${preprocFolderName}/${SienaxFolderName}
if [ ! -f ${filepath}/T1_sienax.txt ] && [ -f ${filepath}/report.sienax ] ; then
  echo `cat ${filepath}/report.sienax` | cut -d " " -f2,7,8,12,13,17,18,20,21,23,24 > ${filepath}/T1_sienax.txt
  result=`cat ${filepath}/T1_sienax.txt`

elif [ -f ${filepath}/T1_sienax.txt ] ; then
    result=`cat ${filepath}/T1_sienax.txt`
fi

echo $result > ${direc}/${AnalysisFolderName}/IDP_files/${scriptName%.*}.txt
echo $result
