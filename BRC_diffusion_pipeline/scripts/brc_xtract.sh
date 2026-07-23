#!/bin/bash
# Last update: 10/04/2025

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
# Runs XTRACT automated white matter tractography.
# Requires:
#   - BedpostX output (merged_* samples)
#   - REG nonlinear warps (std_2_diff and diff_2_std warp coefficients)
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
bedpostxFolder=`getopt1 "--bedpostxfolder" $@`
regFolder=`getopt1 "--regfolder" $@`
xtractFolder=`getopt1 "--xtractfolder" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                      START: XTRACT Tractography                        +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "bedpostxFolder: ${bedpostxFolder}"
log_Msg 2 "regFolder:      ${regFolder}"
log_Msg 2 "xtractFolder:   ${xtractFolder}"
log_Msg 2 "LogFile:        ${LogFile}"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 3 `date`

#=====================================================================================
###                            Sanity checking of inputs
#=====================================================================================

if [ ! -f ${bedpostxFolder}/merged_th1samples.nii.gz ]; then
    log_Msg 3 "ERROR: BedpostX output not found: ${bedpostxFolder}/merged_th1samples.nii.gz"
    log_Msg 3 "       Run --autoptx or --xtract to trigger BedpostX before XTRACT."
    exit 1
fi

std2diff_warp="${regFolder}/std_2_diff_warp_coeff.nii.gz"
diff2std_warp="${regFolder}/diff_2_std_warp_coeff.nii.gz"

if [ ! -f ${std2diff_warp} ]; then
    log_Msg 3 "ERROR: Standard-to-diffusion warp not found: ${std2diff_warp}"
    log_Msg 3 "       Run --reg before --xtract."
    exit 1
fi

if [ ! -f ${diff2std_warp} ]; then
    log_Msg 3 "ERROR: Diffusion-to-standard warp not found: ${diff2std_warp}"
    log_Msg 3 "       Run --reg before --xtract."
    exit 1
fi

#=====================================================================================
###                               Run XTRACT
#=====================================================================================

log_Msg 3 "Running XTRACT tractography"
log_Msg 3 "  BedpostX folder: ${bedpostxFolder}"
log_Msg 3 "  Output folder:   ${xtractFolder}"
log_Msg 3 "  std2diff warp:   ${std2diff_warp}"
log_Msg 3 "  diff2std warp:   ${diff2std_warp}"

# When called from inside a SLURM job, FSL's fsl_sub switches to "shell plugin"
# mode and runs submitted jobs in the background — xtract returns immediately
# before tractography completes. Fix: inject a synchronous fsl_sub wrapper into
# PATH that runs each job script directly (blocking) instead of in background.
BRC_FSLSUB_TMPDIR=$(mktemp -d)

cat > ${BRC_FSLSUB_TMPDIR}/fsl_sub << 'FSLSUB_WRAPPER'
#!/bin/bash
# BRC synchronous fsl_sub wrapper.
# Strips all cluster submission flags and runs the job script directly.
script=""
skip_next=0
for arg in "$@"; do
    if [[ $skip_next -eq 1 ]]; then skip_next=0; continue; fi
    case "$arg" in
        -T|-q|-R|-N|-m|-l|-s|-p|-M|-j|-t|-c|-n|-e|-P|-a|-S|-x|-z|-r|-F)
            skip_next=1 ;;
        --job_name|--queue|--ram|--threads|--coprocessor|--coprocessor_class|\
--coprocessor_toolkit|--coprocessor_multi|--native|--priority|--mailto|\
--mailon|--tres|--project|--extra)
            skip_next=1 ;;
        --*=*) ;;
        --*) ;;
        *) script="$arg" ;;
    esac
done
if [[ -n "$script" ]]; then
    # Echo a fake job ID (required by callers that store the return value)
    echo $$
    bash "$script"
    exit $?
else
    echo "fsl_sub_brc: no script found in: $*" >&2
    exit 1
fi
FSLSUB_WRAPPER

chmod +x ${BRC_FSLSUB_TMPDIR}/fsl_sub

# Prepend tmpdir so our wrapper takes precedence over the system fsl_sub
export PATH="${BRC_FSLSUB_TMPDIR}:${PATH}"

${FSLDIR}/bin/xtract \
    -bpx ${bedpostxFolder} \
    -out ${xtractFolder} \
    -species HUMAN \
    -stdwarp ${std2diff_warp} ${diff2std_warp} \
    -gpu

# Restore PATH and clean up wrapper
export PATH="${PATH#${BRC_FSLSUB_TMPDIR}:}"
rm -rf ${BRC_FSLSUB_TMPDIR}

log_Msg 3 ""
log_Msg 3 "                    END: XTRACT Tractography"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "
