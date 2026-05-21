#!/bin/bash
# Last update: 26/03/2025

# -e  Exit immediately if a command exits with a non-zero status.
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
InputList=`getopt1 "--inputlist" $@`
ListFolder=`getopt1 "--listfolder" $@`
SubjectList_name=`getopt1 "--subjectlist_name" $@`
InputDIR=`getopt1 "--inputdir" $@`
AnalysisFolderName=`getopt1 "--analysisfoldername" $@`
IDP_folder_name=`getopt1 "--idp_folder_name" $@`
GroupIDPFolder=`getopt1 "--groupidpfolder" $@`
Start_Time=`getopt1 "--starttime" $@`
logIDPFolder=`getopt1 "--logidpfolder" $@`

log_SetPath "${logIDPFolder}"

#=====================================================================================
###                          Build the header row (once, before the subject loop)
#=====================================================================================

# --- Part 1: shell-script IDPs from IDP_list.txt (column 2 = IDP short name) ---
shell_headers=`awk '{print $2}' ${BRC_GLOBAL_DIR}/config/IDP_list.txt | tr '\n' ' '`

# --- Part 2: FreeSurfer IDPs from FS_headers.txt (skip first entry "ID" as
#             subject ID is already in column 1 of the output) ---
fs_headers=`tail -n +2 ${BRC_GLOBAL_DIR}/config/FS_headers.txt | tr '\n' ' '`

# --- Part 3: rfMRI IDPs from rfMRI_headers.txt ---
rfmri_headers=`cat ${BRC_GLOBAL_DIR}/config/rfMRI_headers.txt | tr '\n' ' '`

# Assemble full header: SubjectID + all IDP names
full_header="SubjectID ${shell_headers}${fs_headers}${rfmri_headers}"
full_header=`echo $full_header | sed 's/  */ /g'`

# Write headers to group-level TSV (tab-separated with header)
echo "$full_header" | tr ' ' '\t' > ${GroupIDPFolder}/IDPs.tsv

# Plain text file (no header, space-separated — preserves backward compatibility)
if [ -e ${GroupIDPFolder}/IDPs.txt ] ; then rm ${GroupIDPFolder}/IDPs.txt; fi

log_Msg 2 "Header row written to IDPs.tsv (${GroupIDPFolder}/IDPs.tsv)"

#=====================================================================================
###                                   DO WORK
#=====================================================================================

#Generate two different list for the subjects and their status
cut -d' ' -f1 < ${InputList} > ${ListFolder}/${SubjectList_name}

for Subject in $(cat ${ListFolder}/${SubjectList_name}) ; do
    log_Msg 3 "${Subject}"

    IDPFolder=${InputDIR}/${Subject}/${AnalysisFolderName}/${IDP_folder_name}

    if [ -e ${IDPFolder} ] ; then rm -r ${IDPFolder}; fi; mkdir ${IDPFolder}

    # --- Shell-script IDPs ---
    result="${Subject}"
    for elem in `cat ${BRC_GLOBAL_DIR}/config/IDP_list.txt | awk '{print $3}' | uniq` ; do
        if [ -f ${IDPFolder}/${elem}.txt ] ; then
            result="$result `cat ${IDPFolder}/${elem}.txt`"
        else
            result="$result `${BRC_IDPEXTRACT_SCR}/${elem}.sh ${InputDIR}/${Subject} ${IDP_folder_name}`"
        fi
    done

    # --- FreeSurfer IDPs ---
    fs_result=$(${BRC_IDPEXTRACT_SCR}/brc_FS_get_IDPs.py ${InputDIR} ${Subject} ${IDP_folder_name})
    result="$result $fs_result"

    # --- rfMRI IDPs ---
    rfmri_result=$(${BRC_IDPEXTRACT_SCR}/brc_IDP_rfMRI.sh ${InputDIR}/${Subject} ${IDP_folder_name})
    result="$result $rfmri_result"

    result=`echo $result | sed 's/  */ /g'`

    # Write per-subject plain text file (no header)
    echo $result > ${IDPFolder}/IDPs.txt
    echo $result

    # Append to group-level plain text file (no header, backward compatible)
    echo $result >> ${GroupIDPFolder}/IDPs.txt

    # Append to group-level TSV (tab-separated, has header from above)
    echo $result | tr ' ' '\t' >> ${GroupIDPFolder}/IDPs.tsv

done


END_Time="$(date -u +%s)"

${RUN} ${BRCDIR}/Show_version.sh \
      --showdiff="yes" \
      --start=${Start_Time} \
      --end=${END_Time} \
      --type=5 \
      --logfile=${logIDPFolder}
