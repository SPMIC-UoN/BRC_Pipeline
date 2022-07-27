#!/bin/sh
# Last update: 19/07/2022

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
preprocessFolderName="preproc"
tbssFolderName="tbss"

origDir=`pwd`
scriptName=`basename "$0"`
direc=$1

dMRIFolder=${direc}/${AnalysisFolderName}/${dMRIFolderName}
TBSSFolder=${dMRIFolder}/${preprocessFolderName}/${tbssFolderName}

#cd $direc

#basedMRI="dMRI"

#Setting the string of NaN in case there is a problem.
numVars="48"
nanResult="";
for i in $(seq 1 $numVars) ; do
    nanResult="NaN $nanResult" ;
done

result=""

#for i in FA MD MO L1 L2 L3 ICVF OD ISOVF ; do
for i in FA MD MO L1 L2 L3 ; do
    if [ -f ${TBSSFolder}/stats/JHUrois_${i}.txt ] ; then
        if [ `cat ${TBSSFolder}/stats/JHUrois_${i}.txt | wc -w` = 48 ] ; then
            miniResult=`cat ${TBSSFolder}/stats/JHUrois_${i}.txt`
        else
            miniResult="$nanResult"
        fi
    else
        miniResult="$nanResult"
    fi
    result="$result $miniResult"
done

#mkdir -p IDP_files

echo $result > ${direc}/${AnalysisFolderName}/IDP_files/${scriptName%.*}.txt
echo $result

#cd $origDir
