#!/bin/bash
# Last update: 28/09/2018

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
datadir=`getopt1 "--datafolder" $@`
regdir=`getopt1 "--regfolder" $@`
T1wImage=`getopt1 "--t1" $@`
T1wRestore=`getopt1 "--t1restore" $@`
T1wBrainImage=`getopt1 "--t1brain" $@`
wmseg=`getopt1 "--wmseg" $@`
dof=`getopt1 "--dof" $@`
dataT1Folder=`getopt1 "--datat1folder" $@`
regT1Folder=`getopt1 "--regt1folder" $@`
data2strFolder=`getopt1 "--outstr" $@`
data2stdFolder=`getopt1 "--outstd" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                          START: Registration                           +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "datadir:$datadir"
log_Msg 2 "regdir:$regdir"
log_Msg 2 "T1wImage:$T1wImage"
log_Msg 2 "T1wRestore:$T1wRestore"
log_Msg 2 "T1wBrainImage:$T1wBrainImage"
log_Msg 2 "wmseg:$wmseg"
log_Msg 2 "dof:$dof"
log_Msg 2 "dataT1Folder:$dataT1Folder"
log_Msg 2 "regT1Folder:$regT1Folder"
log_Msg 2 "data2strFolder:$data2strFolder"
log_Msg 2 "data2stdFolder:$data2stdFolder"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 3 `date`
Standard=$FSLDIR/data/standard/MNI152_T1_2mm

${FSLDIR}/bin/fslroi ${datadir}/data ${datadir}/nodif 0 1

log_Msg 3 "Linear registration to structural space"
${BRC_FMRI_SCR}/epi_reg_dof.sh --dof=${dof} --epi=${datadir}/nodif --t1=${T1wImage} --t1brain=${T1wBrainImage} --wmseg=${wmseg} --out=${regdir}/diff_2_T1_initII

${FSLDIR}/bin/applywarp --rel --interp=spline -i ${datadir}/nodif -r ${T1wImage} --premat=${regdir}/diff_2_T1_initII_init.mat -o ${regdir}/diff_2_T1_init.nii.gz
${FSLDIR}/bin/applywarp --rel --interp=spline -i ${datadir}/nodif -r ${T1wImage} --premat=${regdir}/diff_2_T1_initII.mat -o ${regdir}/diff_2_T1_initII.nii.gz

#${FSLDIR}/bin/fslmaths ${regdir}/diff_2_T1_initII.nii.gz -div ${BiasField} ${regdir}/diff_2_T1_restore_initII.nii.gz

${FSLDIR}/bin/convert_xfm -omat ${regdir}/diff_2_T1.mat -concat $FSLDIR/etc/flirtsch/ident.mat ${regdir}/diff_2_T1_initII.mat
#${FSLDIR}/bin/convert_xfm -omat ${regdir}/T1_2_diff.mat -inverse ${regdir}/diff_2_T1.mat

${FSLDIR}/bin/applywarp --rel --interp=spline -i ${datadir}/nodif -r ${T1wImage} --premat=${regdir}/diff_2_T1.mat -o ${data2strFolder}/nodif2str
${FSLDIR}/bin/fslmaths ${data2strFolder}/nodif2str -thr 0 ${data2strFolder}/nodif2str
#${FSLDIR}/bin/fslmaths ${regdir}/nodif_2_T1 -div ${BiasField} ${regdir}/nodif_2_T1_restore

#Register diffusion data to T1w space without considering gradient nonlinearities
${FSLDIR}/bin/flirt -in ${datadir}/data -ref ${T1wRestore} -applyxfm -init ${regdir}/diff_2_T1.mat -interp spline -out ${data2strFolder}/data2str
${FSLDIR}/bin/fslmaths ${data2strFolder}/data2str -thr 0 ${data2strFolder}/data2str


#${FSLDIR}/bin/fslmaths "$T1wOutputDirectory"/data -mas "$T1wOutputDirectory"/nodif_brain_mask_temp "$T1wOutputDirectory"/data  #Mask-out data outside the brain

#: <<'COMMENT'







#${FSLDIR}/bin/fslmaths ${datadir}/data -mul ${datadir}/nodif_brain_mask ${datadir}/data_brain


#Linear registration of DTI to T1
#${FSLDIR}/bin/flirt -in ${datadir}/nodif_brain -ref ${dataT1Folder}/T1_brain -dof 6 -omat ${regdir}/diff_2_T1_init.mat

#${FSLDIR}/bin/flirt -in ${datadir}/nodif_brain -ref ${dataT1Folder}/T1_brain -init ${regdir}/diff_2_T1_init.mat -cost bbr -bbrtype global_abs -dof 6 \
#                                               -wmseg ${wmseg} -out ${regdir}/diff_2_T1 -omat ${regdir}/diff_2_T1.mat

${FSLDIR}/bin/convert_xfm -omat ${regdir}/diff_2_std.mat -concat ${regT1Folder}/T1_2_std.mat ${regdir}/diff_2_T1.mat

#${FSLDIR}/bin/flirt -in ${datadir}/data -ref ${Standard} -applyxfm -init ${regdir}/diff_2_std.mat -interp spline -out ${regdir}/data2std

#${FSLDIR}/bin/flirt  -interp spline -in ${datadir}/data_brain -ref ${Standard}_brain -out ${regdir}/diff_2_std -applyxfm -init ${regdir}/diff_2_std.mat -cost bbr -dof 6

$FSLDIR/bin/convert_xfm -inverse ${regdir}/diff_2_T1.mat -omat ${regdir}/T1_2_diff.mat
#$FSLDIR/bin/convert_xfm -inverse ${regdir}/diff_2_std.mat -omat ${regdir}/std_2_diff.mat

log_Msg 3 "Non-Linear registration to standard space"

###${FSLDIR}/bin/convertwarp --ref=${Standard} --premat=./dMRI/reg/FLIRT/DTI_2_T1_vol1.mat --warp1=./T1/T1.anat/T1_to_MNI_nonlin_coeff.nii.gz --out=./dMRI/reg/FNIRT/DTI_to_MNI_warp.nii.gz

${FSLDIR}/bin/applywarp --rel --interp=spline --in=${datadir}/nodif --ref=${Standard} --premat=${regdir}/diff_2_T1.mat --warp=${regT1Folder}/T1_2_std_warp_field \
                                          --out=${data2stdFolder}/nodif2std
${FSLDIR}/bin/fslmaths ${data2stdFolder}/nodif2std -thr 0 ${data2stdFolder}/nodif2std

${FSLDIR}/bin/applywarp --rel --interp=spline --in=${datadir}/data --ref=${Standard} --premat=${regdir}/diff_2_T1.mat --warp=${regT1Folder}/T1_2_std_warp_field \
                                          --out=${data2stdFolder}/data2std
${FSLDIR}/bin/fslmaths ${data2stdFolder}/data2std -thr 0 ${data2stdFolder}/data2std

${FSLDIR}/bin/convertwarp  --relout --ref=${Standard} --premat=${regdir}/diff_2_T1.mat --warp1=${regT1Folder}/T1_2_std_warp_field --out=${regdir}/diff_2_std_warp_coeff
#$FSLDIR/bin/invwarp --ref=${datadir}/nodif -w ${regdir}/diff_2_std_warp_coeff -o std_to_diff_warp_coeff

${FSLDIR}/bin/invwarp -w ${regdir}/diff_2_std_warp_coeff -o ${regdir}/std_2_diff_warp_coeff -r ${datadir}/nodif
#${FSLDIR}/bin/applywarp --rel --interp=spline --in=${Standard} --ref=${datadir}/nodif_brain --warp=${regT1Folder}/std_2_T1_warp_field \
#                                           --postmat=${regdir}/T1_2_diff.mat --out=${regdir}/std_2_diff_warp

log_Msg 3 ""
log_Msg 3 "                            END: Registration"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################
#rm ${regdir}/diff2std_init.mat

rm ${regdir}/diff_2_T1_*
