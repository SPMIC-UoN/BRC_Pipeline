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

if [ $do_Sub_seg = yes ] ; then

  if [ -e ${FirstT1Folder}/T1_first_all_fast_firstseg ] ; then
    $FSLDIR/bin/immv ${FirstT1Folder}/T1_first_all_fast_firstseg  ${SubFolder}/T1_subcort_seg
  fi

#  mv ${TempT1Folder}/T1_vols.txt  ${SubFolder}/T1_vols.txt

  mv ${FirstT1Folder}/T1_first*  ${ShapeFolder}
#  if [ -e ${FirstT1Folder}/T1_first-BrStem_first.bvars ] ; then
#      mv ${FirstT1Folder}/T1_first-BrStem_first.bvars  ${ShapeFolder}/T1_BrStem.bvars
#      mv ${FirstT1Folder}/T1_first-BrStem_first.vtk  ${ShapeFolder}/T1_BrStem.vtk
#  fi
#  mv ${FirstT1Folder}/T1_first-L_Accu_first.bvars  ${ShapeFolder}/T1_L_Accu.bvars
#  mv ${FirstT1Folder}/T1_first-R_Accu_first.bvars  ${ShapeFolder}/T1_R_Accu.bvars
#  mv ${FirstT1Folder}/T1_first-L_Accu_first.vtk  ${ShapeFolder}/T1_L_Accu.vtk
#  mv ${FirstT1Folder}/T1_first-R_Accu_first.vtk  ${ShapeFolder}/T1_R_Accu.vtk
#  mv ${FirstT1Folder}/T1_first-L_Amyg_first.bvars  ${ShapeFolder}/T1_L_Amyg.bvars
#  mv ${FirstT1Folder}/T1_first-R_Amyg_first.bvars  ${ShapeFolder}/T1_R_Amyg.bvars
#  mv ${FirstT1Folder}/T1_first-L_Amyg_first.vtk  ${ShapeFolder}/T1_L_Amyg.vtk
#  mv ${FirstT1Folder}/T1_first-R_Amyg_first.vtk  ${ShapeFolder}/T1_R_Amyg.vtk
#  mv ${FirstT1Folder}/T1_first-L_Caud_first.bvars  ${ShapeFolder}/T1_L_Caud.bvars
#  mv ${FirstT1Folder}/T1_first-R_Caud_first.bvars  ${ShapeFolder}/T1_R_Caud.bvars
#  mv ${FirstT1Folder}/T1_first-L_Caud_first.vtk  ${ShapeFolder}/T1_L_Caud.vtk
#  mv ${FirstT1Folder}/T1_first-R_Caud_first.vtk  ${ShapeFolder}/T1_R_Caud.vtk
#  mv ${FirstT1Folder}/T1_first-L_Hipp_first.bvars  ${ShapeFolder}/T1_L_Hipp.bvars
#  mv ${FirstT1Folder}/T1_first-R_Hipp_first.bvars  ${ShapeFolder}/T1_R_Hipp.bvars
#  mv ${FirstT1Folder}/T1_first-L_Hipp_first.vtk  ${ShapeFolder}/T1_L_Hipp.vtk
#  mv ${FirstT1Folder}/T1_first-R_Hipp_first.vtk  ${ShapeFolder}/T1_R_Hipp.vtk
#  mv ${FirstT1Folder}/T1_first-L_Pall_first.bvars  ${ShapeFolder}/T1_L_Pall.bvars
#  mv ${FirstT1Folder}/T1_first-R_Pall_first.bvars  ${ShapeFolder}/T1_R_Pall.bvars
#  mv ${FirstT1Folder}/T1_first-L_Pall_first.vtk  ${ShapeFolder}/T1_L_Pall.vtk
#  mv ${FirstT1Folder}/T1_first-R_Pall_first.vtk  ${ShapeFolder}/T1_R_Pall.vtk
#  mv ${FirstT1Folder}/T1_first-R_Puta_first.bvars  ${ShapeFolder}/T1_R_Puta.bvars
#  mv ${FirstT1Folder}/T1_first-L_Puta_first.bvars  ${ShapeFolder}/T1_L_Puta.bvars
#  mv ${FirstT1Folder}/T1_first-R_Puta_first.vtk  ${ShapeFolder}/T1_R_Puta.vtk
#  mv ${FirstT1Folder}/T1_first-L_Puta_first.vtk  ${ShapeFolder}/T1_L_Puta.vtk
#  mv ${FirstT1Folder}/T1_first-R_Thal_first.bvars  ${ShapeFolder}/T1_R_Thal.bvars
#  mv ${FirstT1Folder}/T1_first-L_Thal_first.bvars  ${ShapeFolder}/T1_L_Thal.bvars
#  mv ${FirstT1Folder}/T1_first-R_Thal_first.vtk  ${ShapeFolder}/T1_R_Thal.vtk
#  mv ${FirstT1Folder}/T1_first-L_Thal_first.vtk  ${ShapeFolder}/T1_L_Thal.vtk

  if [ -e ${FirstT1Folder}/T1_unbiased_brain_to_std_sub.mat ] ; then
      mv ${FirstT1Folder}/T1_unbiased_brain_to_std_sub.mat  ${regT1Folder}/T1_2_std_sub.mat
  fi

  if [ -e ${FirstT1Folder}/T1_unbiased_brain_to_std_sub ] ; then
      $FSLDIR/bin/immv ${FirstT1Folder}/T1_unbiased_brain_to_std_sub  ${data2stdT1Folder}/T1_2_std_sub
  fi
