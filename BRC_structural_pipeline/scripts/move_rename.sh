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
T2_exist=`getopt1 "--t2exist" $@`
do_Sub_seg=`getopt1 "--dosubseg" $@`
do_tissue_seg=`getopt1 "--dotissueseg" $@`
anatFolder=`getopt1 "--anatname" $@`
dataT1folder=`getopt1 "--datat1folder" $@`
segT1Folder=`getopt1 "--segt1folder" $@`
do_Sub_seg=`getopt1 "--dosubseg" $@`
regT1Folder=`getopt1 "--regt1folder" $@`
TempT1Folder=`getopt1 "--tempt1folder" $@`
dataT2Folder=`getopt1 "--datat2folder" $@`
regT2Folder=`getopt1 "--regt2folder" $@`
TempT2Folder=`getopt1 "--tempt2folder" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                  START: Organizing data structure                      +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "T1Folder=$T1Folder"
log_Msg 2 "T2Folder=$T2Folder"
log_Msg 2 "T2_exist=$T2_exist"
log_Msg 2 "do_Sub_seg=$do_Sub_seg"
log_Msg 2 "do_tissue_seg=$do_tissue_seg"
log_Msg 2 "anatFolder=$anatFolder"
log_Msg 2 "dataT1folder=$dataT1folder"
log_Msg 2 "segT1Folder=$segT1Folder"
log_Msg 2 "do_Sub_seg=$do_Sub_seg"
log_Msg 2 "regT1Folder=$regT1Folder"
log_Msg 2 "TempT1Folder=$TempT1Folder"
log_Msg 2 "dataT2Folder=$dataT2Folder"
log_Msg 2 "regT2Folder=$regT2Folder"
log_Msg 2 "TempT2Folder=$TempT2Folder"
log_Msg 2 "LogFile=$LogFile"

#=====================================================================================
###                                Naming Conventions
#=====================================================================================

TissueFolderName="tissue"
SingChanFolderName="sing_chan"
MultChanFolderName="multi_chan"
SubFolderName="sub"
ShapeFolderName="shape"
LinFolderName="lin"
NonLinFolderName="nonlin"
fslanatFolderName="fsl_anat"
MultiChanFolderName="MultiChan_Seg"

#=====================================================================================
###                                  Setup PATHS
#=====================================================================================

TissueFolder=${segT1Folder}/${TissueFolderName}
SinChanFolder=${TissueFolder}/${SingChanFolderName}
MultChanFolder=${TissueFolder}/${MultChanFolderName}
SubFolder=${segT1Folder}/${SubFolderName}
ShapeFolder=${SubFolder}/${ShapeFolderName}
LinRegFolder=${regT1Folder}/${LinFolderName}
NonLinRegFolder=${regT1Folder}/${NonLinFolderName}
FSLanatFolder=${TempT1Folder}/${fslanatFolderName}

if [ ! -d ${TissueFolder} ]; then mkdir ${TissueFolder}; fi
if [ ! -d ${SinChanFolder} ]; then mkdir ${SinChanFolder}; fi
if [ ! -d ${MultChanFolder} ]; then mkdir ${MultChanFolder}; fi
if [ ! -d ${SubFolder} ]; then mkdir ${SubFolder}; fi
if [ ! -d ${ShapeFolder} ]; then mkdir ${ShapeFolder}; fi
if [ ! -d ${LinRegFolder} ]; then mkdir ${LinRegFolder}; fi
if [ ! -d ${NonLinRegFolder} ]; then mkdir ${NonLinRegFolder}; fi
if [ ! -d ${FSLanatFolder} ]; then mkdir ${FSLanatFolder}; fi

if [[ $T2_exist == yes ]]; then
    LinRegT2Folder=${regT2Folder}/${LinFolderName}
    NonLinRegT2Folder=${regT2Folder}/${NonLinFolderName}
    FSLanatT2Folder=${TempT2Folder}/${fslanatFolderName}
    MultiChanFolder=${TempT1Folder}/${MultiChanFolderName}

    if [ ! -d ${LinRegT2Folder} ]; then mkdir ${LinRegT2Folder}; fi
    if [ ! -d ${NonLinRegT2Folder} ]; then mkdir ${NonLinRegT2Folder}; fi
    if [ ! -d ${FSLanatT2Folder} ]; then mkdir ${FSLanatT2Folder}; fi
    if [ ! -d ${MultiChanFolder} ]; then mkdir ${MultiChanFolder}; fi
fi

#=====================================================================================
###                                   DO WORK
#=====================================================================================

datadir=${T1Folder}/${anatFolder}

# Find related files in the fsl_anat output folder and move them to the related folders in the T1 directory

log_Msg 3 "Organizing T1 data folder"

$FSLDIR/bin/immv $datadir/T1_biascorr  ${dataT1folder}/T1
$FSLDIR/bin/immv $datadir/T1_biascorr_brain  ${dataT1folder}/T1_brain
$FSLDIR/bin/immv $datadir/T1_biascorr_brain_mask  ${dataT1folder}/T1_brain_mask

log_Msg 3 "Organizing T1 seg folder"

$FSLDIR/bin/immv $datadir/T1_fast_pve_0  ${SinChanFolder}/T1_pve_CSF
$FSLDIR/bin/immv $datadir/T1_fast_pve_1  ${SinChanFolder}/T1_pve_GM
$FSLDIR/bin/immv $datadir/T1_fast_pve_2  ${SinChanFolder}/T1_pve_WM
$FSLDIR/bin/fslmaths ${SinChanFolder}/T1_pve_WM -thr 0.5 -bin ${SinChanFolder}/T1_pve_thr_WM
$FSLDIR/bin/fslmaths ${SinChanFolder}/T1_pve_GM -thr 0.5 -bin ${SinChanFolder}/T1_pve_thr_GM
$FSLDIR/bin/immv $datadir/T1_fast_pveseg  ${SinChanFolder}/T1_pveseg
$FSLDIR/bin/immv $datadir/T1_fast_seg  ${SinChanFolder}/T1_seg

if [ $do_Sub_seg = yes ] ; then
  sourcdir=${datadir}/first_results

  if [ -e $sourcdir/T1_first_all_fast_firstseg ] ; then
    $FSLDIR/bin/immv $sourcdir/T1_first_all_fast_firstseg  ${SubFolder}/T1_subcort_seg
  fi

  mv $datadir/T1_vols.txt  ${SubFolder}/T1_vols.txt

  if [ -e $sourcdir/T1_first-BrStem_first.bvars ] ; then
      mv $sourcdir/T1_first-BrStem_first.bvars  ${ShapeFolder}/T1_BrStem.bvars
      mv $sourcdir/T1_first-BrStem_first.vtk  ${ShapeFolder}/T1_BrStem.vtk
  fi
  mv $sourcdir/T1_first-L_Accu_first.bvars  ${ShapeFolder}/T1_L_Accu.bvars
  mv $sourcdir/T1_first-R_Accu_first.bvars  ${ShapeFolder}/T1_R_Accu.bvars
  mv $sourcdir/T1_first-L_Accu_first.vtk  ${ShapeFolder}/T1_L_Accu.vtk
  mv $sourcdir/T1_first-R_Accu_first.vtk  ${ShapeFolder}/T1_R_Accu.vtk
  mv $sourcdir/T1_first-L_Amyg_first.bvars  ${ShapeFolder}/T1_L_Amyg.bvars
  mv $sourcdir/T1_first-R_Amyg_first.bvars  ${ShapeFolder}/T1_R_Amyg.bvars
  mv $sourcdir/T1_first-L_Amyg_first.vtk  ${ShapeFolder}/T1_L_Amyg.vtk
  mv $sourcdir/T1_first-R_Amyg_first.vtk  ${ShapeFolder}/T1_R_Amyg.vtk
  mv $sourcdir/T1_first-L_Caud_first.bvars  ${ShapeFolder}/T1_L_Caud.bvars
  mv $sourcdir/T1_first-R_Caud_first.bvars  ${ShapeFolder}/T1_R_Caud.bvars
  mv $sourcdir/T1_first-L_Caud_first.vtk  ${ShapeFolder}/T1_L_Caud.vtk
  mv $sourcdir/T1_first-R_Caud_first.vtk  ${ShapeFolder}/T1_R_Caud.vtk
  mv $sourcdir/T1_first-L_Hipp_first.bvars  ${ShapeFolder}/T1_L_Hipp.bvars
  mv $sourcdir/T1_first-R_Hipp_first.bvars  ${ShapeFolder}/T1_R_Hipp.bvars
  mv $sourcdir/T1_first-L_Hipp_first.vtk  ${ShapeFolder}/T1_L_Hipp.vtk
  mv $sourcdir/T1_first-R_Hipp_first.vtk  ${ShapeFolder}/T1_R_Hipp.vtk
  mv $sourcdir/T1_first-L_Pall_first.bvars  ${ShapeFolder}/T1_L_Pall.bvars
  mv $sourcdir/T1_first-R_Pall_first.bvars  ${ShapeFolder}/T1_R_Pall.bvars
  mv $sourcdir/T1_first-L_Pall_first.vtk  ${ShapeFolder}/T1_L_Pall.vtk
  mv $sourcdir/T1_first-R_Pall_first.vtk  ${ShapeFolder}/T1_R_Pall.vtk
  mv $sourcdir/T1_first-R_Puta_first.bvars  ${ShapeFolder}/T1_R_Puta.bvars
  mv $sourcdir/T1_first-L_Puta_first.bvars  ${ShapeFolder}/T1_L_Puta.bvars
  mv $sourcdir/T1_first-R_Puta_first.vtk  ${ShapeFolder}/T1_R_Puta.vtk
  mv $sourcdir/T1_first-L_Puta_first.vtk  ${ShapeFolder}/T1_L_Puta.vtk
  mv $sourcdir/T1_first-R_Thal_first.bvars  ${ShapeFolder}/T1_R_Thal.bvars
  mv $sourcdir/T1_first-L_Thal_first.bvars  ${ShapeFolder}/T1_L_Thal.bvars
  mv $sourcdir/T1_first-R_Thal_first.vtk  ${ShapeFolder}/T1_R_Thal.vtk
  mv $sourcdir/T1_first-L_Thal_first.vtk  ${ShapeFolder}/T1_L_Thal.vtk

  mv $datadir/T1_biascorr_to_std_sub.mat  ${LinRegFolder}/T1_2_std_sub.mat
#  $FSLDIR/bin/immv $datadir/T1_biascorr_to_std_sub  $T1Folder/reg/lin/T1_2_std_sub
fi

log_Msg 3 "Organizing T1 linear registration folder"

$FSLDIR/bin/immv $datadir/T1_to_MNI_lin  ${LinRegFolder}/T1_2_std
mv $datadir/T1_to_MNI_lin.mat  ${LinRegFolder}/T1_2_std.mat
$FSLDIR/bin/convert_xfm -inverse ${LinRegFolder}/T1_2_std.mat -omat ${LinRegFolder}/std_2_T1.mat

log_Msg 3 "Organizing T1 non-linear registration folder"

$FSLDIR/bin/immv $datadir/T1_to_MNI_nonlin  ${NonLinRegFolder}/T1_2_std_warp
$FSLDIR/bin/immv $datadir/T1_to_MNI_nonlin_coeff  ${NonLinRegFolder}/T1_2_std_warp_coeff
$FSLDIR/bin/immv $datadir/T1_to_MNI_nonlin_field  ${NonLinRegFolder}/T1_2_std_warp_field
$FSLDIR/bin/immv $datadir/T1_to_MNI_nonlin_jac  ${NonLinRegFolder}/T1_2_std_warp_jac
$FSLDIR/bin/immv $datadir/MNI_to_T1_nonlin_field  ${NonLinRegFolder}/std_2_T1_warp_field

cp -r $datadir/* ${FSLanatFolder}/
rm -rf $datadir

#: <<'COMMENT'


if [[ $T2_exist == yes ]]; then
    T2datadir=${T2Folder}/${anatFolder}

    log_Msg 3 "Organizing T2 data folder"

    $FSLDIR/bin/immv $T2datadir/T2_biascorr  ${dataT2Folder}/T2
    $FSLDIR/bin/immv $T2datadir/T2_biascorr_brain  ${dataT2Folder}/T2_brain
    $FSLDIR/bin/immv $T2datadir/T2_biascorr_brain_mask  ${dataT2Folder}/T2_brain_mask

    log_Msg 3  `date`
    log_Msg 3 "Organizing T2 linear registration folder"

    ${FSLDIR}/bin/epi_reg --epi=${dataT2Folder}/T2_brain --t1=${dataT1folder}/T1 --t1brain=${dataT1folder}/T1_brain --out=${LinRegT2Folder}/T2_2_T1_init --wmseg=${SinChanFolder}/T1_pve_thr_WM
    ${FSLDIR}/bin/flirt -in ${dataT2Folder}/T2_brain -ref ${dataT1folder}/T1_brain -init ${LinRegT2Folder}/T2_2_T1_init.mat -out ${LinRegT2Folder}/T2_2_T1 -omat ${LinRegT2Folder}/T2_2_T1.mat -dof 6

    if [ $do_tissue_seg = "yes" ] ; then
        log_Msg 3  `date`
        log_Msg 3 "Multichanel tissue segmentation of T1 using T2"

        $FSLDIR/bin/fast -o ${MultiChanFolder}/FAST -g -N -S 2 ${dataT1folder}/T1_brain  ${LinRegT2Folder}/T2_2_T1

        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_pve_0  ${MultChanFolder}/T1_pve_CSF
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_pve_1  ${MultChanFolder}/T1_pve_WM
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_pve_2  ${MultChanFolder}/T1_pve_GM
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_pveseg  ${MultChanFolder}/T1_pveseg
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_seg_0  ${MultChanFolder}/T1_CSF
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_seg_1  ${MultChanFolder}/T1_WM
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_seg_2  ${MultChanFolder}/T1_GM
        $FSLDIR/bin/immv ${MultiChanFolder}/FAST_seg  ${MultChanFolder}/T1_seg

        $FSLDIR/bin/fslmaths ${MultChanFolder}/T1_pve_WM -thr 0.5 -bin ${MultChanFolder}/T1_pve_thr_WM

        log_Msg 3  `date`
        log_Msg 3 "Main registration: between corrected T2w and corrected T1w"

        ${FSLDIR}/bin/epi_reg --epi=${dataT2Folder}/T2_brain --t1=${dataT1folder}/T1 --t1brain=${dataT1folder}/T1_brain --out=${LinRegT2Folder}/T2_2_T1_init --wmseg=${MultChanFolder}/T1_pve_thr_WM
        ${FSLDIR}/bin/flirt -in ${dataT2Folder}/T2_brain -ref ${dataT1folder}/T1_brain -init ${LinRegT2Folder}/T2_2_T1_init.mat -out ${LinRegT2Folder}/T2_2_T1 -omat ${LinRegT2Folder}/T2_2_T1.mat -dof 6
    fi

    log_Msg 3  `date`
    log_Msg 3 "Organizing T2 non-linear registration folder"

    ${FSLDIR}/bin/applywarp --rel --in=${dataT2Folder}/T2 --ref=$FSLDIR/data/standard/MNI152_T1_1mm --premat=${LinRegT2Folder}/T2_2_T1.mat --warp=${NonLinRegFolder}/T1_2_std_warp_coeff --out=${NonLinRegT2Folder}/T2_to_std_warp --interp=spline

    ${FSLDIR}/bin/invwarp --ref=${dataT1folder}/T1 -w ${NonLinRegFolder}/T1_2_std_warp_coeff -o ${NonLinRegFolder}/std_2_T1_warp

    ${FSLDIR}/bin/convert_xfm -inverse ${LinRegT2Folder}/T2_2_T1.mat -omat ${LinRegT2Folder}/T1_2_T2.mat

    ${FSLDIR}/bin/applywarp --rel --in=$FSLDIR/data/standard/MNI152_T1_1mm_brain_mask --ref=${dataT2Folder}/T2 --warp=${NonLinRegFolder}/std_2_T1_warp --postmat=${LinRegT2Folder}/T1_2_T2.mat --out=${dataT2Folder}/T2_brain_mask --interp=spline

    ${FSLDIR}/bin/fslmaths ${dataT2Folder}/T2 -mul ${dataT2Folder}/T2_brain_mask ${dataT2Folder}/T2_brain

    cp -r $T2datadir/* ${FSLanatT2Folder}/
    rm -rf $T2datadir
fi

log_Msg 3 ""
log_Msg 3 "                    END: Organizing data structure  "
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "


################################################################################################
## Cleanup
################################################################################################
