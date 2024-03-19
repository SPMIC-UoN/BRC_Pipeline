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
workingdir=`getopt1 "--workingdir" $@`
eddydir=`getopt1 "--eddyfolder" $@`
datadir=`getopt1 "--datafolder" $@`
CombineMatchedFlag=`getopt1 "--combinematched" $@`
Apply_Topup=`getopt1 "--Apply_Topup" $@`
HIRES=`getopt1 "--hires" $@`
do_NODDI=`getopt1 "--donoddi" $@`
do_DKI=`getopt1 "--dodki" $@`
do_WMTI=`getopt1 "--dowmti" $@`
do_FWDTI=`getopt1 "--dofwdti" $@`
b0maxbval=`getopt1 "--b0maxbval" $@`
DTIMaxShell=`getopt1 "--dtimaxshell" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                      START: Eddy Post-processing                       +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "workingdir:$workingdir"
log_Msg 2 "eddydir:$eddydir"
log_Msg 2 "datadir:$datadir"
log_Msg 2 "CombineMatchedFlag:$CombineMatchedFlag"
log_Msg 2 "Apply_Topup:$Apply_Topup"
log_Msg 2 "HIRES:$HIRES"
log_Msg 2 "do_NODDI:$do_NODDI"
log_Msg 2 "do_DKI:$do_DKI"
log_Msg 2 "do_WMTI:$do_WMTI"
log_Msg 2 "do_FWDTI:$do_FWDTI"
log_Msg 2 "b0maxbval:$b0maxbval"
log_Msg 2 "DTIMaxShell:$DTIMaxShell"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 3 `date`

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
        ${FSLDIR}/bin/fslroi ${eddydir}/eddy_unwarped_images ${eddydir}/eddy_unwarped_Neg $((${PosVols} - 1)) 1

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
if [ $HIRES = "yes" ] ; then
    ${FSLDIR}/bin/bet ${datadir}/data ${datadir}/nodif_brain -m -f 0.15
else
    ${FSLDIR}/bin/bet ${datadir}/data ${datadir}/nodif_brain -m -f 0.20
fi
${FSLDIR}/bin/fslroi ${datadir}/data ${datadir}/nodif 0 1

if [[ $do_DKI == "yes" ]] || [[ ${do_WMTI} == "yes" ]] || [[ ${do_FWDTI} == "yes" ]]; then

    if [ ${CLUSTER_MODE} = "YES" ] ; then
        module load brcpython-img
    else
        module load brcpython
    fi

    if [[ $do_DKI == "yes" ]]; then
        log_Msg 3 "DKI model"
        if [ ! -d ${datadir}/"data.dki" ]; then mkdir ${datadir}/"data.dki"; fi
    fi
    if [[ ${do_WMTI} == "yes" ]]; then
        log_Msg 3 "WMTI model"
        if [ ! -d ${datadir}/"data.wmti" ]; then mkdir ${datadir}/"data.wmti"; fi
    fi
    if [[ ${do_FWDTI} == "yes" ]]; then
        log_Msg 3 "Free Water Model"
        if [ ! -d ${datadir}/"data.fwdti" ]; then mkdir ${datadir}/"data.fwdti"; fi
    fi

    $FSLDIR/bin/fslmaths ${datadir}/data -mul ${datadir}/nodif_brain_mask ${datadir}/data_brain

    python ${BRC_DMRI_SCR}/run_DKI.py ${datadir} "no" ${do_DKI} ${do_WMTI} ${do_FWDTI}

    # if [ `${FSLDIR}/bin/imtest ${datadir}/data_brain` = 1 ] ; then
    #     $FSLDIR/bin/imrm ${datadir}/data_brain
    # fi

fi

log_Msg 3 "Prepare the data for DTI model"

# ${FSLDIR}/fslpython/envs/fslpython/bin/python ${BRC_DMRI_SCR}/extract_shells.py ${datadir}/bvals ${DTIMaxShell}
${FSLDIR}/bin/fslpython ${BRC_DMRI_SCR}/extract_shells.py ${datadir}/bvals ${DTIMaxShell}

CMD=""
for shell in `cat ${datadir}/shells.txt` 
do 
    CMD="${CMD} -b ${shell}"
done

${FSLDIR}/bin/select_dwi_vols ${datadir}/data \
                                ${datadir}/bvals \
                                ${datadir}/data_dti \
                                0 \
                                ${CMD} \
                                -obv ${datadir}/bvecs \
                                -db ${b0maxbval}

if [ ${do_NODDI} = "yes" ] ; then

    if [ ${CLUSTER_MODE} = "YES" ] ; then
        module load cuda-12.2.2
    fi

    log_Msg 3 "NODDI model"
    ${CUDIMOT}/bin/Pipeline_NODDI_Watson.sh ${datadir}

    if [ ${CLUSTER_MODE} = "YES" ] ; then
        module load cuda-img/9.1
    fi

else
    log_Msg 3 "DTIFIT model"

    ${FSLDIR}/bin/dtifit -k ${datadir}/data_dti \
                         -m ${datadir}/nodif_brain \
                         -r ${datadir}/data_dti.bvec \
                         -b ${datadir}/data_dti.bval \
                         -o ${datadir}/dti \
                         --save_tensor

    if [ ! -d ${datadir}/"data.dti" ]; then mkdir ${datadir}/"data.dti"; fi

    ${FSLDIR}/bin/immv ${datadir}/dti_FA ${datadir}/"data.dti"/dti_FA
    ${FSLDIR}/bin/immv ${datadir}/dti_L1 ${datadir}/"data.dti"/dti_L1
    ${FSLDIR}/bin/immv ${datadir}/dti_L2 ${datadir}/"data.dti"/dti_L2
    ${FSLDIR}/bin/immv ${datadir}/dti_L3 ${datadir}/"data.dti"/dti_L3
    ${FSLDIR}/bin/immv ${datadir}/dti_V1 ${datadir}/"data.dti"/dti_V1
    ${FSLDIR}/bin/immv ${datadir}/dti_V2 ${datadir}/"data.dti"/dti_V2
    ${FSLDIR}/bin/immv ${datadir}/dti_V3 ${datadir}/"data.dti"/dti_V3
    ${FSLDIR}/bin/immv ${datadir}/dti_MD ${datadir}/"data.dti"/dti_MD
    ${FSLDIR}/bin/immv ${datadir}/dti_MO ${datadir}/"data.dti"/dti_MO
    ${FSLDIR}/bin/immv ${datadir}/dti_S0 ${datadir}/"data.dti"/dti_S0
    ${FSLDIR}/bin/immv ${datadir}/dti_tensor ${datadir}/"data.dti"/dti_tensor

    rm ${datadir}/data_dti*
    rm ${datadir}/shells.txt
fi

#Cleaning up unnecessary files
rm -rf ${workingdir}/raw

if [ $Apply_Topup = yes ] ; then
    ${FSLDIR}/bin/imrm ${eddydir}/Pos_Neg
else
    ${FSLDIR}/bin/imrm ${eddydir}/Pos
fi
#${FSLDIR}/bin/imrm ${eddydir}/eddy_unwarped_images

log_Msg 3 ""
log_Msg 3 "                        END: Eddy Post-processing"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################
# : <<'COMMENT'
