#!/bin/bash
# Last update: 15/10/2021

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham

set -e

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
NoddiFolder=`getopt1 "--workingdir" $@`
Datadir=`getopt1 "--datadir" $@`

#=====================================================================================
###                                   DO WORK
#=====================================================================================

if [ ! -d ${Datadir}/"data.dti" ]; then mkdir ${Datadir}/"data.dti"; fi
if [ ! -d ${Datadir}/"data.noddi" ]; then mkdir ${Datadir}/"data.noddi"; fi

${FSLDIR}/bin/immv ${NoddiFolder}/Dtifit/dtifit_FA ${Datadir}/"data.dti"/dti_FA
${FSLDIR}/bin/immv ${NoddiFolder}/Dtifit/dtifit_L1 ${Datadir}/"data.dti"/dti_L1
${FSLDIR}/bin/immv ${NoddiFolder}/Dtifit/dtifit_L2 ${Datadir}/"data.dti"/dti_L2
${FSLDIR}/bin/immv ${NoddiFolder}/Dtifit/dtifit_L3 ${Datadir}/"data.dti"/dti_L3
${FSLDIR}/bin/immv ${NoddiFolder}/Dtifit/dtifit_V1 ${Datadir}/"data.dti"/dti_V1
${FSLDIR}/bin/immv ${NoddiFolder}/Dtifit/dtifit_V2 ${Datadir}/"data.dti"/dti_V2
${FSLDIR}/bin/immv ${NoddiFolder}/Dtifit/dtifit_V3 ${Datadir}/"data.dti"/dti_V3
${FSLDIR}/bin/immv ${NoddiFolder}/Dtifit/dtifit_MD ${Datadir}/"data.dti"/dti_MD
${FSLDIR}/bin/immv ${NoddiFolder}/Dtifit/dtifit_MO ${Datadir}/"data.dti"/dti_MO
${FSLDIR}/bin/immv ${NoddiFolder}/Dtifit/dtifit_S0 ${Datadir}/"data.dti"/dti_S0
${FSLDIR}/bin/immv ${NoddiFolder}/Dtifit/dtifit_tensor ${Datadir}/"data.dti"/dti_tensor

${FSLDIR}/bin/immv ${NoddiFolder}/OD ${Datadir}/"data.noddi"/NODDI_ODI
${FSLDIR}/bin/immv ${NoddiFolder}/mean_fintra ${Datadir}/"data.noddi"/NODDI_ICVF
${FSLDIR}/bin/immv ${NoddiFolder}/mean_fiso ${Datadir}/"data.noddi"/NODDI_ISOVF

rm -r ${NoddiFolder}