fi

log_Msg 3 "Organizing T1 linear registration folder"

$FSLDIR/bin/immv ${regTempT1Folder}/T1_to_MNI_linear  ${data2stdT1Folder}/T1_2_std
mv ${regTempT1Folder}/T1_to_MNI_linear.mat  ${regT1Folder}/T1_2_std.mat
$FSLDIR/bin/convert_xfm -inverse ${regT1Folder}/T1_2_std.mat -omat ${regT1Folder}/std_2_T1.mat

log_Msg 3 "Organizing T1 non-linear registration folder"

$FSLDIR/bin/immv ${regTempT1Folder}/T1_to_MNI_nonlin  ${data2stdT1Folder}/T1_2_std_warp
$FSLDIR/bin/immv ${regTempT1Folder}/T1_to_MNI_nonlin_coeff  ${regT1Folder}/T1_2_std_warp_coeff
$FSLDIR/bin/immv ${regTempT1Folder}/T1_to_MNI_nonlin_field  ${regT1Folder}/T1_2_std_warp_field
$FSLDIR/bin/immv ${regTempT1Folder}/T1_to_MNI_nonlin_jac  ${regT1Folder}/T1_2_std_warp_jac
$FSLDIR/bin/immv ${regTempT1Folder}/T1_to_MNI_nonlin_coeff_inv  ${regT1Folder}/std_2_T1_warp_field


