#!/bin/bash
# Last update: 12/06/2021

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
###                                   DO WORK
#=====================================================================================

#Generate two different list for the subjects and their status
cut -d' ' -f1 < ${InputList} > ${ListFolder}/${SubjectList_name}

for Subject in $(cat ${ListFolder}/${SubjectList_name}) ; do
    log_Msg 3 "${Subject}"

    IDPFolder=${InputDIR}/${Subject}/${AnalysisFolderName}/${IDP_folder_name}

    if [ -e ${IDPFolder} ] ; then rm -r ${IDPFolder}; fi; mkdir ${IDPFolder}

    result="${Subject}"
    for elem in `cat ${BRC_GLOBAL_DIR}/config/IDP_list.txt | awk '{print $3}' | uniq` ; do
        if [ -f ${IDPFolder}/${elem}.txt ] ; then
            result="$result `cat ${IDPFolder}/${elem}.txt`"
        else
            result="$result `${BRC_IDPEXTRACT_SCR}/${elem}.sh ${InputDIR}/${Subject}`"
        fi
    done

    result=`echo $result | sed 's/  / /g'`

    echo $result > ${IDPFolder}/IDPs.txt
    echo $result

    echo $result >> ${GroupIDPFolder}/IDPs.txt

done


END_Time="$(date -u +%s)"

${RUN} ${BRCDIR}/Show_version.sh \
      --showdiff="yes" \
      --start=${Start_Time} \
      --end=${END_Time} \
      --type=5 \
      --logfile=${logIDPFolder}
