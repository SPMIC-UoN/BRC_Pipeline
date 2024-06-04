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
processedFolderName="processed"
tempFolderName="temp"
regFolderName="reg"

origDir=`pwd`
scriptName=`basename "$0"`
direc=$1

T1wSubjFolder=${direc}/${AnalysisFolderName}/${AnatMRIFolderName}/${T1FolderName}

#Setting the string of NaN in case there is a problem.
numVars="139"
result="";
for i in $(seq 1 $numVars) ; do
    result="NaN $result" ;
done

filename1="${T1wSubjFolder}/${preprocFolderName}/${regFolderName}/std_2_T1_warp_field.nii.gz"
filename2="${T1wSubjFolder}/${processedFolderName}/seg/tissue/sing_chan/T1_pve_GM.nii.gz"

if [ -f ${filename1} ] ; then
    if [ -f ${filename2} ] ; then
        ${FSLDIR}/bin/applywarp -i ${BRC_GLOBAL_DIR}/templates/GMatlas -o ${T1wSubjFolder}/${tempFolderName}/GMatlas_to_T1 -r ${T1wSubjFolder}/processed/data/T1 -w ${filename1} --interp=nn
        result=`${FSLDIR}/bin/fslstats -K ${T1wSubjFolder}/${tempFolderName}/GMatlas_to_T1.nii.gz ${filename2} -m -v | xargs -n 3 | awk '{print "("$1"*"$2")"}' | bc `
    fi
fi

echo $result > ${direc}/${AnalysisFolderName}/IDP_files/${scriptName%.*}.txt
echo $result

################################################################################################
## Cleanup
################################################################################################

${FSLDIR}/bin/imrm ${T1wSubjFolder}/${tempFolderName}/GMatlas_to_T1
