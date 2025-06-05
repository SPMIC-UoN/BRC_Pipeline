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
BiancaTempFolder=`getopt1 "--biancatempfolder" $@`
regTempT1Folder=`getopt1 "--regtempt1folder" $@`
T2=`getopt1 "--t2" $@`
TempT2Folder=`getopt1 "--tempt2folder" $@`
rawT2Folder=`getopt1 "--rawt2folder" $@`
regTempT2Folder=`getopt1 "--regtempt2folder" $@`
SienaxTempFolder=`getopt1 "--sienaxtempfolder" $@`
T2LesionPath=`getopt1 "--t2lesionpath" $@`
fBET=`getopt1 "--fbet" $@`
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
      --sienaxtempfolder=${SienaxTempFolder} \
      --regtempt1folder=${regTempT1Folder} \
      --regtype=${RegType} \
      --fbet=${fBET} \
      --logfile=${logT1Folder}


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
            --biancatempfolder=${BiancaTempFolder} \
            --t2lesionpath=${T2LesionPath} \
            --logfile=${logT1Folder}

fi

#: <<'COMMENT'
