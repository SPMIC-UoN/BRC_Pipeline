#!/bin/bash
# Last update: 28/09/2018

set -e
echo -e "\n START: registration"

workingdir=$1
T2_exist=$2
do_Sub_seg=$3

T1_dir=$workingdir/T1

datadir=${T1_dir}/temp.anat

# Find related files in the fsl_anat output folder and move them to the related folders in the T1 directory
targdir=$T1_dir/preprocess

$FSLDIR/bin/immv $datadir/T1_biascorr  $targdir/T1_biascorr
$FSLDIR/bin/immv $datadir/T1_biascorr_brain  $targdir/T1_biascorr_brain
$FSLDIR/bin/immv $datadir/T1_biascorr_brain_mask  $targdir/T1_biascorr_brain_mask

targdir=$T1_dir/seg/tissue

$FSLDIR/bin/immv $datadir/T1_fast_pve_0  $targdir/sing_chan/T1_pve_CSF
$FSLDIR/bin/immv $datadir/T1_fast_pve_1  $targdir/sing_chan/T1_pve_GM
$FSLDIR/bin/immv $datadir/T1_fast_pve_2  $targdir/sing_chan/T1_pve_WM
$FSLDIR/bin/fslmaths $targdir/sing_chan/T1_pve_WM -thr 0.5 -bin $targdir/sing_chan/T1_pve_WMseg
$FSLDIR/bin/immv $datadir/T1_fast_pveseg  $targdir/sing_chan/T1_pveseg
$FSLDIR/bin/immv $datadir/T1_fast_seg  $targdir/sing_chan/T1_seg

if [ $do_Sub_seg = yes ] ; then
  targdir=$T1_dir/seg/sub
  sourcdir=${T1_dir}/temp.anat/first_results

  if [ -e $sourcdir/T1_first_all_fast_firstseg ] ; then
    $FSLDIR/bin/immv $sourcdir/T1_first_all_fast_firstseg  $targdir/T1_subcort_seg
  fi

  mv $datadir/T1_vols.txt  $targdir/T1_vols.txt

  mv $sourcdir/T1_first-BrStem_first.bvars  $targdir/shape/T1_BrStem.bvars
  mv $sourcdir/T1_first-BrStem_first.vtk  $targdir/shape/T1_BrStem.vtk
  mv $sourcdir/T1_first-L_Accu_first.bvars  $targdir/shape/T1_L_Accu.bvars
  mv $sourcdir/T1_first-R_Accu_first.bvars  $targdir/shape/T1_R_Accu.bvars
  mv $sourcdir/T1_first-L_Accu_first.vtk  $targdir/shape/T1_L_Accu.vtk
  mv $sourcdir/T1_first-R_Accu_first.vtk  $targdir/shape/T1_R_Accu.vtk
  mv $sourcdir/T1_first-L_Amyg_first.bvars  $targdir/shape/T1_L_Amyg.bvars
  mv $sourcdir/T1_first-R_Amyg_first.bvars  $targdir/shape/T1_R_Amyg.bvars
  mv $sourcdir/T1_first-L_Amyg_first.vtk  $targdir/shape/T1_L_Amyg.vtk
  mv $sourcdir/T1_first-R_Amyg_first.vtk  $targdir/shape/T1_R_Amyg.vtk
  mv $sourcdir/T1_first-L_Caud_first.bvars  $targdir/shape/T1_L_Caud.bvars
  mv $sourcdir/T1_first-R_Caud_first.bvars  $targdir/shape/T1_R_Caud.bvars
  mv $sourcdir/T1_first-L_Caud_first.vtk  $targdir/shape/T1_L_Caud.vtk
  mv $sourcdir/T1_first-R_Caud_first.vtk  $targdir/shape/T1_R_Caud.vtk
  mv $sourcdir/T1_first-L_Hipp_first.bvars  $targdir/shape/T1_L_Hipp.bvars
  mv $sourcdir/T1_first-R_Hipp_first.bvars  $targdir/shape/T1_R_Hipp.bvars
  mv $sourcdir/T1_first-L_Hipp_first.vtk  $targdir/shape/T1_L_Hipp.vtk
  mv $sourcdir/T1_first-R_Hipp_first.vtk  $targdir/shape/T1_R_Hipp.vtk
  mv $sourcdir/T1_first-L_Pall_first.bvars  $targdir/shape/T1_L_Pall.bvars
  mv $sourcdir/T1_first-R_Pall_first.bvars  $targdir/shape/T1_R_Pall.bvars
  mv $sourcdir/T1_first-L_Pall_first.vtk  $targdir/shape/T1_L_Pall.vtk
  mv $sourcdir/T1_first-R_Pall_first.vtk  $targdir/shape/T1_R_Pall.vtk
  mv $sourcdir/T1_first-R_Puta_first.bvars  $targdir/shape/T1_R_Puta.bvars
  mv $sourcdir/T1_first-L_Puta_first.bvars  $targdir/shape/T1_L_Puta.bvars
  mv $sourcdir/T1_first-R_Puta_first.vtk  $targdir/shape/T1_R_Puta.vtk
  mv $sourcdir/T1_first-L_Puta_first.vtk  $targdir/shape/T1_L_Puta.vtk
  mv $sourcdir/T1_first-R_Thal_first.bvars  $targdir/shape/T1_R_Thal.bvars
  mv $sourcdir/T1_first-L_Thal_first.bvars  $targdir/shape/T1_L_Thal.bvars
  mv $sourcdir/T1_first-R_Thal_first.vtk  $targdir/shape/T1_R_Thal.vtk
  mv $sourcdir/T1_first-L_Thal_first.vtk  $targdir/shape/T1_L_Thal.vtk

  mv $datadir/T1_biascorr_to_std_sub.mat  $T1_dir/reg/lin/T1_2_std_sub.mat
