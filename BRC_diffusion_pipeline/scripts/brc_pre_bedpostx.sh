#!/bin/bash
# Last update: 30/03/2025

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
# Adapted from UK Biobank bb_pre_bedpostx_gpu
# (Alfaro-Almagro, Smith & Jenkinson, University of Oxford)
#
set -e

source $BRC_GLOBAL_SCR/log.shlib  # Logging related functions

# function for parsing options
getopt1()
{
    sopt="$1"
    shift 1
    for fn in $@ ; do
        if [ `echo $fn | grep -- "^${sopt}=" | wc -w` -gt 0 ] ; then
            echo $fn | sed "s/^${sopt}=//"
            return 0
        fi
    done
}

# parse arguments
dataFolder=`getopt1 "--datafolder" $@`
bedpostxFolder=`getopt1 "--bedpostxfolder" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                    START: BedpostX Pre-processing                      +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "dataFolder: ${dataFolder}"
log_Msg 2 "bedpostxFolder: ${bedpostxFolder}"
log_Msg 2 "LogFile: ${LogFile}"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 3 `date`

#=====================================================================================
###                            Sanity checking of inputs
#=====================================================================================

if [ ! -d ${dataFolder} ]; then
    log_Msg 3 "ERROR: data directory not found: ${dataFolder}"
    exit 1
fi

if [ ! -e ${dataFolder}/bvecs ]; then
    log_Msg 3 "ERROR: bvecs not found in ${dataFolder}"
    exit 1
fi

if [ ! -e ${dataFolder}/bvals ]; then
    log_Msg 3 "ERROR: bvals not found in ${dataFolder}"
    exit 1
fi

if [ `${FSLDIR}/bin/imtest ${dataFolder}/data` -eq 0 ]; then
    log_Msg 3 "ERROR: data image not found in ${dataFolder}"
    exit 1
fi

if [ `${FSLDIR}/bin/imtest ${dataFolder}/nodif_brain_mask` -eq 0 ]; then
    log_Msg 3 "ERROR: nodif_brain_mask not found in ${dataFolder}"
    exit 1
fi

# Check if bedpostX has already completed successfully
if [ -e ${bedpostxFolder}/xfms/eye.mat ]; then
    log_Msg 3 "WARNING: bedpostX output already exists at ${bedpostxFolder}"
    log_Msg 3 "Delete or rename ${bedpostxFolder} before repeating."
    exit 1
fi

#=====================================================================================
###                          Make bedpostX directory structure
#=====================================================================================

log_Msg 3 "Making bedpostX directory structure"

if [ -e ${bedpostxFolder} ] ; then rm -rf ${bedpostxFolder}; fi
mkdir -p ${bedpostxFolder}
mkdir -p ${bedpostxFolder}/diff_parts
mkdir -p ${bedpostxFolder}/logs
mkdir -p ${bedpostxFolder}/logs/logs_gpu
mkdir -p ${bedpostxFolder}/xfms

log_Msg 3 "Copying files to bedpostX directory"
cp ${dataFolder}/bvecs ${bedpostxFolder}/bvecs
cp ${dataFolder}/bvals ${bedpostxFolder}/bvals
${FSLDIR}/bin/imcp ${dataFolder}/nodif_brain_mask ${bedpostxFolder}/nodif_brain_mask

# Create nodif_brain for bedpostX (masked b0)
if [ `${FSLDIR}/bin/imtest ${dataFolder}/nodif` = 1 ] ; then
    ${FSLDIR}/bin/fslmaths ${dataFolder}/nodif \
                           -mas ${dataFolder}/nodif_brain_mask \
                           ${bedpostxFolder}/nodif_brain
fi

#=====================================================================================
###                         Split data for GPU processing
#=====================================================================================

log_Msg 3 "Splitting data for GPU processing"

# split_parts_gpu splits the 4D data into GPU-friendly chunks
# Arguments: data mask NULL(no prior) 0(no rician) 1(nparts) outdir
${FSLDIR}/bin/split_parts_gpu \
    ${dataFolder}/data \
    ${dataFolder}/nodif_brain_mask \
    ${dataFolder}/bvals \
    ${dataFolder}/bvecs \
    NULL \
    0 \
    1 \
    ${bedpostxFolder}

# Store number of brain voxels for the GPU run
nvox=`${FSLDIR}/bin/fslstats ${bedpostxFolder}/nodif_brain_mask -V | cut -d ' ' -f1`
echo ${nvox} > ${bedpostxFolder}/nvox.txt
log_Msg 3 "Number of brain voxels: ${nvox}"

log_Msg 3 ""
log_Msg 3 "                     END: BedpostX Pre-processing"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "
