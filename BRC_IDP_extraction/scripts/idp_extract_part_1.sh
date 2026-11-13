#!/bin/bash
# Last update: 13/10/2026

# Extract the IDPs of ONE subject and save them in <inputdir>/<subject>/<analysis>/<IDP folder>/IDPs.txt
# The group-level files (IDPs.txt and IDPs.tsv) are generated afterwards by idp_extract_part_2.sh
#
# If one of the IDP scripts fails, its IDPs are set to NaN and the remaining IDPs are still extracted.
# This script always exits with status 0, so that a failure never blocks the merging step.

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
Subject=`getopt1 "--subject" $@`
InputDIR=`getopt1 "--inputdir" $@`
AnalysisFolderName=`getopt1 "--analysisfoldername" $@`
IDP_folder_name=`getopt1 "--idp_folder_name" $@`
logSubjFile=`getopt1 "--logfile" $@`

log_SetPath "${logSubjFile}"

# Generate a string of n NaNs
nan_string()
{
    printf 'NaN %.0s' $(seq 1 $1)
}

#=====================================================================================
###                                   DO WORK
#=====================================================================================

extract_subject()
{
    # -e  Exit immediately if a command exits with a non-zero status.
    set -e

    log_Msg 3 "${Subject}"

    IDPFolder=${InputDIR}/${Subject}/${AnalysisFolderName}/${IDP_folder_name}

    if [ -e ${IDPFolder} ] ; then rm -r ${IDPFolder}; fi; mkdir ${IDPFolder}

    # --- Shell-script IDPs ---
    result="${Subject}"
    for elem in `cat ${BRC_GLOBAL_DIR}/config/IDP_list.txt | awk '{print $3}' | uniq` ; do
        if [ -f ${IDPFolder}/${elem}.txt ] ; then
            result="$result `cat ${IDPFolder}/${elem}.txt`"
        elif elem_result=`${BRC_IDPEXTRACT_SCR}/${elem}.sh ${InputDIR}/${Subject} ${IDP_folder_name}` ; then
            result="$result ${elem_result}"
        else
            log_Msg 2 "${Subject}: ${elem} failed, its IDPs will be NaN"
            result="$result `nan_string $(awk -v e=${elem} '$3==e' ${BRC_GLOBAL_DIR}/config/IDP_list.txt | wc -l)`"
        fi
    done

    # --- FreeSurfer IDPs ---
    if fs_result=$(${BRC_IDPEXTRACT_SCR}/brc_FS_get_IDPs.py ${InputDIR} ${Subject} ${IDP_folder_name}) ; then
        result="$result $fs_result"
    else
        log_Msg 2 "${Subject}: brc_FS_get_IDPs failed, its IDPs will be NaN"
        result="$result `nan_string $(tail -n +2 ${BRC_GLOBAL_DIR}/config/FS_headers.txt | wc -l)`"
    fi

    # --- rfMRI network matrices (inputs of the rfMRI IDPs) ---
    if ! ${BRC_IDPEXTRACT_SCR}/brc_IDP_rfMRI_netmats.sh ${InputDIR}/${Subject} ${logSubjFile} ; then
        log_Msg 2 "${Subject}: generating the rfMRI network matrices failed, the rfMRI IDPs will be NaN"
    fi

    # --- rfMRI IDPs ---
    if rfmri_result=$(${BRC_IDPEXTRACT_SCR}/brc_IDP_rfMRI.sh ${InputDIR}/${Subject} ${IDP_folder_name}) ; then
        result="$result $rfmri_result"
    else
        log_Msg 2 "${Subject}: brc_IDP_rfMRI failed, its IDPs will be NaN"
        result="$result `nan_string $(cat ${BRC_GLOBAL_DIR}/config/rfMRI_headers.txt | wc -w)`"
    fi

    result=`echo $result | sed 's/  */ /g'`

    # Write per-subject plain text file (no header)
    echo $result > ${IDPFolder}/IDPs.txt
    echo $result
}

# Run in a subshell, so that an unexpected error only stops this subject
( extract_subject )
status=$?

if [ ${status} -ne 0 ] ; then
    log_Msg 3 "${Subject}: IDP extraction failed (exit status ${status}), the subject will be NaN in the group files"
fi

exit 0
