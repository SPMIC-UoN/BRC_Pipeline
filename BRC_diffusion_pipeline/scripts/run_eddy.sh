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
WD=`getopt1 "--workingdir" $@`
Apply_Topup=`getopt1 "--applytopup" $@`
do_QC=`getopt1 "--doqc" $@`
qcdir=`getopt1 "--qcdir" $@`
Slice2Volume=`getopt1 "--slice2vol" $@`
topupFolder=`getopt1 "--topupdir" $@`
SliceSpec=`getopt1 "--slspec" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+         START: Eddy for correcting eddy currents and movements         +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "Apply_Topup:$Apply_Topup"
log_Msg 2 "do_QC:$do_QC"
log_Msg 2 "qcdir:$qcdir"
log_Msg 2 "Slice2Volume:$Slice2Volume"
log_Msg 2 "topupFolder:$topupFolder"
log_Msg 2 "SliceSpec:$SliceSpec"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

if [[ $Slice2Volume == yes ]]; then
    MPOrder=4
else
    MPOrder=0
fi

if [ $Apply_Topup = yes ] ; then
    ${FSLDIR}/bin/imcp ${topupFolder}/nodif_brain_mask ${WD}/
else
    log_Msg 3 "Running BET on the Pos b0"
    ${FSLDIR}/bin/fslroi ${WD}/Pos_b0 ${WD}/Pos_b01 0 1
    ${FSLDIR}/bin/bet ${WD}/Pos_b01 ${WD}/nodif_brain -m -f 0.2
fi

#if [ "x$CUDA_HOME" = "x" ] ; then   #No CUDA installed, run OPEMP version
#    nice ${FSLDIR}/bin/eddy_openmp --imain=${WD}/Pos_Neg --mask=${WD}/nodif_brain_mask --index=${WD}/index.txt --acqp=${WD}/acqparams.txt --bvecs=${WD}/Pos_Neg.bvecs --bvals=${WD}/Pos_Neg.bvals --fwhm=0 --topup=${topupdir}/topup_Pos_Neg_b0 --out=${WD}/eddy_unwarped_images --flm=quadratic -v #--resamp=lsr #--session=${WD}/series_index.txt
#else

if [ $Apply_Topup = yes ] ; then
    imain_arg=${WD}/Pos_Neg
    bvecs_arg=${WD}/Pos_Neg.bvecs
    bvals_arg=${WD}/Pos_Neg.bvals
    b_arg=${WD}/Pos_Neg.bvals
    g_arg=${WD}/Pos_Neg.bvecs
else
    imain_arg=${WD}/Pos
    bvecs_arg=${WD}/Pos.bvec
    bvals_arg=${WD}/Pos.bval
    b_arg=${WD}/Pos.bval
    g_arg=${WD}/Pos.bvec
fi

EDDY_arg="--imain=${imain_arg} --mask=${WD}/nodif_brain_mask --index=${WD}/index.txt --acqp=${WD}/acqparams.txt --bvecs=${bvecs_arg} --bvals=${bvals_arg} --out=${WD}/eddy_unwarped_images"
EDDY_arg="${EDDY_arg} --fwhm=0 --flm=quadratic --cnr_maps --repol --s2v_niter=0 -v"
EDDY_arg="${EDDY_arg} --mporder=${MPOrder} --s2v_niter=10 --s2v_fwhm=0 --s2v_interp=trilinear --s2v_lambda=1"

if [ ! $SliceSpec = "NONE" ] ; then
    ${MATLABpath}/matlab -nojvm -nodesktop -r "addpath('${BRC_FMRI_SCR}'); extract_slice_specifications('${SliceSpec}' , '${WD}/slspec.txt'); exit"

    if [ -e ${WD}/slspec.txt ] ; then
        EDDY_arg="${EDDY_arg} --slspec=${WD}/slspec.txt"
    else
        log_Msg 3 ""
        log_Msg 3 "WARNING: Slice Timing information does not exist in the json file"
        log_Msg 3 ""
    fi
fi

if [ $Apply_Topup = yes ] ; then
    EDDY_arg="${EDDY_arg} --topup=${topupFolder}/topup_Pos_Neg_b0"
fi

$FSLDIR/bin/eddy_cuda  ""$EDDY_arg""

#if [ $Apply_Topup = yes ] ; then
#    ${FSLDIR}/bin/eddy_cuda --imain=${WD}/Pos_Neg \
#                            --mask=${WD}/nodif_brain_mask \
#                            --index=${WD}/index.txt \
#                            --acqp=${WD}/acqparams.txt \
#                            --bvecs=${WD}/Pos_Neg.bvecs \
#                            --bvals=${WD}/Pos_Neg.bvals \
#                            --fwhm=0 \
#                            --topup=${topupFolder}/topup_Pos_Neg_b0 \
#                            --out=${WD}/eddy_unwarped_images \
#                            --flm=quadratic \
#                            --cnr_maps \
#                            --repol \
#                            --s2v_niter=0 \
#                            -v
#else
#    ${FSLDIR}/bin/eddy_cuda --imain=${WD}/Pos \
#                            --mask=${WD}/nodif_brain_mask \
#                            --index=${WD}/index.txt \
#                            --acqp=${WD}/acqparams.txt \
#                            --bvecs=${WD}/Pos.bvec \
#                            --bvals=${WD}/Pos.bval \
#                            --fwhm=0 \
#                            --out=${WD}/eddy_unwarped_images \
#                            --flm=quadratic \
#                            --cnr_maps \
#                            --repol \
#                            --s2v_niter=0 \
#                            -v
#fi


  #fi

if [ $do_QC = yes ] ; then

    eddy_quad ${WD}/eddy_unwarped_images \
              -idx ${WD}/index.txt \
              -par ${WD}/acqparams.txt \
              -m ${WD}/nodif_brain_mask \
              -b ${b_arg} \
              -g ${g_arg}


    mv ${WD}/eddy_unwarped_images.qc/* $qcdir/
    rm -r ${WD}/eddy_unwarped_images.qc
fi

log_Msg 3 ""
log_Msg 3 "           END: Eddy for correcting eddy currents and movements"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "


################################################################################################
## Cleanup
################################################################################################
