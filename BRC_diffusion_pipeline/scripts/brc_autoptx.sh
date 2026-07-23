#!/bin/bash
# Last update: 10/04/2025

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
# Runs automated probabilistic tractography (AutoPtx).
# Based on bb_trackSubjectStruct (De Groot et al., NeuroImage 2013;
# Alfaro-Almagro et al., NeuroImage 2018).
#
# Requires:
#   - BedpostX output (merged_* samples)
#   - TBSS nonlinear warps: MNI_to_dti_FA_warp and dti_FA_to_MNI_warp
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
tbssFolder=`getopt1 "--tbssfolder" $@`
autoptxFolder=`getopt1 "--autoptxfolder" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                     START: AutoPtx Tractography                        +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "dataFolder:     ${dataFolder}"
log_Msg 2 "bedpostxFolder: ${bedpostxFolder}"
log_Msg 2 "tbssFolder:     ${tbssFolder}"
log_Msg 2 "autoptxFolder:  ${autoptxFolder}"
log_Msg 2 "LogFile:        ${LogFile}"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 3 `date`

#=====================================================================================
###                            Sanity checking of inputs
#=====================================================================================

if [ ! -f ${bedpostxFolder}/merged_th1samples.nii.gz ]; then
    log_Msg 3 "ERROR: BedpostX output not found: ${bedpostxFolder}/merged_th1samples.nii.gz"
    log_Msg 3 "       Run --autoptx only after BedpostX has completed successfully."
    exit 1
fi

mni2fa_warp="${tbssFolder}/FA/MNI_to_dti_FA_warp"
fa2mni_warp="${tbssFolder}/FA/dti_FA_to_MNI_warp"

if [ ! -f ${mni2fa_warp}.nii.gz ]; then
    log_Msg 3 "ERROR: TBSS MNI-to-FA warp not found: ${mni2fa_warp}.nii.gz"
    log_Msg 3 "       Run --tbss before --autoptx."
    exit 1
fi

if [ ! -f ${fa2mni_warp}.nii.gz ]; then
    log_Msg 3 "ERROR: TBSS FA-to-MNI warp not found: ${fa2mni_warp}.nii.gz"
    log_Msg 3 "       Run --tbss before --autoptx."
    exit 1
fi

protocolsDir="${BRC_GLOBAL_DIR}/data/autoptx_protocols"
if [ ! -d ${protocolsDir} ]; then
    log_Msg 3 "ERROR: AutoPtx protocol masks not found: ${protocolsDir}"
    exit 1
fi

structureList="${BRC_GLOBAL_DIR}/config/autoptx_structureList"
if [ ! -f ${structureList} ]; then
    log_Msg 3 "ERROR: Structure list not found: ${structureList}"
    exit 1
fi

#=====================================================================================
###                            Setup output directories
#=====================================================================================

tractsDir="${autoptxFolder}/tracts"
mkdir -p ${tractsDir}

# Base number of seeds per voxel (scaled by per-tract multiplier)
baseSeedsPerVox=300

log_Msg 3 "Protocol masks dir:  ${protocolsDir}"
log_Msg 3 "Structure list:      ${structureList}"
log_Msg 3 "MNI-to-FA warp:      ${mni2fa_warp}.nii.gz"
log_Msg 3 "FA-to-MNI warp:      ${fa2mni_warp}.nii.gz"
log_Msg 3 "Output tracts dir:   ${tractsDir}"

#=====================================================================================
###                         Run tractography for each tract
#=====================================================================================

while IFS= read -r line || [[ -n "${line}" ]]; do

    # Skip comment lines and blank lines
    [[ "${line}" =~ ^[[:space:]]*#.*$ ]] && continue
    [[ -z "${line// }" ]] && continue

    tractName=$(echo ${line} | awk '{print $1}')
    seedMult=$(echo ${line} | awk '{print $2}')

    # Total seeds = baseSeedsPerVox * multiplier (rounded to integer)
    nsamples=$(awk "BEGIN { v=int(${baseSeedsPerVox}*${seedMult}); printf \"%d\", (v < 1 ? 1 : v) }")

    protDir="${protocolsDir}/${tractName}"
    tractDir="${tractsDir}/${tractName}"

    if [ ! -d ${protDir} ]; then
        log_Msg 3 "WARNING: Protocol directory not found for '${tractName}', skipping."
        continue
    fi

    mkdir -p ${tractDir}

    log_Msg 3 "----------------------------------------------------------------------"
    log_Msg 3 "Tract: ${tractName}  (${nsamples} samples)"

    #----------------------------------------------------------------------------------
    # Warp masks from MNI space into FA/diffusion space
    #----------------------------------------------------------------------------------

    log_Msg 3 "  Warping seed mask to FA space"
    ${FSLDIR}/bin/applywarp \
        -i ${protDir}/seed \
        -r ${bedpostxFolder}/nodif_brain_mask \
        -w ${mni2fa_warp} \
        -o ${tractDir}/seed \
        --interp=nn

    log_Msg 3 "  Warping target (waypoint) mask to FA space"
    ${FSLDIR}/bin/applywarp \
        -i ${protDir}/target \
        -r ${bedpostxFolder}/nodif_brain_mask \
        -w ${mni2fa_warp} \
        -o ${tractDir}/target \
        --interp=nn

    log_Msg 3 "  Warping exclusion mask to FA space"
    ${FSLDIR}/bin/applywarp \
        -i ${protDir}/exclude \
        -r ${bedpostxFolder}/nodif_brain_mask \
        -w ${mni2fa_warp} \
        -o ${tractDir}/exclude \
        --interp=nn

    # Optional stop mask — relative path for use inside the cd subshell
    stop_arg=""
    if [ -f ${protDir}/stop.nii.gz ]; then
        log_Msg 3 "  Warping stop mask to FA space"
        ${FSLDIR}/bin/applywarp \
            -i ${protDir}/stop \
            -r ${bedpostxFolder}/nodif_brain_mask \
            -w ${mni2fa_warp} \
            -o ${tractDir}/stop \
            --interp=nn
        stop_arg="--stop=stop.nii.gz"
    fi

    #----------------------------------------------------------------------------------
    # Forward tractography: seed -> target (with exclusion)
    # Note: all mask paths are relative so they resolve correctly inside the subshell.
    # --dir=. tells probtrackx2 explicitly to write output to the current directory.
    #----------------------------------------------------------------------------------

    log_Msg 3 "  Running probtrackx2 (forward)"
    (cd ${tractDir} && ${FSLDIR}/bin/probtrackx2 \
        --samples=${bedpostxFolder}/merged \
        --mask=${bedpostxFolder}/nodif_brain_mask \
        --seed=seed.nii.gz \
        --waypoints=target.nii.gz \
        --avoid=exclude.nii.gz \
        ${stop_arg} \
        --nsamples=${nsamples} \
        --loopcheck \
        --onewaycondition \
        --dir=. \
        --out=fdt_paths \
        --forcedir \
        -V 0)

    # Check waytotal first: if 0, FSL does not write fdt_paths.nii.gz (by design).
    # This is a valid result meaning no streamlines reached the waypoint mask.
    if [ ! -f ${tractDir}/waytotal ]; then
        log_Msg 3 "  WARNING: waytotal not found for ${tractName} — probtrackx2 may have failed"
        continue
    fi
    waytotal_fwd=$(cat ${tractDir}/waytotal | tr -d '[:space:]')
    if [[ ! "${waytotal_fwd}" =~ ^[0-9]+$ ]] || [ "${waytotal_fwd}" -eq 0 ]; then
        log_Msg 3 "  No streamlines reached waypoint mask for ${tractName} (waytotal=${waytotal_fwd}), skipping"
        continue
    fi

    # waytotal > 0: fdt_paths.nii.gz must exist
    if [ ! -f ${tractDir}/fdt_paths.nii.gz ]; then
        found=$(find ${tractDir} -maxdepth 2 -name "fdt_paths*" 2>/dev/null | head -1)
        if [ -n "${found}" ]; then
            log_Msg 3 "  Relocating output: ${found} -> ${tractDir}/fdt_paths.nii.gz"
            mv "${found}" ${tractDir}/fdt_paths.nii.gz
        else
            log_Msg 3 "  WARNING: waytotal=${waytotal_fwd} but fdt_paths not found for ${tractName}"
            log_Msg 3 "  Full contents of ${tractDir}:"
            find ${tractDir} -maxdepth 3 | sort | while read f; do log_Msg 3 "    ${f}"; done
            continue
        fi
    fi

    #----------------------------------------------------------------------------------
    # Bidirectional tractography: if 'invert' flag exists, also run target -> seed
    # and add both density maps together (UKBB approach)
    #----------------------------------------------------------------------------------

    if [ -f ${protDir}/invert ]; then

        log_Msg 3 "  Running probtrackx2 (inverted: target->seed)"
        (cd ${tractDir} && ${FSLDIR}/bin/probtrackx2 \
            --samples=${bedpostxFolder}/merged \
            --mask=${bedpostxFolder}/nodif_brain_mask \
            --seed=target.nii.gz \
            --waypoints=seed.nii.gz \
            --avoid=exclude.nii.gz \
            ${stop_arg} \
            --nsamples=${nsamples} \
            --loopcheck \
            --onewaycondition \
            --dir=. \
            --out=fdt_paths_inv \
            --forcedir \
            -V 0)

        # Guard for inverted output
        if [ ! -f ${tractDir}/fdt_paths_inv.nii.gz ]; then
            found_inv=$(find ${tractDir} -maxdepth 2 -name "fdt_paths_inv.nii.gz" 2>/dev/null | head -1)
            [ -n "${found_inv}" ] && mv "${found_inv}" ${tractDir}/fdt_paths_inv.nii.gz
        fi

        if [ -f ${tractDir}/fdt_paths_inv.nii.gz ]; then
            log_Msg 3 "  Merging forward and inverted density maps"
            ${FSLDIR}/bin/fslmaths \
                ${tractDir}/fdt_paths.nii.gz \
                -add ${tractDir}/fdt_paths_inv.nii.gz \
                ${tractDir}/fdt_paths.nii.gz
        else
            log_Msg 3 "  WARNING: fdt_paths_inv.nii.gz not found for ${tractName}, using forward only"
        fi

    fi

    #----------------------------------------------------------------------------------
    # Normalise by total streamline count reaching waypoints
    #----------------------------------------------------------------------------------

    if [ ! -f ${tractDir}/waytotal ]; then
        log_Msg 3 "  WARNING: waytotal not found for ${tractName}, skipping normalisation"
    else
        waytotal=$(cat ${tractDir}/waytotal | tr -d '[:space:]')
        if [[ "${waytotal}" =~ ^[0-9]+$ ]] && [ "${waytotal}" -gt 0 ]; then
            log_Msg 3 "  Normalising fdt_paths (waytotal=${waytotal})"
            ${FSLDIR}/bin/fslmaths \
                ${tractDir}/fdt_paths.nii.gz \
                -div ${waytotal} \
                ${tractDir}/fdt_paths_normalized.nii.gz
        else
            log_Msg 3 "  WARNING: waytotal=${waytotal}, skipping normalisation for ${tractName}"
        fi
    fi

    log_Msg 3 "  Done: ${tractName}"

done < "${structureList}"

log_Msg 3 ""
log_Msg 3 "                   END: AutoPtx Tractography"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "
