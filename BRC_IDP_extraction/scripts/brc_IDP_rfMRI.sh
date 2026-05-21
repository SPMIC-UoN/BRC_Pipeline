#!/bin/bash
# Last update: 26/03/2025

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#

set -e

AnalysisFolderName="analysis"
rfMRIFolderName="rfMRI"
processedFolderName="processed"
dataFolderName="data"

scriptName=`basename "$0"`
direc=$1
IDP_folder_name=$2

rfMRIDataSubjFolder=${direc}/${AnalysisFolderName}/${rfMRIFolderName}/${processedFolderName}/${dataFolderName}

# Number of expected values per file (based on actual node counts after noise removal)
# d25 decomposition: 21 nodes retained
# d100 decomposition: 55 nodes retained
n_d25_amp=21
n_d25_corr=210    # 21*(21-1)/2 upper triangle

n_d100_amp=55
n_d100_corr=1485  # 55*(55-1)/2 upper triangle

#Setting the string of NaN for each file in case it is missing
nan_d25_amp=$(printf 'NaN %.0s' $(seq 1 $n_d25_amp))
nan_d25_corr=$(printf 'NaN %.0s' $(seq 1 $n_d25_corr))
nan_d100_amp=$(printf 'NaN %.0s' $(seq 1 $n_d100_amp))
nan_d100_corr=$(printf 'NaN %.0s' $(seq 1 $n_d100_corr))

result=""

# --- d25 ---
if [ -f ${rfMRIDataSubjFolder}/rfMRI_d25_NodeAmplitudes_v1.txt ] ; then
    result="$result `cat ${rfMRIDataSubjFolder}/rfMRI_d25_NodeAmplitudes_v1.txt`"
else
    result="$result $nan_d25_amp"
fi

if [ -f ${rfMRIDataSubjFolder}/rfMRI_d25_fullcorr_v1.txt ] ; then
    result="$result `cat ${rfMRIDataSubjFolder}/rfMRI_d25_fullcorr_v1.txt`"
else
    result="$result $nan_d25_corr"
fi

if [ -f ${rfMRIDataSubjFolder}/rfMRI_d25_partialcorr_v1.txt ] ; then
    result="$result `cat ${rfMRIDataSubjFolder}/rfMRI_d25_partialcorr_v1.txt`"
else
    result="$result $nan_d25_corr"
fi

# --- d100 ---
if [ -f ${rfMRIDataSubjFolder}/rfMRI_d100_NodeAmplitudes_v1.txt ] ; then
    result="$result `cat ${rfMRIDataSubjFolder}/rfMRI_d100_NodeAmplitudes_v1.txt`"
else
    result="$result $nan_d100_amp"
fi

if [ -f ${rfMRIDataSubjFolder}/rfMRI_d100_fullcorr_v1.txt ] ; then
    result="$result `cat ${rfMRIDataSubjFolder}/rfMRI_d100_fullcorr_v1.txt`"
else
    result="$result $nan_d100_corr"
fi

if [ -f ${rfMRIDataSubjFolder}/rfMRI_d100_partialcorr_v1.txt ] ; then
    result="$result `cat ${rfMRIDataSubjFolder}/rfMRI_d100_partialcorr_v1.txt`"
else
    result="$result $nan_d100_corr"
fi

result=`echo $result | sed 's/^ //'`

echo $result > ${direc}/${AnalysisFolderName}/${IDP_folder_name}/${scriptName%.*}.txt
echo $result
