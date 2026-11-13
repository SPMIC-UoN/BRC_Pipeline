#!/bin/bash
# Last update: 13/10/2026

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#

set -e

# --------------------------------------------------------------------------------
#  Usage Description Function
# --------------------------------------------------------------------------------

Usage()
{
  echo " "
  echo " "
  echo "`basename $0`: Description"
  echo " "
  echo "Extracts the IDPs of each subject and merges them into the group files <outdir>/Group_IDP/IDPs.tsv and IDPs.txt."
  echo "In cluster mode, one job is submitted per subject, plus one job that merges the subjects when all of them are finished."
  echo "A subject whose IDPs could not be extracted is set to NaN and listed in <outdir>/Group_IDP/list/missing_subjects.txt."
  echo "To recover such subjects, run the extraction for them again and then run this script with --mergeonly and the full list."
  echo " "
  echo "Usage: `basename $0`"
  echo "Compulsory arguments (You MUST set one or more of):"
  echo " --in <path>                     A list of subject IDs that are pre-processed"
  echo " --indir <path>                  The full path of the input directory. All of the IDs that are in the input list MUST have a pre-processed folder in this direcory"
  echo " --outdir <path>                 The full path of the output directory to save the output files"
  echo " "
  echo "Optional arguments (You may optionally specify one or more of):"
  echo " --mergeonly                     Only merge the already extracted IDPs of the subjects into the group files (IDPs.txt and IDPs.tsv)"
  echo " --help                          help"
  echo " "
  echo " "
}

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi

################################################## OPTION PARSING #####################################################

log=`echo "$@"`

# default values
MergeOnly="no"

while [ "$1" != "" ]; do
    case $1 in
      --in )                  shift
                              InputList=$1
                              ;;

      --indir )               shift
                              InputDIR=$1
                              ;;

      --outdir )              shift
                              OutDIR=$1
                              ;;

      --mergeonly )           MergeOnly="yes"
                              ;;

      * )                     Usage
                              exit 1

    esac
    shift
done

#=====================================================================================
###                          Sanity checking of arguments
#=====================================================================================

if [ X$InputList = X ] || [ X$InputDIR = X ] || [ X$OutDIR = X ] ; then
    echo ""
    echo "All of the compulsory arguments --in, -indir, and --outdir MUST be used"
    echo ""
    exit 1;
fi

# Maximum number of jobs that can be in the queue (pending + running) at the same time
MaxQueuedJobs=1000

# One job per subject + one job for merging; check they all fit in the queue before changing anything
if [ ${CLUSTER_MODE} = "YES" ] && [ ${MergeOnly} = "no" ] && command -v squeue > /dev/null 2>&1 ; then
    NSub=`awk 'NF' ${InputList} | wc -l`
    NQueued=`squeue -u ${USER} -h 2> /dev/null | wc -l`
    NNeeded=$(( ${NSub} + 1 ))

    if [ $(( ${NQueued} + ${NNeeded} )) -gt ${MaxQueuedJobs} ] ; then
        echo ""
        echo "ERROR: ${NNeeded} jobs are needed (${NSub} subjects + 1 merging job), but you already have ${NQueued} jobs in the queue"
        echo "       and the maximum number of jobs in the queue is ${MaxQueuedJobs}. No job has been submitted and no file has been changed."
        echo "       Please wait for some of your jobs to finish, or split the input list into smaller lists."
        echo ""
        exit 1
    fi
fi

#=====================================================================================
###                                Naming Conventions
#=====================================================================================

AnalysisFolderName="analysis"
logFolderName="log"
AnatMRIFolderName="anatMRI"
T1FolderName="T1"

GroupIDP_folder_name="Group_IDP"
List_Folder_name="list"
IDP_folder_name="IDP_files"

SubjectList_name="Subject_list.txt"
log_Name="log.txt"

#=====================================================================================
###                                  Setup PATHS
#=====================================================================================

if [ ! -d ${OutDIR} ]; then mkdir -p ${OutDIR}; fi

GroupIDPFolder=${OutDIR}/${GroupIDP_folder_name}
logFolder=${GroupIDPFolder}/${logFolderName}
ListFolder=${GroupIDPFolder}/${List_Folder_name}

if [ ! -d ${GroupIDPFolder} ]; then                          mkdir -p ${GroupIDPFolder}; fi
if [ ${MergeOnly} = "yes" ] ; then
    # Keep the logs of the subjects from the extraction run
    mkdir -p ${logFolder} ${ListFolder}
