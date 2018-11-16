#!/bin/bash
# Last update: 28/09/2018

set -e
echo -e "\n START: postproc"


workingdir=$1
CombineMatchedFlag=$2
Apply_Topup=$3

eddydir=${workingdir}/preprocess/eddy
datadir=${workingdir}/processed

if [ ${CombineMatchedFlag} -eq 2 ]; then
    ${FSLDIR}/bin/imcp  ${eddydir}/eddy_unwarped_images ${datadir}/data

    if [ $Apply_Topup = yes ] ; then
        cp ${eddydir}/Pos_Neg.bvals ${datadir}/bvals
        cp ${eddydir}/Pos_Neg.bvecs ${datadir}/bvecs
    else
        cp ${eddydir}/Pos.bval ${datadir}/bvals
        cp ${eddydir}/Pos.bvec ${datadir}/bvecs
    fi

else
    PosVols=`wc ${eddydir}/Pos.bval | awk {'print $2'}`
    ${FSLDIR}/bin/fslroi ${eddydir}/eddy_unwarped_images ${eddydir}/eddy_unwarped_Pos 0 ${PosVols}

    if [ $Apply_Topup = yes ] ; then
        NegVols=`wc ${eddydir}/Neg.bval | awk {'print $2'}`    #Split Pos and Neg Volumes
        ${FSLDIR}/bin/fslroi ${eddydir}/eddy_unwarped_images ${eddydir}/eddy_unwarped_Neg ${PosVols} ${NegVols}
    else
        NegVols=$PosVols
        ${FSLDIR}/bin/fslroi ${eddydir}/eddy_unwarped_images ${eddydir}/eddy_unwarped_Neg $((${PosVols} - 1)) ${PosVols}

        touch ${eddydir}/Neg.bval
        touch ${eddydir}/Neg.bvec
    fi

    ${BRC_DMRI_SCR}/eddy_combine.sh ${eddydir}/eddy_unwarped_Pos ${eddydir}/Pos.bval ${eddydir}/Pos.bvec ${eddydir}/Pos_SeriesVolNum.txt \
                                    ${eddydir}/eddy_unwarped_Neg ${eddydir}/Neg.bval ${eddydir}/Neg.bvec ${eddydir}/Neg_SeriesVolNum.txt ${datadir} ${CombineMatchedFlag}

    ${FSLDIR}/bin/imrm ${eddydir}/eddy_unwarped_Neg
    ${FSLDIR}/bin/imrm ${eddydir}/eddy_unwarped_Pos
fi

#Remove negative intensity values (caused by spline interpolation) from final data
${FSLDIR}/bin/fslmaths ${datadir}/data -thr 0 ${datadir}/data
${FSLDIR}/bin/bet ${datadir}/data ${datadir}/nodif_brain -m -f 0.25

${FSLDIR}/bin/dtifit -k ${datadir}/data -m ${datadir}/nodif_brain -r ${datadir}/bvecs -b ${datadir}/bvals -o ${datadir}/dti

#Cleaning up unnecessary files
rm -rf ${workingdir}/raw

if [ $Apply_Topup = yes ] ; then
    ${FSLDIR}/bin/imrm ${eddydir}/Pos_Neg
else
    ${FSLDIR}/bin/imrm ${eddydir}/Pos
fi
#${FSLDIR}/bin/imrm ${eddydir}/eddy_unwarped_images

echo -e "\n END: postproc"
