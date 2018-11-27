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
wmseg=`getopt1 "--wmseg" $@`
dataT1Folder=`getopt1 "--datat1folder" $@`
regT1Folder=`getopt1 "--regt1folder" $@`
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
log_Msg 2 "wmseg:$wmseg"
log_Msg 2 "dataT1Folder:$dataT1Folder"
log_Msg 2 "regT1Folder:$regT1Folder"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

Standard=$FSLDIR/data/standard/MNI152_T1_2mm

log_Msg 3 "Linear registration to standard space"

${FSLDIR}/bin/fslmaths ${datadir}/data -mul ${datadir}/nodif_brain_mask ${datadir}/data_brain


#Linear registration of DTI to T1
${FSLDIR}/bin/flirt -in ${datadir}/nodif_brain -ref ${dataT1Folder}/T1_brain -dof 6 -omat ${regdir}/diff2std_init.mat

${FSLDIR}/bin/flirt -in ${datadir}/nodif_brain -ref ${dataT1Folder}/T1_brain -init ${regdir}/diff2std_init.mat -cost bbr -bbrtype global_abs -dof 6 \
                                               -wmseg ${wmseg} -out ${regdir}/diff_2_T1 -omat ${regdir}/diff_2_T1.mat

${FSLDIR}/bin/convert_xfm -omat ${regdir}/diff_2_std.mat -concat ${regT1Folder}/T1_2_std.mat ${regdir}/diff_2_T1.mat

${FSLDIR}/bin/flirt  --interp=spline --in=${datadir}/data_brain --ref=${Standard}_brain --out=${regdir}/diff_2_stf -applyxfm --init=${regdir}/diff_2_std.mat -cost bbr -dof 6

$FSLDIR/bin/convert_xfm -inverse ${regdir}/diff_2_T1.mat -omat ${regdir}/T1_2_diff.mat
$FSLDIR/bin/convert_xfm -inverse ${regdir}/diff_2_std.mat -omat ${regdir}/std_2_diff.mat

log_Msg 3 "Non-Linear registration to standard space"

###${FSLDIR}/bin/convertwarp --ref=${Standard} --premat=./dMRI/reg/FLIRT/DTI_2_T1_vol1.mat --warp1=./T1/T1.anat/T1_to_MNI_nonlin_coeff.nii.gz --out=./dMRI/reg/FNIRT/DTI_to_MNI_warp.nii.gz

${FSLDIR}/bin/applywarp --rel --interp=spline --in=${datadir}/data --ref=${Standard} --premat=${regdir}/diff_2_T1.mat --warp=${regT1Folder}/T1_2_std_warp_coeff \
                                          --out=${regdir}/diff_to_std_warp

${FSLDIR}/bin/convertwarp  --relout --ref=${Standard} --premat=${regdir}/diff_2_T1.mat --warp1=${regT1Folder}/T1_2_std_warp_coeff --out=${regdir}/diff_2_std_warp_coeff
#$FSLDIR/bin/invwarp --ref=${datadir}/nodif -w ${regdir}/diff_2_std_warp_coeff -o std_to_diff_warp_coeff

${FSLDIR}/bin/applywarp --rel --interp=spline --in=${Standard} --ref=${datadir}/nodif_brain --warp=${regT1Folder}/std_2_T1_warp_field \
                                           --postmat=${regdir}/T1_2_diff.mat --out=${regdir}/std_2_diff_warp

log_Msg 3 ""
log_Msg 3 "                            END: Registration"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################
rm ${regdir}/diff2std_init.mat

${FSLDIR}/bin/imrm ${WD}/${ScoutInputFile}_undistorted2T1w_init_fast_*
