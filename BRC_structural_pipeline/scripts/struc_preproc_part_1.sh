#!/bin/bash
# Last update: 09/10/2018
#Example:
#./struc_preproc.sh --path ~/main/analysis -s Sub_002 -i ~/P_Share/Images/3T_Harmonisation_Stam/03286_20180307_Ingenia/NIFTI/1_MPRAGE/__T1_1mm_sag_20180307162159_201.nii.gz -t2 ~/P_Share/Images/3T_Harmonisation_Stam/03286_20180307_Ingenia/NIFTI/2_3D_T2w_FLAIR/__T2_FLAIR_1mm_20180307162159_301.nii.gz --subseg

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
TempT1Folder=`getopt1 "--tempt1folder" $@`
rawT1Folder=`getopt1 "--rawt1folder" $@`
do_Sub_seg=`getopt1 "--dosubseg" $@`
do_tissue_seg=`getopt1 "--dotissueseg" $@`
do_crop=`getopt1 "--docrop" $@`
do_defacing=`getopt1 "--dodefacing" $@`
FastT1Folder=`getopt1 "--fastt1folder" $@`
FirstT1Folder=`getopt1 "--firstt1folder" $@`
SienaxT1Folder=`getopt1 "--sienaxt1folder" $@`
BiancaT2Folder=`getopt1 "--biancat2folder" $@`
regTempT1Folder=`getopt1 "--regtempt1folder" $@`
T2=`getopt1 "--t2" $@`
TempT2Folder=`getopt1 "--tempt2folder" $@`
rawT2Folder=`getopt1 "--rawt2folder" $@`
regTempT2Folder=`getopt1 "--regtempt2folder" $@`
T1Folder=`getopt1 "--t1folder" $@`
T2Folder=`getopt1 "--t2folder" $@`
biasT1Folder=`getopt1 "--biast1folder" $@`
dataT1Folder=`getopt1 "--datat1folder" $@`
data2stdT1Folder=`getopt1 "--data2stdt1folder" $@`
segT1Folder=`getopt1 "--segt1folder" $@`
regT1Folder=`getopt1 "--regt1folder" $@`
dataT2Folder=`getopt1 "--datat2folder" $@`
data2stdT2Folder=`getopt1 "--data2stdt2folder" $@`
regT2Folder=`getopt1 "--regt2folder" $@`
regT2Folder=`getopt1 "--regt2folder" $@`
do_freesurfer=`getopt1 "--dofreesurfer" $@`
processedT1Folder=`getopt1 "--processedt1folder" $@`
FSFolderName=`getopt1 "--fsfoldername" $@`
Start_Time=`getopt1 "--starttime" $@`
Sub_ID=`getopt1 "--subid" $@`
RegType=`getopt1 "--regtype" $@`
logT1Folder=`getopt1 "--logt1folder" $@`

log_SetPath "${logT1Folder}"

#=====================================================================================
###                                   DO WORK
#=====================================================================================

${BRC_SCTRUC_SCR}/run_T1_preprocessing.sh \
      --workingdir=${TempT1Folder} \
      --t1input=${rawT1Folder}/T1_orig.nii.gz \
      --dosubseg=${do_Sub_seg} \
      --dotissueseg=${do_tissue_seg} \
      --docrop=${do_crop} \
      --dodefacing=${do_defacing} \
      --fastfolder=${FastT1Folder} \
      --firstfolder=${FirstT1Folder} \
      --sienaxt1folder=${SienaxT1Folder} \
      --regtempt1folder=${regTempT1Folder} \
      --regtype=${RegType} \
      --logfile=${logT1Folder}

#: <<'COMMENT'
if [[ $T2 == "yes" ]]; then

      ${BRC_SCTRUC_SCR}/run_T2_preprocessing.sh \
            --workingdir=${TempT2Folder} \
            --t2input=${rawT2Folder}/T2_orig.nii.gz \
            --tempt1folder=${TempT1Folder} \
            --fastfolder=${FastT1Folder} \
            --regtempt1folder=${regTempT1Folder} \
            --regtempt2folder=${regTempT2Folder} \
            --dodefacing=${do_defacing} \
            --regtype=${RegType} \
            --docrop=${do_crop} \
            --biancat2folder=${BiancaT2Folder} \
            --logfile=${logT1Folder}

fi

#: <<'COMMENT'
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
      --logfile=${logT1Folder}

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
        recon-all -i ${rawT1Folder}/T1_orig.nii.gz -s FS -FLAIR ${rawT2Folder}/T2_orig.nii.gz -all
    else
        recon-all -i ${rawT1Folder}/T1_orig.nii.gz -s FS -all
    fi

    rm -r ${processedT1Folder}/fsaverage
fi


END_Time="$(date -u +%s)"


${RUN} ${BRCDIR}/Show_version.sh \
      --showdiff="yes" \
      --start=${Start_Time} \
      --end=${END_Time} \
      --subject=${Sub_ID} \
      --type=1 \
      --logfile=${logT1Folder}

#: <<'COMMENT'
