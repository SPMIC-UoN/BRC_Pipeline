#!/bin/bash
# Last update: 03/05/2018

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
do_freesurfer=`getopt1 "--dofreesurfer" $@` 
processedT1Folder=`getopt1 "--processedt1folder" $@`
FSFolderName=`getopt1 "--fsfoldername" $@`
T2=`getopt1 "--t2" $@`
rawT1Folder=`getopt1 "--rawt1folder" $@`
rawT2Folder=`getopt1 "--rawt2folder" $@`
logT1Folder=`getopt1 "--logt1folder" $@`

log_SetPath "${logT1Folder}"

#=====================================================================================
###                                   DO WORK
#=====================================================================================

if [[ $do_freesurfer == "yes" ]]; then
    SUBJECTS_DIR=${processedT1Folder}

    log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    log_Msg 3 "+                                                                        +"
    log_Msg 3 "+                       START: FreeSurfer Analysis                       +"
    log_Msg 3 "+                                                                        +"
    log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

    if [ -e "${processedT1Folder}/${FSFolderName}" ] ; then
        rm -r ${processedT1Folder}/${FSFolderName}
    fi

    if [[ $T2 == yes ]]; then
        recon-all -i ${rawT1Folder}/T1_orig.nii.gz -s ${FSFolderName} -FLAIR ${rawT2Folder}/T2_orig.nii.gz -all
    else
        recon-all -i ${rawT1Folder}/T1_orig.nii.gz -s ${FSFolderName} -all
    fi

    rm -r ${processedT1Folder}/fsaverage
fi
