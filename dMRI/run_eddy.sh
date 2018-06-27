#!/bin/bash
# Last update: 06/06/2018

set -e
echo -e "\n START: eddy"

workingdir=$1
topupdir=`dirname ${workingdir}`/topup

${FSLDIR}/bin/imcp ${topupdir}/nodif_brain_mask ${workingdir}/

#if [ "x$CUDA_HOME" = "x" ] ; then   #No CUDA installed, run OPEMP version
#    nice ${FSLDIR}/bin/eddy_openmp --imain=${workingdir}/Pos_Neg --mask=${workingdir}/nodif_brain_mask --index=${workingdir}/index.txt --acqp=${workingdir}/acqparams.txt --bvecs=${workingdir}/Pos_Neg.bvecs --bvals=${workingdir}/Pos_Neg.bvals --fwhm=0 --topup=${topupdir}/topup_Pos_Neg_b0 --out=${workingdir}/eddy_unwarped_images --flm=quadratic -v #--resamp=lsr #--session=${workingdir}/series_index.txt
#else
    ${FSLDIR}/bin/eddy_cuda --imain=${workingdir}/Pos_Neg --mask=${workingdir}/nodif_brain_mask --index=${workingdir}/index.txt --acqp=${workingdir}/acqparams.txt --bvecs=${workingdir}/Pos_Neg.bvecs --bvals=${workingdir}/Pos_Neg.bvals --fwhm=0 --topup=${topupdir}/topup_Pos_Neg_b0 --out=${workingdir}/eddy_unwarped_images --flm=quadratic --cnr_maps --repol --s2v_niter=0 -v
#fi

eddy_quad ${workingdir}/eddy_unwarped_images -idx ${workingdir}/index.txt -par ${workingdir}/acqparams.txt -m ${workingdir}/nodif_brain_mask -b ${workingdir}/Pos_Neg.bvals -g ${workingdir}/Pos_Neg.bvecs

echo -e "\n END: eddy"
