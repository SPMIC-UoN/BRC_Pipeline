#!/bin/bash
# Last update: 30/03/2025

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
# Adapted from UK Biobank bb_post_bedpostx_gpu
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
log_Msg 3 "+                   START: BedpostX Post-processing                      +"
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

if [ ! -f ${bedpostxFolder}/nvox.txt ]; then
    log_Msg 3 "ERROR: nvox.txt not found - was brc_pre_bedpostx.sh run successfully?"
    exit 1
fi

if [ ! -d ${bedpostxFolder}/diff_parts/data_part_0000 ]; then
    log_Msg 3 "ERROR: bedpostX GPU output not found - was brc_bedpostx.sh run successfully?"
    exit 1
fi

#=====================================================================================
###                     Merge GPU output into final bedpostX files
#=====================================================================================

# Must match the options used in brc_bedpostx.sh exactly
opts="--nf=3 --fudge=1 --bi=3000 --nj=1250 --se=25 --model=2 --cnonlinear"

nvox=`cat ${bedpostxFolder}/nvox.txt`
log_Msg 3 "Merging GPU output parts with options: ${opts}"
log_Msg 3 "Number of brain voxels: ${nvox}"

# bedpostx_postproc_gpu.sh expects all output under ${subjdir}.bedpostX, but
# the BRC pipeline stores output in a custom bedpostxFolder path.
# Create a temporary symlink so FSL finds files at the path it constructs.
ln -sfn ${bedpostxFolder} ${dataFolder}.bedpostX

cleanup_symlink() {
    rm -f ${dataFolder}.bedpostX
}
trap cleanup_symlink EXIT

${FSLDIR}/bin/bedpostx_postproc_gpu.sh \
    --data=${dataFolder}/data \
    --mask=${bedpostxFolder}/nodif_brain_mask \
    -b ${bedpostxFolder}/bvals \
    -r ${bedpostxFolder}/bvecs \
    --forcedir \
    --logdir=${bedpostxFolder}/diff_parts \
    ${opts} \
    ${nvox} \
    1 \
    ${dataFolder} \
    ${FSLDIR}

rm -f ${dataFolder}.bedpostX
trap - EXIT

log_Msg 3 ""
log_Msg 3 "                   END: BedpostX Post-processing"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "
