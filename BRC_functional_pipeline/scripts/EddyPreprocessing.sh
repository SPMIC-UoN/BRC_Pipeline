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
EddyFolder=`getopt1 "--workingdir" $@`
InputfMRI=`getopt1 "--inputfile" $@`
InputSBref=`getopt1 "--inscout" $@`
NameOffMRI=`getopt1 "--fmriname" $@`
DCFolder=`getopt1 "--dcfolder" $@`
DCMethod=`getopt1 "--dcmethod" $@`
topupFolderName=`getopt1 "--topupfodername" $@`
EddyOut=`getopt1 "--output_eddy" $@`
PhaseEncodeOne=`getopt1 "--SEPhaseNeg" $@`
PhaseEncodeTwo=`getopt1 "--SEPhasePos" $@`
UnwarpDir=`getopt1 "--unwarpdir" $@`  # "$6"
EchoSpacing=`getopt1 "--echospacing" $@`  # "$5"
Slice2Volume=`getopt1 "--slice2vol" $@`
SliceSpec=`getopt1 "--slspec" $@`
OutFolder=`getopt1 "--outfolder" $@`
EchoSpacing_fMRI=`getopt1 "--echospacingfmri" $@`  # "$5"
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+         START: Eddy for correcting eddy currents and movements         +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "EddyFolder:$EddyFolder"
log_Msg 2 "InputfMRI:$InputfMRI"
log_Msg 2 "InputSBref:$InputSBref"
log_Msg 2 "NameOffMRI:$NameOffMRI"
log_Msg 2 "DCFolder:$DCFolder"
log_Msg 2 "DCMethod:$DCMethod"
log_Msg 2 "EddyOut:$EddyOut"
log_Msg 2 "PhaseEncodeOne:$PhaseEncodeOne"
log_Msg 2 "PhaseEncodeTwo:$PhaseEncodeTwo"
log_Msg 2 "UnwarpDir:$UnwarpDir"
log_Msg 2 "EchoSpacing:$EchoSpacing"
log_Msg 2 "Slice2Volume:$Slice2Volume"
log_Msg 2 "SliceSpec:$SliceSpec"
log_Msg 2 "OutFolder:$OutFolder"
log_Msg 2 "EchoSpacing_fMRI:$EchoSpacing_fMRI"
log_Msg 2 "topupFolderName:$topupFolderName"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

if [ -e ${EddyFolder} ] ; then
    ${RUN} rm -r ${EddyFolder}
fi
mkdir -p $EddyFolder

if [[ $Slice2Volume == yes ]]; then
    MPOrder=4
else
    MPOrder=0
fi

TR_vol=`${FSLDIR}/bin/fslval ${InputfMRI} pixdim4 | cut -d " " -f 1`

#Concatenate SE_PE_POS and SE_PE_NEG to the original data
#if [[ ${DCMethod} == "TOPUP" ]]; then
    ${FSLDIR}/bin/fslmerge -tr ${EddyFolder}/SE_Neg_Pos ${PhaseEncodeOne} ${PhaseEncodeTwo} $TR_vol
    ${FSLDIR}/bin/fslmerge -tr ${EddyFolder}/${NameOffMRI}_SE_Neg_Pos ${InputfMRI} ${EddyFolder}/SE_Neg_Pos $TR_vol
    ${FSLDIR}/bin/fslmerge -tr ${EddyFolder}/SBref_${NameOffMRI}_SE_Neg_Pos ${InputSBref} ${EddyFolder}/${NameOffMRI}_SE_Neg_Pos $TR_vol
    Eddy_Input=${EddyFolder}/SBref_${NameOffMRI}_SE_Neg_Pos

#    ${FSLDIR}/bin/fslmerge -tr ${EddyFolder}/SBref_${NameOffMRI} ${InputSBref} ${InputfMRI} $TR_vol
#    Eddy_Input=${EddyFolder}/SBref_${NameOffMRI}


