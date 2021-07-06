#!/bin/bash
# Last update: 16/03/2021

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
  echo "Usage: `basename $0`"
  echo "Compulsory arguments (You MUST set one or more of):"
  echo " --in <path>                     A list of subject IDs that are pre-processed"
  echo " --indir <path>                  The full path of the input directory. All of the IDs that are in the input list MUST have a pre-processed folder in this direcory"
  echo " --outdir <path>                 The full path of the output directory to save the output files"
  echo " "
  echo "Optional arguments (You may optionally specify one or more of):"
  echo " --help                          help"
  echo " "
  echo " "
}

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi

################################################## OPTION PARSING #####################################################

log=`echo "$@"`

# default values


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
if [ -e ${logFolder} ] ;       then rm -r ${logFolder}; fi;  mkdir ${logFolder}
if [ -e ${ListFolder} ] ;      then rm -r ${ListFolder}; fi; mkdir -p ${ListFolder}
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
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

#=====================================================================================
###                                   DO WORK
#=====================================================================================
if [ ${CLUSTER_MODE} = "YES" ] ; then

    NSub=`wc -l ${InputList}`
    NSub=`echo -e $NSub | awk '{ print $1 }'`
    minutes=$(( ${NSub} * 4 ))

    if [ "${minutes}" -lt 25 ] ; then
        hour=0
    else
        ((hour=${minutes}/60))
    fi
    ((min=${minutes}-${hour}*60))
    Time_Limit=${hour}:${min}:00

    jobID1=`${JOBSUBpath}/jobsub -q cpu -p 1 -s BRC_IDPEx -t ${Time_Limit} -m 10 -c "${BRC_IDPEXTRACT_SCR}/idp_extract_part_1.sh --inputlist=${InputList} --listfolder=${ListFolder} --subjectlist_name=${SubjectList_name} --inputdir=${InputDIR} --analysisfoldername=${AnalysisFolderName} --idp_folder_name=${IDP_folder_name} --groupidpfolder=${GroupIDPFolder} --starttime=${Start_Time} --logidpfolder=${logFolder}/${log_Name}" &`
    jobID1=`echo -e $jobID1 | awk '{ print $NF }'`
    echo "jobID_1: ${jobID1}"

else

    ${BRC_IDPEXTRACT_SCR}/idp_extract_part_1.sh \
                          --inputlist=${InputList} \
                          --listfolder=${ListFolder} \
                          --subjectlist_name=${SubjectList_name} \
                          --inputdir=${InputDIR} \
                          --analysisfoldername=${AnalysisFolderName} \
                          --idp_folder_name=${IDP_folder_name} \
                          --groupidpfolder=${GroupIDPFolder} \
                          --starttime=${Start_Time} \
                          --logidpfolder=${logFolder}/${log_Name}


fi
