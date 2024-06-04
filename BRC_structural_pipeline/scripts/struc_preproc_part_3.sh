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
BiancaT2Folder=`getopt1 "--biancat2folder" $@` 
T1Folder=`getopt1 "--t1folder" $@`
T2Folder=`getopt1 "--t2folder" $@`
biasT1Folder=`getopt1 "--biast1folder" $@`
dataT1Folder=`getopt1 "--datat1folder" $@`
data2stdT1Folder=`getopt1 "--data2stdt1folder" $@`
segT1Folder=`getopt1 "--segt1folder" $@`
dataT2Folder=`getopt1 "--datat2folder" $@`
regT1Folder=`getopt1 "--regt1folder" $@`
data2stdT2Folder=`getopt1 "--data2stdt2folder" $@`
regT2Folder=`getopt1 "--regt2folder" $@`
do_fastsurfer=`getopt1 "--dofastsurfer" $@`
FastSurferFolderName=`getopt1 "--fastsurferfoldername" $@`
Start_Time=`getopt1 "--starttime" $@`
Sub_ID=`getopt1 "--subid" $@`
processedT1Folder=`getopt1 "--processedt1folder" $@`
T2=`getopt1 "--t2" $@`
regTempT2Folder=`getopt1 "--regtempt2folder" $@`
rawT1Folder=`getopt1 "--rawt1folder" $@`
FastT1Folder=`getopt1 "--fastt1folder" $@`
FirstT1Folder=`getopt1 "--firstt1folder" $@`
SienaxT1Folder=`getopt1 "--sienaxt1folder" $@`
BiancaTempFolder=`getopt1 "--biancatempfolder" $@`
regTempT1Folder=`getopt1 "--regtempt1folder" $@`
do_Sub_seg=`getopt1 "--dosubseg" $@`
TempT1Folder=`getopt1 "--tempt1folder" $@`
TempT2Folder=`getopt1 "--tempt2folder" $@`
rawT2Folder=`getopt1 "--rawt2folder" $@`
do_tissue_seg=`getopt1 "--dotissueseg" $@`
do_defacing=`getopt1 "--dodefacing" $@`
RegType=`getopt1 "--regtype" $@`
SienaxTempFolder=`getopt1 "--sienaxtempfolder" $@`
logT1Folder=`getopt1 "--logt1folder" $@`

log_SetPath "${logT1Folder}"

#=====================================================================================
###                                   DO WORK
#=====================================================================================

if [[ $do_fastsurfer == "yes" ]]; then
    SUBJECTS_DIR=${processedT1Folder}

    log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    log_Msg 3 "+                                                                        +"
    log_Msg 3 "+                       START: FastSurfer Analysis                       +"
    log_Msg 3 "+                                                                        +"
    log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

    if [ -e "${processedT1Folder}/${FastSurferFolderName}" ] ; then
        rm -r ${processedT1Folder}/${FastSurferFolderName}
    fi

    if [[ $T2 == yes ]]; then
        log_Msg 3 "WARNING: T2 specified but will be ignored by FastSurfer"
    fi

    if [ ${CLUSTER_MODE} = "YES" ] ; then
        module load brcpython-img
    else
        module load brcpython
    fi

    run_fastsurfer.sh --t1 ${rawT1Folder}/T1_orig.nii.gz --sid ${FastSurferFolderName} --sd ${processedT1Folder}

    # rm -r ${processedT1Folder}/fsaverage
fi

${BRC_SCTRUC_SCR}/output_organization.sh \
      --t1folder=${T1Folder} \
      --t2folder=${T2Folder} \
      --rawt1folder=${rawT1Folder} \
      --fastfolder=${FastT1Folder} \
      --firstfolder=${FirstT1Folder} \
      --regtempt1folder=${regTempT1Folder} \
      --biast1folder=${biasT1Folder} \
      --dosubseg=${do_Sub_seg} \
      --datat1folder=${dataT1Folder} \
      --data2stdt1folder=${data2stdT1Folder} \
      --segt1folder=${segT1Folder} \
      --regt1folder=${regT1Folder} \
      --tempt1folder=${TempT1Folder} \
      --t2exist=${T2} \
      --tempt2folder=${TempT2Folder} \
      --rawt2folder=${rawT2Folder} \
      --dotissueseg=${do_tissue_seg} \
      --datat2folder=${dataT2Folder} \
      --data2stdt2folder=${data2stdT2Folder} \
      --regt2folder=${regT2Folder} \
      --regtempt2folder=${regTempT2Folder} \
      --dodefacing=${do_defacing} \
      --regtype=${RegType} \
      --sienaxt1folder=${SienaxT1Folder} \
      --sienaxtempfolder=${SienaxTempFolder} \
      --biancat2folder=${BiancaT2Folder} \
      --biancatempfolder=${BiancaTempFolder} \
      --logfile=${logT1Folder}

END_Time="$(date -u +%s)"

${RUN} ${BRCDIR}/Show_version.sh \
      --showdiff="yes" \
      --start=${Start_Time} \
      --end=${END_Time} \
      --subject=${Sub_ID} \
      --type=1 \
      --logfile=${logT1Folder}