#else
#    ${FSLDIR}/bin/fslmerge -tr ${EddyFolder}/SBref_${NameOffMRI} ${InputSBref} ${InputfMRI} $TR_vol
#    Eddy_Input=${EddyFolder}/SBref_${NameOffMRI}
#fi

if [[ ${DCMethod} == "TOPUP" ]]; then
    BrainMask=$DCFolder/${topupFolderName}/Magnitude_brain_mask.nii.gz
else
    log_Msg 3 "generating brain mask using the 1st fMRI volume"
    ${FSLDIR}/bin/fslmaths ${InputfMRI} -Tmean ${EddyFolder}/${NameOffMRI}_mean
    ${FSLDIR}/bin/bet2 ${EddyFolder}/${NameOffMRI}_mean ${EddyFolder}/${NameOffMRI}_brain -f 0.3 -m -n
    BrainMask=${EddyFolder}/${NameOffMRI}_brain_mask.nii.gz

    ${FSLDIR}/bin/imrm ${EddyFolder}/${NameOffMRI}_mean
fi

log_Msg 3 "generating acquisition parameters"

if [ $EchoSpacing_fMRI != 0.0 ]; then

    #Generating acquisition file for the fMRI data
    txtfname=${EddyFolder}/acqparams.txt

    ${BRC_FMRI_SCR}/Generate_Parameter_File.sh \
                  --workingdir=${EddyFolder} \
                  --phaseone=${PhaseEncodeOne} \
                  --phasetwo=${PhaseEncodeTwo} \
                  --unwarpdir=${UnwarpDir} \
                  --echospacing=${EchoSpacing_fMRI} \
                  --out=${txtfname}

elif [ ! -e $DCFolder/${topupFolderName}/acqparams.txt ]; then

    #TOPUP is not active
    txtfname=${EddyFolder}/acqparams.txt

    ${BRC_FMRI_SCR}/Generate_Parameter_File.sh \
                  --workingdir=${EddyFolder} \
                  --phaseone=${PhaseEncodeOne} \
                  --phasetwo=${PhaseEncodeTwo} \
                  --unwarpdir=${UnwarpDir} \
                  --echospacing=${EchoSpacing} \
                  --out=${txtfname}
else
    txtfname=$DCFolder/${topupFolderName}/acqparams.txt
fi


#Final_EchoSpacing=${EchoSpacing}
#if [ $EchoSpacing_fMRI != 0.0 ]; then
#    echo $Final_EchoSpacing
#    Final_EchoSpacing=${EchoSpacing_fMRI}
#fi
#
#if [ $EchoSpacing_fMRI != 0.0 ] || [ ! -e $DCFolder/FieldMap/acqparams.txt ]; then
#
#    # Calculate the readout time and populate the parameter file appropriately
#    txtfname=${EddyFolder}/acqparams.txt
#
#    echo $Final_EchoSpacing
#
#    ${BRC_FMRI_SCR}/Generate_Parameter_File.sh \
#                  --workingdir=${EddyFolder} \
#                  --phaseone=${PhaseEncodeOne} \
#                  --phasetwo=${PhaseEncodeTwo} \
#                  --unwarpdir=${UnwarpDir} \
#                  --echospacing=${Final_EchoSpacing} \
#                  --out=${txtfname}
#
#else
#    txtfname=$DCFolder/FieldMap/acqparams.txt
#fi
#
#echo $txtfname

log_Msg 3 "generating index, bval, and bvec files"

dimt=`${FSLDIR}/bin/fslval $Eddy_Input dim4`

for (( i=0; i<${dimt}; i++ ))
do

    if (( $i == "${dimt} - 1" )); then

        printf "2" >> ${EddyFolder}/index.txt
        printf "0" >> ${EddyFolder}/${NameOffMRI}.bvals

    else
        printf "1 " >> ${EddyFolder}/index.txt
        printf "0 " >> ${EddyFolder}/${NameOffMRI}.bvals
    fi

done


for (( i=0; i<3; i++ ))
do
    for (( j=0; j<${dimt}; j++ ))
    do
        if (( $j == "${dimt} - 1" )); then
            if [ $i == 0 ]; then
                printf "1"
            else
                printf "0"
            fi
        else
          if [ $i == 0 ]; then
              printf "1 "
          else
              printf "0 "
          fi
        fi
    done

    printf '\n'
done >> ${EddyFolder}/${NameOffMRI}.bvecs


#Standard arguments
EDDY_arg="--imain=${Eddy_Input} --mask=${BrainMask} --index=${EddyFolder}/index.txt --acqp=$txtfname --bvecs=${EddyFolder}/${NameOffMRI}.bvecs --bvals=${EddyFolder}/${NameOffMRI}.bvals --out=${EddyFolder}/${EddyOut}"
EDDY_arg="${EDDY_arg} --data_is_shelled --very_verbose --b0_only --dont_mask_output --nvoxhp=1000"
#EDDY_arg="${EDDY_arg} --niter=5 --fwhm=10,0,0,0,0 --mporder=${MPOrder} --s2v_niter=10 --s2v_fwhm=0 --s2v_interp=trilinear --s2v_lambda=1 --mbs_niter=20 --mbs_lambda=5 --mbs_ksp=5"
EDDY_arg="${EDDY_arg} --niter=5 --fwhm=10,10,5,5,0 --mporder=${MPOrder} --s2v_niter=10 --s2v_fwhm=0 --s2v_interp=trilinear --s2v_lambda=1"

if [ ! $SliceSpec = "NONE" ] ; then
    ${MATLABpath}/matlab -nojvm -nodesktop -r "addpath('${BRC_FMRI_SCR}'); extract_slice_specifications('${SliceSpec}' , '${EddyFolder}/slspec.txt'); exit"

    if [ -e ${EddyFolder}/slspec.txt ] ; then
        EDDY_arg="${EDDY_arg} --slspec=${EddyFolder}/slspec.txt"
    else
        log_Msg 3 ""
        log_Msg 3 "WARNING: Slice Timing information does not exist in the json file"
        log_Msg 3 ""
    fi
fi

if [[ ${DCMethod} == "TOPUP" ]]; then
    EDDY_arg="${EDDY_arg} --topup=${DCFolder}/${topupFolderName}/Coefficents"
fi

log_Msg 2 "EDDY_arg: $EDDY_arg"
$FSLDIR/bin/eddy_cuda  ""$EDDY_arg""

#        --imain=${Eddy_Input} \
#        --mask=${BrainMask} \
#        --index=${EddyFolder}/index.txt \
#        --acqp=$txtfname \
#        --bvecs=${EddyFolder}/${NameOffMRI}.bvecs \
#        --bvals=${EddyFolder}/${NameOffMRI}.bvals \
#        --fwhm=10 \
#        --topup=${DCFolder}/FieldMap/Coefficents \
#        --out=${EddyFolder}/${EddyOut} \
#        --s2v_niter=10 \
#        --very_verbose \
#
#
#        --data_is_shelled \
#        --niter=1 \
#        --mporder=${MPOrder} \
#        --s2v_fwhm=0 \
#        --s2v_interp=trilinear \
#        --s2v_lambda=1 \
#        --nvoxhp=1000 \
#        --b0_only \
#        --dont_mask_output \
#        --mbs_niter=20 \
#        --mbs_lambda=5 \
#        --mbs_ksp=5
#         ""${TOPUP_arg}""
#        --slspec=${EddyFolder}/slspec.txt \
#
#--niter=10 \
#--fwhm=10,10,5,5,0,0,0 \


#     ß   --repol
#        --estimate_move_by_susceptibility \
#        --slspec=slice_order.txt \
#        --field=fieldmap_in_Hz.nii.gz \
#--b0_only=field_to_func_rigid_transform.mat \

#eddy_quad ${EddyFolder}/${EddyOut} \
#          -idx ${EddyFolder}/index.txt \
#          -par ${txtfname} \
#          -m ${BrainMask} \
#          -b ${EddyFolder}/${NameOffMRI}.bvals \
#          -g ${EddyFolder}/${NameOffMRI}.bvecs

