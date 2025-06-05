#!/bin/bash
# Last update: 02/10/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
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
T1Folder=`getopt1 "--t1folder" $@`
T2Folder=`getopt1 "--t2folder" $@`
rawT1Folder=`getopt1 "--rawt1folder" $@`
FastT1Folder=`getopt1 "--fastfolder" $@`
FirstT1Folder=`getopt1 "--firstfolder" $@`
regTempT1Folder=`getopt1 "--regtempt1folder" $@`
biasT1Folder=`getopt1 "--biast1folder" $@`
do_Sub_seg=`getopt1 "--dosubseg" $@`
dataT1folder=`getopt1 "--datat1folder" $@`
data2stdT1Folder=`getopt1 "--data2stdt1folder" $@`
segT1Folder=`getopt1 "--segt1folder" $@`
regT1Folder=`getopt1 "--regt1folder" $@`
TempT1Folder=`getopt1 "--tempt1folder" $@`
T2_exist=`getopt1 "--t2exist" $@`
TempT2Folder=`getopt1 "--tempt2folder" $@`
rawT2Folder=`getopt1 "--rawt2folder" $@`
do_tissue_seg=`getopt1 "--dotissueseg" $@`
dataT2Folder=`getopt1 "--datat2folder" $@`
data2stdT2Folder=`getopt1 "--data2stdt2folder" $@`
regT2Folder=`getopt1 "--regt2folder" $@`
regTempT2Folder=`getopt1 "--regtempt2folder" $@`
do_defacing=`getopt1 "--dodefacing" $@`
RegType=`getopt1 "--regtype" $@`
SienaxT1Folder=`getopt1 "--sienaxt1folder" $@`
SienaxTempFolder=`getopt1 "--sienaxtempfolder" $@`
BiancaT2Folder=`getopt1 "--biancat2folder" $@`
BiancaTempFolder=`getopt1 "--biancatempfolder" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                  START: Organizing data structure                      +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "T1Folder=$T1Folder"
log_Msg 2 "T2Folder=$T2Folder"
log_Msg 2 "rawT1Folder=$rawT1Folder"
log_Msg 2 "FastT1Folder=$FastT1Folder"
log_Msg 2 "FirstT1Folder=$FirstT1Folder"
log_Msg 2 "regTempT1Folder=$regTempT1Folder"
log_Msg 2 "biasT1Folder=$biasT1Folder"
log_Msg 2 "do_Sub_seg=$do_Sub_seg"
log_Msg 2 "dataT1folder=$dataT1folder"
log_Msg 2 "data2stdT1Folder=$data2stdT1Folder"
log_Msg 2 "segT1Folder=$segT1Folder"
log_Msg 2 "regT1Folder=$regT1Folder"
log_Msg 2 "TempT1Folder=$TempT1Folder"
log_Msg 2 "T2_exist=$T2_exist"
log_Msg 2 "TempT2Folder=$TempT2Folder"
log_Msg 2 "rawT2Folder=$rawT2Folder"
log_Msg 2 "do_tissue_seg=$do_tissue_seg"
log_Msg 2 "dataT2Folder=$dataT2Folder"
log_Msg 2 "data2stdT2Folder=$data2stdT2Folder"
log_Msg 2 "regT2Folder=$regT2Folder"
log_Msg 2 "regTempT2Folder=$regTempT2Folder"
log_Msg 2 "do_defacing=$do_defacing"
log_Msg 2 "RegType=$RegType"
log_Msg 2 "SienaxT1Folder=$SienaxT1Folder"
log_Msg 2 "SienaxTempFolder=$SienaxTempFolder"
log_Msg 2 "BiancaT2Folder=$BiancaT2Folder"
log_Msg 2 "BiancaTempFolder=$BiancaTempFolder"
log_Msg 2 "LogFile=$LogFile"

#=====================================================================================
###                                Naming Conventions
#=====================================================================================

TissueFolderName="tissue"
SingChanFolderName="sing_chan"
MultChanFolderName="multi_chan"
SubFolderName="sub"
ShapeFolderName="shape"
MultiChanFolderName="MultiChan_Seg"

#=====================================================================================
###                                  Setup PATHS
#=====================================================================================

TissueFolder=${segT1Folder}/${TissueFolderName}
SinChanFolder=${TissueFolder}/${SingChanFolderName}
MultChanFolder=${TissueFolder}/${MultChanFolderName}
SubFolder=${segT1Folder}/${SubFolderName}
ShapeFolder=${SubFolder}/${ShapeFolderName}

if [ ! -d ${TissueFolder} ]; then mkdir ${TissueFolder}; fi
if [ ! -d ${SinChanFolder} ]; then mkdir ${SinChanFolder}; fi
if [ ! -d ${MultChanFolder} ]; then mkdir ${MultChanFolder}; fi
if [ ! -d ${SubFolder} ]; then mkdir ${SubFolder}; fi
if [ ! -d ${ShapeFolder} ]; then mkdir ${ShapeFolder}; fi

if [[ $T2_exist == yes ]]; then
    MultiChanFolder=${TempT1Folder}/${MultiChanFolderName}

    if [ ! -d ${FSLanatT2Folder} ]; then mkdir ${FSLanatT2Folder}; fi
    if [ ! -d ${MultiChanFolder} ]; then mkdir ${MultiChanFolder}; fi
fi

#=====================================================================================
###                                   DO WORK
#=====================================================================================

# Find related files in the fsl_anat output folder and move them to the related folders in the T1 directory

log_Msg 3 "Organizing T1 data folder"

$FSLDIR/bin/immv ${TempT1Folder}/T1  ${dataT1folder}/T1
$FSLDIR/bin/immv ${TempT1Folder}/T1_brain  ${dataT1folder}/T1_brain
$FSLDIR/bin/immv ${TempT1Folder}/T1_brain_mask  ${dataT1folder}/T1_brain_mask
$FSLDIR/bin/immv ${TempT1Folder}/T1_unbiased  ${dataT1folder}/T1_unbiased
$FSLDIR/bin/immv ${TempT1Folder}/T1_unbiased_brain  ${dataT1folder}/T1_unbiased_brain

if [ $do_defacing = "yes" ] ; then
    $FSLDIR/bin/immv ${TempT1Folder}/T1_orig_defaced  ${rawT1Folder}/T1_orig_defaced
fi

log_Msg 3 "Organizing T1 seg folder"

$FSLDIR/bin/immv ${FastT1Folder}/T1_brain_pve_0  ${SinChanFolder}/T1_pve_CSF
$FSLDIR/bin/immv ${FastT1Folder}/T1_brain_pve_1  ${SinChanFolder}/T1_pve_GM
$FSLDIR/bin/immv ${FastT1Folder}/T1_brain_pve_2  ${SinChanFolder}/T1_pve_WM
$FSLDIR/bin/immv ${FastT1Folder}/T1_brain_CSF_mask  ${SinChanFolder}/T1_CSF_mask
$FSLDIR/bin/immv ${FastT1Folder}/T1_brain_GM_mask  ${SinChanFolder}/T1_GM_mask
$FSLDIR/bin/immv ${FastT1Folder}/T1_brain_WM_mask  ${SinChanFolder}/T1_WM_mask
$FSLDIR/bin/immv ${FastT1Folder}/T1_brain_pveseg  ${SinChanFolder}/T1_pveseg
$FSLDIR/bin/immv ${FastT1Folder}/T1_brain_seg  ${SinChanFolder}/T1_seg

$FSLDIR/bin/immv ${FastT1Folder}/T1_brain_bias  ${biasT1Folder}/T1_brain_bias

#if [ $do_Sub_seg = yes ] ; then
#
#  if [ -e ${FirstT1Folder}/T1_first_all_fast_firstseg ] ; then
#    $FSLDIR/bin/immv ${FirstT1Folder}/T1_first_all_fast_firstseg  ${SubFolder}/T1_subcort_seg
#  fi
#
#  mv ${FirstT1Folder}/T1_first*  ${ShapeFolder}
#
#  if [ -e ${FirstT1Folder}/T1_unbiased_brain_to_std_sub.mat ] ; then
#      mv ${FirstT1Folder}/T1_unbiased_brain_to_std_sub.mat  ${regT1Folder}/T1_2_std_sub.mat
#  fi
#
#  if [ -e ${FirstT1Folder}/T1_unbiased_brain_to_std_sub ] ; then
#      $FSLDIR/bin/immv ${FirstT1Folder}/T1_unbiased_brain_to_std_sub  ${data2stdT1Folder}/T1_2_std_sub
#  fi
#fi

log_Msg 3 "Organizing T1 linear registration folder"

$FSLDIR/bin/immv ${regTempT1Folder}/T1_to_MNI_linear  ${data2stdT1Folder}/T1_2_std
$FSLDIR/bin/immv ${regTempT1Folder}/T1_brain_to_MNI_linear  ${data2stdT1Folder}/T1_2_std_brain_lin
mv ${regTempT1Folder}/T1_to_MNI_linear.mat  ${regT1Folder}/T1_2_std.mat
$FSLDIR/bin/convert_xfm -inverse ${regT1Folder}/T1_2_std.mat -omat ${regT1Folder}/std_2_T1.mat

if [ $RegType == 2 ] || [ $RegType == 3 ]; then

    log_Msg 3 "Organizing T1 non-linear registration folder"

    $FSLDIR/bin/immv ${regTempT1Folder}/T1_to_MNI_nonlin  ${data2stdT1Folder}/T1_2_std_warped
    $FSLDIR/bin/immv ${regTempT1Folder}/T1_brain_to_MNI_nonlin  ${data2stdT1Folder}/T1_2_std_brain_warped

    if [ $RegType == 2 ]; then
        $FSLDIR/bin/immv ${regTempT1Folder}/T1_to_MNI_nonlin_coeff  ${regT1Folder}/T1_2_std_warp_coeff
        $FSLDIR/bin/immv ${regTempT1Folder}/T1_to_MNI_nonlin_jac  ${regT1Folder}/T1_2_std_warp_jac
#    elif [ $RegType == 3 ]; then
#        $FSLDIR/bin/immv ${regTempT1Folder}/T1_to_MNI_nonlin_warp_fsl  ${regT1Folder}/T1_2_std_warp_field
    fi

    $FSLDIR/bin/imcp ${regTempT1Folder}/T1_to_MNI_nonlin_field  ${regT1Folder}/T1_2_std_warp_field
    $FSLDIR/bin/immv ${regTempT1Folder}/T1_to_MNI_nonlin_coeff_inv  ${regT1Folder}/std_2_T1_warp_field

    mv ${SienaxTempFolder}/*  ${SienaxT1Folder}/
    ${FSLDIR}/bin/imrm ${SienaxT1Folder}/T1_brain*
    ${FSLDIR}/bin/imrm ${SienaxT1Folder}/T1_pve*
    ${FSLDIR}/bin/imrm ${SienaxT1Folder}/T1_seg*
    rm ${SienaxT1Folder}/T1_to*
fi

if [[ $T2_exist == yes ]]; then

    log_Msg 3 "Organizing T2 data folder"

    $FSLDIR/bin/immv ${TempT2Folder}/T2  ${dataT2Folder}/T2
    $FSLDIR/bin/immv ${TempT2Folder}/T2_brain  ${dataT2Folder}/T2_brain
    $FSLDIR/bin/immv ${TempT2Folder}/T2_brain_mask  ${dataT2Folder}/T2_brain_mask
    $FSLDIR/bin/immv ${TempT2Folder}/T2_unbiased  ${dataT2Folder}/T2_unbiased
    $FSLDIR/bin/immv ${TempT2Folder}/T2_unbiased_brain  ${dataT2Folder}/T2_unbiased_brain

    if [ $do_defacing = "yes" ] ; then
        $FSLDIR/bin/immv ${TempT2Folder}/T2_orig_defaced  ${rawT2Folder}/T2_orig_defaced
    fi

    log_Msg 3  `date`
    log_Msg 3 "Organizing T2 linear registration folder"

    $FSLDIR/bin/immv ${regTempT2Folder}/T2_to_MNI_linear  ${data2stdT2Folder}/T2_2_std
    $FSLDIR/bin/immv ${regTempT2Folder}/T2_brain_to_MNI_linear  ${data2stdT2Folder}/T2_2_std_brain_lin

    if [ $RegType == 1 ]; then
        mv ${regTempT2Folder}/T2_to_MNI_linear.mat  ${regT2Folder}/T2_2_std.mat
    elif [ $RegType == 2 ] || [ $RegType == 3 ]; then
        mv ${regTempT2Folder}/T2_orig_ud_to_MNI_linear.mat  ${regT2Folder}/T2_2_std.mat
    fi
    $FSLDIR/bin/convert_xfm -inverse ${regT2Folder}/T2_2_std.mat -omat ${regT2Folder}/std_2_T2.mat

    if [ $RegType == 2 ] || [ $RegType == 3 ]; then

        log_Msg 3  `date`
        log_Msg 3 "Organizing T2 non-linear registration folder"

        $FSLDIR/bin/immv ${regTempT2Folder}/T2_to_MNI  ${data2stdT2Folder}/T2_2_std_warped
        $FSLDIR/bin/immv ${regTempT2Folder}/T2_brain_to_MNI  ${data2stdT2Folder}/T2_2_std_brain_warped

#        if [ $RegType == 2 ]; then
#            $FSLDIR/bin/immv ${regTempT2Folder}/T2_orig_to_MNI_warp  ${regT2Folder}/T2_2_std_warp_field
#        elif [ $RegType == 3 ]; then
        $FSLDIR/bin/imcp ${regT1Folder}/T1_2_std_warp_field  ${regT2Folder}/T2_2_std_warp_field
#        fi

    fi

    if [ $do_tissue_seg = "yes" ] ; then
        log_Msg 3  `date`
        log_Msg 3 "Multichanel tissue segmentation of T1 using T2"

        $FSLDIR/bin/fast -o ${MultiChanFolder}/FAST -g -N -S 2 ${dataT1folder}/T1_brain  ${dataT2Folder}/T2_brain

        # Compute mean intensity for each partial volume estimate
        mean0=$($FSLDIR/bin/fslstats ${MultiChanFolder}/FAST_pve_0 -M)
        mean1=$($FSLDIR/bin/fslstats ${MultiChanFolder}/FAST_pve_1 -M)
        mean2=$($FSLDIR/bin/fslstats ${MultiChanFolder}/FAST_pve_2 -M)

        # Identify CSF, GM, WM based on expected intensity characteristics
        # CSF usually has lowest intensity, GM medium, WM highest in T1

        # Sort the means and assign labels. Create an array of means
        means=($mean0 $mean1 $mean2)

        # Find indices of sorted order
        sorted=($(printf "%s\n" "${means[@]}" | awk '{ print $1, NR-1 }' | sort -n | awk '{ print $2 }'))

        csf_idx=${sorted[0]}
        gm_idx=${sorted[1]}
        wm_idx=${sorted[2]}

        # Rename the pve files
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_pve_${csf_idx} ${MultChanFolder}/T1_pve_CSF
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_pve_${gm_idx} ${MultChanFolder}/T1_pve_GM
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_pve_${wm_idx} ${MultChanFolder}/T1_pve_WM

        # Rename the seg masks
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_seg_${csf_idx} ${MultChanFolder}/T1_CSF_mask
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_seg_${gm_idx} ${MultChanFolder}/T1_GM_mask
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_seg_${wm_idx} ${MultChanFolder}/T1_WM_mask

        # Rename the segmentation summary
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_pveseg ${MultChanFolder}/T1_pveseg
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_seg ${MultChanFolder}/T1_seg

        # $FSLDIR/bin/immv ${MultiChanFolder}/FAST_pve_0  ${MultChanFolder}/T1_pve_CSF
        # $FSLDIR/bin/immv ${MultiChanFolder}/FAST_pve_1  ${MultChanFolder}/T1_pve_WM
        # $FSLDIR/bin/immv ${MultiChanFolder}/FAST_pve_2  ${MultChanFolder}/T1_pve_GM
        # $FSLDIR/bin/immv ${MultiChanFolder}/FAST_pveseg  ${MultChanFolder}/T1_pveseg
        # $FSLDIR/bin/immv ${MultiChanFolder}/FAST_seg_0  ${MultChanFolder}/T1_CSF_mask
        # $FSLDIR/bin/immv ${MultiChanFolder}/FAST_seg_1  ${MultChanFolder}/T1_WM_mask
        # $FSLDIR/bin/immv ${MultiChanFolder}/FAST_seg_2  ${MultChanFolder}/T1_GM_mask
        # $FSLDIR/bin/immv ${MultiChanFolder}/FAST_seg  ${MultChanFolder}/T1_seg

    fi

    if [ `${FSLDIR}/bin/imtest ${BiancaTempFolder}/lesion_mask_2_T1` = 1 ] ; then
        $FSLDIR/bin/immv ${BiancaTempFolder}/lesion_mask_2_T1  ${dataT2Folder}/lesion_mask_2_T1
    fi

    mv ${BiancaTempFolder}/*  ${BiancaT2Folder}/
    ${FSLDIR}/bin/imrm ${BiancaT2Folder}/T1_*
    ${FSLDIR}/bin/imrm ${BiancaT2Folder}/bianca_*
    # ${FSLDIR}/bin/imrm ${BiancaT2Folder}/final_*
    rm ${BiancaT2Folder}/conf_*

fi

log_Msg 3 ""
log_Msg 3 "                    END: Organizing data structure  "
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "


################################################################################################
## Cleanup
################################################################################################

${FSLDIR}/bin/imrm ${regT2Folder}/T2_2_T1_init*
${FSLDIR}/bin/imrm ${regTempT1Folder}/T1_tmp*
${FSLDIR}/bin/imrm ${TempT1Folder}/T1_tmp*
