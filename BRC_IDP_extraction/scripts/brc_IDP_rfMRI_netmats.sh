#!/bin/bash
# Last update: 13/10/2026

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
# Generate the rfMRI network matrices used by brc_IDP_rfMRI.sh:
#   1) Stage 1 of dual regression (fsl_glm) of the standard-space (MNI 2mm) fMRI data
#      against the group ICA maps (d25 and d100)
#   2) Full/partial correlation and node amplitudes (Python port of FSLNets, netmats/brc_IDP_netmats.py)
#
# Usage: brc_IDP_rfMRI_netmats.sh <subject_dir> <log_file>
#
# Outputs are saved in <subject_dir>/analysis/rfMRI/processed/netmats
# Nothing is written to stdout; progress is appended to <log_file> (the IDP extraction log)

set -e

source ${BRC_GLOBAL_SCR}/log.shlib  # Logging related functions

AnalysisFolderName="analysis"
rfMRIFolderName="rfMRI"
processedFolderName="processed"
data2stdFolderName="data2std"
netmatsFolderName="netmats"

direc=$1
logFile=$2

rfMRIProcFolder=${direc}/${AnalysisFolderName}/${rfMRIFolderName}/${processedFolderName}
rfMRI2std=${rfMRIProcFolder}/${data2stdFolderName}/rfMRI2std
netmatsFolder=${rfMRIProcFolder}/${netmatsFolderName}

StdMask=${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask

Dims="25 100"
Outputs="NodeAmplitudes fullcorr partialcorr"

log_SetPath "${logFile}"

#=====================================================================================
###                          Skip if the outputs already exist
#=====================================================================================

all_exist="yes"
for D in ${Dims} ; do
    for O in ${Outputs} ; do
        if [ ! -s ${netmatsFolder}/rfMRI_d${D}_${O}_v1.txt ] ; then all_exist="no"; fi
    done
done

if [ ${all_exist} = "yes" ] ; then
    exit 0
fi

#=====================================================================================
###                                 Sanity checking
#=====================================================================================

if [ `${FSLDIR}/bin/imtest ${rfMRI2std}` != 1 ] ; then
    # No processed fMRI data for this subject, so there is nothing to do
    exit 0
fi

if [ -e ${netmatsFolder} ] ; then rm -rf ${netmatsFolder}; fi; mkdir -p ${netmatsFolder}

log_Msg 2 "netmats: Input: ${rfMRI2std}"

# The group ICA maps and the brain mask are MNI 2mm (91x109x91), so the data must be on the same grid
dims=`${FSLDIR}/bin/fslval ${rfMRI2std} dim1`" "`${FSLDIR}/bin/fslval ${rfMRI2std} dim2`" "`${FSLDIR}/bin/fslval ${rfMRI2std} dim3`
pixdims=`${FSLDIR}/bin/fslval ${rfMRI2std} pixdim1`" "`${FSLDIR}/bin/fslval ${rfMRI2std} pixdim2`" "`${FSLDIR}/bin/fslval ${rfMRI2std} pixdim3`
dims=`echo ${dims}`

is_2mm=`echo ${pixdims} | awk '{ ok=1; for (i=1; i<=3; i++) { d=$i-2; if (d<0) d=-d; if (d>0.01) ok=0 }; print ok }'`

if [ "${dims}" != "91 109 91" ] || [ ${is_2mm} != 1 ] ; then
    log_Msg 2 "netmats: ERROR: ${rfMRI2std} is not on the MNI 2mm grid (dims: ${dims}, pixdims: `echo ${pixdims}`)"
    exit 1
fi

vols=`${FSLDIR}/bin/fslval ${rfMRI2std} dim4`
vols=`echo ${vols}`
tr=`${FSLDIR}/bin/fslval ${rfMRI2std} pixdim4`
tr=`echo ${tr}`

log_Msg 2 "netmats: Volumes: ${vols}, TR: ${tr}"

#=====================================================================================
###                    Stage 1 of dual regression (subject timeseries)
#=====================================================================================

for D in ${Dims} ; do
    log_Msg 2 "netmats: fsl_glm: d${D}"

    mkdir -p ${netmatsFolder}/rfMRI_${D}.dr
    ${FSLDIR}/bin/fsl_glm -i ${rfMRI2std} \
                          -d ${BRC_GLOBAL_DIR}/templates/melodic_IC_${D} \
                          -o ${netmatsFolder}/rfMRI_${D}.dr/dr_stage1.txt \
                          --demean \
                          -m ${StdMask} >> ${logFile} 2>&1
done

#=====================================================================================
###                                 Network matrices
#=====================================================================================

log_Msg 2 "netmats: Computing network matrices"

${FSLDIR}/bin/fslpython ${BRC_IDPEXTRACT_SCR}/netmats/brc_IDP_netmats.py ${netmatsFolder} >> ${logFile} 2>&1

for D in ${Dims} ; do
    for O in ${Outputs} ; do
        if [ ! -s ${netmatsFolder}/rfMRI_d${D}_${O}_v1.txt ] ; then
            log_Msg 2 "netmats: ERROR: missing output rfMRI_d${D}_${O}_v1.txt"
            exit 1
        fi
    done
done

log_Msg 2 "netmats: Done"