log_Msg 3 "Extract the outputs"
${FSLDIR}/bin/fslroi ${EddyFolder}/${EddyOut} ${EddyFolder}/SBRef_dc 0 1
${FSLDIR}/bin/fslroi ${EddyFolder}/${EddyOut} ${EddyFolder}/PhaseOne_gdc_dc $(( ${dimt} - 2 )) 1
${FSLDIR}/bin/fslroi ${EddyFolder}/${EddyOut} ${EddyFolder}/PhaseTwo_gdc_dc $(( ${dimt} - 1 )) 1
${FSLDIR}/bin/fslroi ${EddyFolder}/${EddyOut} ${EddyFolder}/${EddyOut} 1 $(( ${dimt} - 3 ))


${FSLDIR}/bin/fslroi ${EddyFolder}/${EddyOut} ${OutFolder}/WarpField 0 3
${FSLDIR}/bin/fslmaths ${OutFolder}/WarpField -mul 0 ${OutFolder}/WarpField


${FSLDIR}/bin/fslmaths ${EddyFolder}/SBRef_dc -mul 0 -add 1 ${OutFolder}/Jacobian


$FSLDIR/bin/fsl_tsplot -i ${EddyFolder}/eddy_corrected.eddy_movement_rms -t 'Eddy emovement RMS (mm)' -u 1 -w 640 -h 144 -a absolute,relative -o ${EddyFolder}/eddy_movement_rms.png
$FSLDIR/bin/fsl_tsplot -i ${EddyFolder}/eddy_corrected.eddy_restricted_movement_rms -t 'Eddy restricted movement RMS (mm)' -u 1 -w 640 -h 144 -a absolute,relative -o ${EddyFolder}/eddy_restricted_movement_rms.png


$FSLDIR/bin/fslmodhd ${EddyFolder}/${EddyOut} pixdim4 $TR_vol
$FSLDIR/bin/fslmodhd ${EddyFolder}/SBRef_dc pixdim4 $TR_vol
$FSLDIR/bin/fslmodhd ${EddyFolder}/PhaseOne_gdc_dc pixdim4 $TR_vol
$FSLDIR/bin/fslmodhd ${EddyFolder}/PhaseTwo_gdc_dc pixdim4 $TR_vol
$FSLDIR/bin/fslmodhd ${OutFolder}/WarpField pixdim4 $TR_vol
$FSLDIR/bin/fslmodhd ${OutFolder}/Jacobian pixdim4 $TR_vol


${FSLDIR}/bin/imcp ${EddyFolder}/SBRef_dc.nii.gz ${OutFolder}/SBRef_dc.nii.gz
${FSLDIR}/bin/imcp ${EddyFolder}/PhaseOne_gdc_dc.nii.gz ${OutFolder}/PhaseOne_gdc_dc.nii.gz
${FSLDIR}/bin/imcp ${EddyFolder}/PhaseTwo_gdc_dc.nii.gz ${OutFolder}/PhaseTwo_gdc_dc.nii.gz

log_Msg 3 ""
log_Msg 3 "           END: Eddy for correcting eddy currents and movements"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "


################################################################################################
## Cleanup
################################################################################################

${FSLDIR}/bin/imrm ${EddyFolder}/PhaseOne
${FSLDIR}/bin/imrm ${EddyFolder}/PhaseTwo
if [ -e ${EddyFolder}/SBref_${NameOffMRI}_SE_Neg_Pos ] ; then
    ${FSLDIR}/bin/imrm ${EddyFolder}/SBref_${NameOffMRI}_SE_Neg_Pos
fi
if [ -e ${EddyFolder}/${NameOffMRI}_SE_Neg_Pos ] ; then
    ${FSLDIR}/bin/imrm ${EddyFolder}/${NameOffMRI}_SE_Neg_Pos
fi
#if [ -e ${EddyFolder}/SBref_${NameOffMRI} ] ; then
#    ${FSLDIR}/bin/imrm ${EddyFolder}/SBref_${NameOffMRI}
#fi
#${FSLDIR}/bin/imrm ${EddyFolder}/SE_Neg_Pos