if [[ $T2_exist == yes ]]; then

    log_Msg 3 "Organizing T2 data folder"

    $FSLDIR/bin/immv ${TempT2Folder}/T2  ${dataT2Folder}/T2
    $FSLDIR/bin/immv ${TempT2Folder}/T2_brain  ${dataT2Folder}/T2_brain
    $FSLDIR/bin/immv ${TempT2Folder}/T2_brain_mask  ${dataT2Folder}/T2_brain_mask
    $FSLDIR/bin/immv ${TempT2Folder}/T2_unbiased  ${dataT2Folder}/T2_unbiased
    $FSLDIR/bin/immv ${TempT2Folder}/T2_unbiased_brain  ${dataT2Folder}/T2_unbiased_brain

    $FSLDIR/bin/immv ${TempT2Folder}/T2_orig_defaced  ${rawT2Folder}/T2_orig_defaced

    log_Msg 3  `date`
    log_Msg 3 "Organizing T2 linear registration folder"

    $FSLDIR/bin/immv ${regTempT2Folder}/T2_to_MNI_linear  ${data2stdT2Folder}/T2_2_std
    mv ${regTempT2Folder}/T2_to_MNI_linear.mat  ${regT2Folder}/T2_2_std.mat
    $FSLDIR/bin/convert_xfm -inverse ${regT2Folder}/T2_2_std.mat -omat ${regT2Folder}/std_2_T2.mat

    log_Msg 3  `date`
    log_Msg 3 "Organizing T2 non-linear registration folder"

    $FSLDIR/bin/immv ${regTempT2Folder}/T2_brain_to_MNI  ${data2stdT2Folder}/T2_2_std_warp

    if [ $do_tissue_seg = "yes" ] ; then
        log_Msg 3  `date`
        log_Msg 3 "Multichanel tissue segmentation of T1 using T2"

        $FSLDIR/bin/fast -o ${MultiChanFolder}/FAST -g -N -S 2 ${dataT1folder}/T1_brain  ${dataT2Folder}/T2_brain

        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_pve_0  ${MultChanFolder}/T1_pve_CSF
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_pve_1  ${MultChanFolder}/T1_pve_WM
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_pve_2  ${MultChanFolder}/T1_pve_GM
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_pveseg  ${MultChanFolder}/T1_pveseg
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_seg_0  ${MultChanFolder}/T1_CSF_mask
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_seg_1  ${MultChanFolder}/T1_WM_mask
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_seg_2  ${MultChanFolder}/T1_GM_mask
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_seg  ${MultChanFolder}/T1_seg

#        log_Msg 3  `date`
#        log_Msg 3 "Main registration: between corrected T2w and corrected T1w"
#
#        ${FSLDIR}/bin/epi_reg --epi=${dataT2Folder}/T2_brain --t1=${dataT1folder}/T1 --t1brain=${dataT1folder}/T1_brain --out=${regT2Folder}/T2_2_T1_init --wmseg=${MultChanFolder}/T1_pve_thr_WM
#        ${FSLDIR}/bin/flirt -in ${dataT2Folder}/T2_brain -ref ${dataT1folder}/T1_brain -init ${regT2Folder}/T2_2_T1_init.mat -out ${regT2Folder}/T2_2_T1 -omat ${regT2Folder}/T2_2_T1.mat -dof 6
    fi

#    log_Msg 3  `date`
#    log_Msg 3 "Organizing T2 non-linear registration folder"
#
#    ${FSLDIR}/bin/applywarp --rel --in=${dataT2Folder}/T2 --ref=$FSLDIR/data/standard/MNI152_T1_1mm --premat=${regT2Folder}/T2_2_T1.mat --warp=${regT1Folder}/T1_2_std_warp_coeff --out=${data2stdT2Folder}/T2_to_std_warp --interp=spline
#
##    ${FSLDIR}/bin/invwarp --ref=${dataT1folder}/T1 -w ${regT1Folder}/T1_2_std_warp_coeff -o ${regT1Folder}/std_2_T1_warp
#
#    ${FSLDIR}/bin/convert_xfm -inverse ${regT2Folder}/T2_2_T1.mat -omat ${regT2Folder}/T1_2_T2.mat
#
#    ${FSLDIR}/bin/applywarp --rel --in=$FSLDIR/data/standard/MNI152_T1_1mm_brain_mask --ref=${dataT2Folder}/T2 --warp=${regT1Folder}/std_2_T1_warp_field --postmat=${regT2Folder}/T1_2_T2.mat --out=${dataT2Folder}/T2_brain_mask --interp=spline
#
#    ${FSLDIR}/bin/fslmaths ${dataT2Folder}/T2 -mul ${dataT2Folder}/T2_brain_mask ${dataT2Folder}/T2_brain
#
##    cp -r $T2datadir/* ${FSLanatT2Folder}/
##    rm -rf $T2datadir
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
