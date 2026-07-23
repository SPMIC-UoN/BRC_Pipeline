#!/bin/bash
# Last update: 30/03/2025

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
# Adapted from UK Biobank bb_bedpostx_gpu
# (Alfaro-Almagro, Smith & Jenkinson, University of Oxford)
#
set -e

source $BRC_GLOBAL_SCR/log.shlib  # Logging related functions

# function for parsing options
getopt1()
{
    local sopt="$1"
    shift 1
    local fn
    for fn in "$@" ; do
        case "$fn" in
            "${sopt}"=*) printf '%s\n' "${fn#*=}"; return 0 ;;
        esac
    done
}

# parse arguments
dataFolder=`getopt1 "--datafolder" $@`
bedpostxFolder=`getopt1 "--bedpostxfolder" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                        START: BedpostX GPU Run                         +"
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

#=====================================================================================
###                              BedpostX model options
#
# These match the UK Biobank protocol (Ball-and-Sticks with 3 fibres, ARD prior):
#   --nf=3            : up to 3 fibre orientations per voxel
#   --fudge=1         : automatic relevance determination (ARD) weight
#   --bi=3000         : burn-in period (MCMC iterations before sampling)
#   --nj=1250         : number of jumps (MCMC samples)
#   --se=25           : sample every 25th jump
#   --model=2         : multi-shell zeppelin-cylinder model
#   --cnonlinear      : constrained nonlinear optimisation for initialisation
#=====================================================================================

opts="--nf=3 --fudge=1 --bi=3000 --nj=1250 --se=25 --model=2 --cnonlinear"

nvox=`cat ${bedpostxFolder}/nvox.txt`
log_Msg 3 "Running xfibres_gpu with options: ${opts}"
log_Msg 3 "Number of brain voxels: ${nvox}"

#=====================================================================================
###                              Run xfibres GPU
#=====================================================================================

${FSLDIR}/bin/xfibres_gpu \
    --data=${bedpostxFolder}/data_0 \
    --mask=${bedpostxFolder}/nodif_brain_mask \
    -b ${bedpostxFolder}/bvals \
    -r ${bedpostxFolder}/bvecs \
    --forcedir \
    --logdir=${bedpostxFolder}/diff_parts/data_part_0000 \
    ${opts} \
    ${dataFolder} \
    0 \
    1 \
    ${nvox}

log_Msg 3 ""
log_Msg 3 "                        END: BedpostX GPU Run"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "
