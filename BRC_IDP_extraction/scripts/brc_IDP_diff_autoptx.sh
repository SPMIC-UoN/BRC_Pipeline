#!/bin/sh
# Last update: 03/05/2025

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#

set -e

AnalysisFolderName="analysis"
dMRIFolderName="dMRI"
preprocessFolderName="preproc"
processedFolderName="processed"
tbssFolderName="tbss"
dataFolderName="data"
autoptxFolderName="data.autoptx"

scriptName=`basename "$0"`
direc=$1
IDP_folder_name=$2

dMRIFolder=${direc}/${AnalysisFolderName}/${dMRIFolderName}
tbssFolder=${dMRIFolder}/${preprocessFolderName}/${tbssFolderName}
tbssStatsDir=${tbssFolder}/stats
fa2mniWarp=${tbssFolder}/FA/dti_FA_to_MNI_warp
autoptxFolder=${dMRIFolder}/${processedFolderName}/${dataFolderName}/${autoptxFolderName}
tractsDir=${autoptxFolder}/tracts

structureList="${BRC_GLOBAL_DIR}/config/autoptx_structureList"

numVars=243
nanResult=""
for i in $(seq 1 $numVars) ; do
    nanResult="NaN $nanResult"
done

if [ ! -d "${tractsDir}" ] || [ ! -f "${fa2mniWarp}.nii.gz" ] || [ ! -f "${structureList}" ] ; then
    echo $nanResult > ${direc}/${AnalysisFolderName}/${IDP_folder_name}/${scriptName%.*}.txt
    echo $nanResult
    exit 0
fi

tmpdir=$(mktemp -d /tmp/brc_autoptx_idp.XXXXXX)
trap "rm -rf ${tmpdir}" EXIT

tracts=$(awk '/^[^#[:space:]]/ {print $1}' "${structureList}")

result=""

for metric in FA MD MO L1 L2 L3 ICVF ISOVF ODI ; do

    metricMap="${tbssStatsDir}/all_${metric}.nii.gz"

    for tractName in ${tracts} ; do

        tractMask="${tractsDir}/${tractName}/fdt_paths_normalized.nii.gz"

        val="NaN"
        if [ -f "${tractMask}" ] && [ -f "${metricMap}" ] ; then
            ${FSLDIR}/bin/applywarp \
                -i "${tractMask}" \
                -r "${FSLDIR}/data/standard/FMRIB58_FA_1mm" \
                -w "${fa2mniWarp}" \
                -o "${tmpdir}/tract_mni" \
                --interp=trilinear
            ${FSLDIR}/bin/fslmaths "${tmpdir}/tract_mni" -mul "${metricMap}" "${tmpdir}/tmp_num"
            num=$(${FSLDIR}/bin/fslstats "${tmpdir}/tmp_num" -M)
            denom=$(${FSLDIR}/bin/fslstats "${tmpdir}/tract_mni" -M)
            val=$(awk "BEGIN {d=${denom}; if (d==0) print \"NaN\"; else printf \"%.10f\", ${num}/d}")
        fi

        result="${result} ${val}"

    done
done

echo $result > ${direc}/${AnalysisFolderName}/${IDP_folder_name}/${scriptName%.*}.txt
echo $result