else
    if [ -e ${logFolder} ] ;       then rm -r ${logFolder}; fi;  mkdir ${logFolder}
    if [ -e ${ListFolder} ] ;      then rm -r ${ListFolder}; fi; mkdir -p ${ListFolder}
fi
if [ -e ${GroupIDPFolder}/IDPs.txt ] ;      then rm ${GroupIDPFolder}/IDPs.txt; fi

#=====================================================================================
###                              Setup the Log file
#=====================================================================================

${RUN} ${BRCDIR}/Show_version.sh \
      --showdiff="no" \
      --logfile=${logFolder}/${log_Name}
Start_Time="$(date -u +%s)"

source ${BRC_GLOBAL_SCR}/log.shlib  # Logging related functions
log_SetPath "${logFolder}/${log_Name}"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "Original command:"
log_Msg 2 "$log"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "Parsing Command Line Options"
log_Msg 2 "InputList: ${InputList}"
log_Msg 2 "InputDIR: ${InputDIR}"
log_Msg 2 "OutDIR: ${OutDIR}"
log_Msg 2 "MergeOnly: ${MergeOnly}"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

#=====================================================================================
###                                   DO WORK
#=====================================================================================

# List of the subjects (first column of the input list, empty lines are ignored)
awk 'NF {print $1}' ${InputList} > ${ListFolder}/${SubjectList_name}
NSub=`cat ${ListFolder}/${SubjectList_name} | wc -l`

log_Msg 3 "Number of subjects: ${NSub}"

MergeOptions="--listfolder=${ListFolder} --subjectlist_name=${SubjectList_name} --inputdir=${InputDIR} --analysisfoldername=${AnalysisFolderName} --idp_folder_name=${IDP_folder_name} --groupidpfolder=${GroupIDPFolder} --starttime=${Start_Time} --logidpfolder=${logFolder}/${log_Name}"

if [ ${MergeOnly} = "yes" ] ; then

    ${BRC_IDPEXTRACT_SCR}/idp_extract_part_2.sh ${MergeOptions}
    exit 0

fi

# Remove the IDP file of the previous run of each subject, so that only the outputs of this run are merged
for Subject in $(cat ${ListFolder}/${SubjectList_name}) ; do
    if [ -e ${InputDIR}/${Subject}/${AnalysisFolderName}/${IDP_folder_name}/IDPs.txt ] ; then
        rm ${InputDIR}/${Subject}/${AnalysisFolderName}/${IDP_folder_name}/IDPs.txt
    fi
done

if [ ${CLUSTER_MODE} = "YES" ] ; then

    jobIDs=""
    for Subject in $(cat ${ListFolder}/${SubjectList_name}) ; do

        jobID1=`${JOBSUBpath}/jobsub -q cpu -p 1 -s BRC_IDPEx_${Subject} -t 00:25:00 -m 16 -c "${BRC_IDPEXTRACT_SCR}/idp_extract_part_1.sh --subject=${Subject} --inputdir=${InputDIR} --analysisfoldername=${AnalysisFolderName} --idp_folder_name=${IDP_folder_name} --logfile=${logFolder}/${Subject}.txt" &`
        jobID1=`echo -e $jobID1 | awk '{ print $NF }'`
        echo "jobID_1 (${Subject}): ${jobID1}"

        if [ "X${jobIDs}" = "X" ] ; then
            jobIDs=${jobID1}
        else
            jobIDs=${jobIDs}:${jobID1}
        fi
    done

    jobID2=`${JOBSUBpath}/jobsub -q cpu -p 1 -s BRC_IDPEx_merge -t 01:00:00 -m 4 -w ${jobIDs} -c "${BRC_IDPEXTRACT_SCR}/idp_extract_part_2.sh ${MergeOptions}" &`
    jobID2=`echo -e $jobID2 | awk '{ print $NF }'`
    echo "jobID_2 (merge): ${jobID2}"

else

    for Subject in $(cat ${ListFolder}/${SubjectList_name}) ; do
        ${BRC_IDPEXTRACT_SCR}/idp_extract_part_1.sh \
                              --subject=${Subject} \
                              --inputdir=${InputDIR} \
                              --analysisfoldername=${AnalysisFolderName} \
                              --idp_folder_name=${IDP_folder_name} \
                              --logfile=${logFolder}/${Subject}.txt
    done

    ${BRC_IDPEXTRACT_SCR}/idp_extract_part_2.sh ${MergeOptions}

fi