#  $FSLDIR/bin/immv $datadir/T1_biascorr_to_std_sub  $T1_dir/reg/lin/T1_2_std_sub
fi

echo "Do linear registration"

$FSLDIR/bin/immv $datadir/T1_to_MNI_lin  $T1_dir/reg/lin/T1_2_std
mv $datadir/T1_to_MNI_lin.mat  $T1_dir/reg/lin/T1_2_std.mat
$FSLDIR/bin/convert_xfm -inverse $T1_dir/reg/lin/T1_2_std.mat -omat $T1_dir/reg/lin/std_2_T1.mat

echo "Do non-linear registration"

$FSLDIR/bin/immv $datadir/T1_to_MNI_nonlin  $T1_dir/reg/nonlin/T1_2_std_warp
$FSLDIR/bin/immv $datadir/T1_to_MNI_nonlin_coeff  $T1_dir/reg/nonlin/T1_2_std_warp_coeff
$FSLDIR/bin/immv $datadir/T1_to_MNI_nonlin_field  $T1_dir/reg/nonlin/T1_2_std_warp_field
$FSLDIR/bin/immv $datadir/T1_to_MNI_nonlin_jac  $T1_dir/reg/nonlin/T1_2_std_warp_jac
$FSLDIR/bin/immv $datadir/MNI_to_T1_nonlin_field  $T1_dir/reg/nonlin/std_2_T1_warp_field

cp -r $datadir/* $T1_dir/unlabeled/fsl_anat/
rm -rf $datadir

#: <<'COMMENT'

if [[ $T2_exist == yes ]]; then
    T2_dir=$workingdir/T2
    T2datadir=${T2_dir}/temp.anat

    targdir=$T2_dir/preprocess

    $FSLDIR/bin/immv $T2datadir/T2_biascorr  $targdir/T2_biascorr
    $FSLDIR/bin/immv $T2datadir/T2_biascorr_brain  $targdir/T2_biascorr_brain
    $FSLDIR/bin/immv $T2datadir/T2_biascorr_brain_mask  $targdir/T2_biascorr_brain_mask

    echo "T2w registration"
    # Main registration: between corrected T2w and corrected T1w
    ${FSLDIR}/bin/epi_reg --epi=$targdir/T2_biascorr_brain --t1=$T1_dir/preprocess/T1_biascorr --t1brain=$T1_dir/preprocess/T1_biascorr_brain --out=${T2_dir}/reg/lin/T2_2_T1_init --wmseg=$T1_dir/seg/tissue/sing_chan/T1_pve_WMseg

    ${FSLDIR}/bin/flirt -in $targdir/T2_biascorr_brain -ref $T1_dir/preprocess/T1_biascorr_brain -init ${T2_dir}/reg/lin/T2_2_T1_init.mat -out ${T2_dir}/reg/lin/T2_2_T1 -omat ${T2_dir}/reg/lin/T2_2_T1.mat -dof 6

    ${FSLDIR}/bin/applywarp --rel --in=$targdir/T2_biascorr --ref=$FSLDIR/data/standard/MNI152_T1_1mm --premat=${T2_dir}/reg/lin/T2_2_T1.mat --warp=${T1_dir}/reg/nonlin/T1_2_std_warp_coeff --out=${T2_dir}/reg/nonlin/T2_to_std_warp --interp=spline

    ${FSLDIR}/bin/invwarp --ref=$T1_dir/preprocess/T1_biascorr -w $T1_dir/reg/nonlin/T1_2_std_warp_coeff -o $T1_dir/reg/nonlin/std_2_T1_warp


    ${FSLDIR}/bin/convert_xfm -inverse ${T2_dir}/reg/lin/T2_2_T1.mat -omat ${T2_dir}/reg/lin/T1_2_T2.mat

    ${FSLDIR}/bin/applywarp --rel --in=$FSLDIR/data/standard/MNI152_T1_1mm_brain_mask --ref=$targdir/T2_biascorr --warp=$T1_dir/reg/nonlin/std_2_T1_warp --postmat=${T2_dir}/reg/lin/T1_2_T2.mat --out=$targdir/T2_biascorr_brain_mask --interp=spline

    ${FSLDIR}/bin/fslmaths $targdir/T2_biascorr -mul $targdir/T2_biascorr_brain_mask $targdir/T2_biascorr_brain

    cp -r $T2datadir/* $T2_dir/unlabeled/fsl_anat/
    rm -rf $T2datadir
fi
