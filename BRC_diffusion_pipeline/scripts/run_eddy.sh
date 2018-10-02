#!/bin/bash
# Last update: 28/09/2018

set -e
echo -e "\n START: eddy"

workingdir=$1
Apply_Topup=$2
do_QC=$3
qcdir=$4

topupdir=`dirname ${workingdir}`/topup

if [ $Apply_Topup = yes ] ; then
    ${FSLDIR}/bin/imcp ${topupdir}/nodif_brain_mask ${workingdir}/
else
    echo "Running BET on the Pos b0"
    ${FSLDIR}/bin/fslroi ${workingdir}/Pos_b0 ${workingdir}/Pos_b01 0 1
    ${FSLDIR}/bin/bet ${workingdir}/Pos_b01 ${workingdir}/nodif_brain -m -f 0.2
fi

#if [ "x$CUDA_HOME" = "x" ] ; then   #No CUDA installed, run OPEMP version
#    nice ${FSLDIR}/bin/eddy_openmp --imain=${workingdir}/Pos_Neg --mask=${workingdir}/nodif_brain_mask --index=${workingdir}/index.txt --acqp=${workingdir}/acqparams.txt --bvecs=${workingdir}/Pos_Neg.bvecs --bvals=${workingdir}/Pos_Neg.bvals --fwhm=0 --topup=${topupdir}/topup_Pos_Neg_b0 --out=${workingdir}/eddy_unwarped_images --flm=quadratic -v #--resamp=lsr #--session=${workingdir}/series_index.txt
#else
if [ $Apply_Topup = yes ] ; then
    ${FSLDIR}/bin/eddy_cuda --imain=${workingdir}/Pos_Neg \
                            --mask=${workingdir}/nodif_brain_mask \
                            --index=${workingdir}/index.txt \
                            --acqp=${workingdir}/acqparams.txt \
                            --bvecs=${workingdir}/Pos_Neg.bvecs \
                            --bvals=${workingdir}/Pos_Neg.bvals \
                            --fwhm=0 \
                            --topup=${topupdir}/topup_Pos_Neg_b0 \
                            --out=${workingdir}/eddy_unwarped_images \
                            --flm=quadratic \
                            --cnr_maps \
                            --repol \
                            --s2v_niter=0 \
                            -v
else
    ${FSLDIR}/bin/eddy_cuda --imain=${workingdir}/Pos \
                            --mask=${workingdir}/nodif_brain_mask \
                            --index=${workingdir}/index.txt \
                            --acqp=${workingdir}/acqparams.txt \
                            --bvecs=${workingdir}/Pos.bvec \
                            --bvals=${workingdir}/Pos.bval \
                            --fwhm=0 \
                            --out=${workingdir}/eddy_unwarped_images \
                            --flm=quadratic \
                            --cnr_maps \
                            --repol \
                            --s2v_niter=0 \
                            -v
fi


  #fi

if [ $do_QC = yes ] ; then
    if [ $Apply_Topup = yes ] ; then
        eddy_quad ${workingdir}/eddy_unwarped_images \
                  -idx ${workingdir}/index.txt \
                  -par ${workingdir}/acqparams.txt \
                  -m ${workingdir}/nodif_brain_mask \
                  -b ${workingdir}/Pos_Neg.bvals \
                  -g ${workingdir}/Pos_Neg.bvecs
    else
        eddy_quad ${workingdir}/eddy_unwarped_images \
                  -idx ${workingdir}/index.txt \
                  -par ${workingdir}/acqparams.txt \
                  -m ${workingdir}/nodif_brain_mask \
                  -b ${workingdir}/Pos.bval \
                  -g ${workingdir}/Pos.bvec
    fi


    mv ${workingdir}/eddy_unwarped_images.qc/* $qcdir/
    rm -r ${workingdir}/eddy_unwarped_images.qc
fi

echo -e "\n END: eddy"
