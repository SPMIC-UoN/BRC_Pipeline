#!/bin/bash
# Last update: 06/06/2018

set -e
echo -e "\n START: run_topup"


workingdir=$1
topup_config_file=${FSLDIR}/etc/flirtsch/b02b0.cnf


${FSLDIR}/bin/topup --imain=${workingdir}/Pos_Neg_b0 --datain=${workingdir}/acqparams.txt --config=${topup_config_file} --fout=${workingdir}/myfield --out=${workingdir}/topup_Pos_Neg_b0 -v

dimt=`${FSLDIR}/bin/fslval ${workingdir}/Pos_b0 dim4`
dimt=$((${dimt} + 1))

echo "Applying topup to get a hifi b0"
${FSLDIR}/bin/fslroi ${workingdir}/Pos_b0 ${workingdir}/Pos_b01 0 1
${FSLDIR}/bin/fslroi ${workingdir}/Neg_b0 ${workingdir}/Neg_b01 0 1
${FSLDIR}/bin/applytopup --imain=${workingdir}/Pos_b01,${workingdir}/Neg_b01 --topup=${workingdir}/topup_Pos_Neg_b0 --datain=${workingdir}/acqparams.txt --inindex=1,${dimt} --out=${workingdir}/hifib0

${FSLDIR}/bin/imrm ${workingdir}/Pos_b0*
${FSLDIR}/bin/imrm ${workingdir}/Neg_b0*

echo "Running BET on the hifi b0"
${FSLDIR}/bin/bet ${workingdir}/hifib0 ${workingdir}/nodif_brain -m -f 0.2

echo -e "\n END: run_topup"
