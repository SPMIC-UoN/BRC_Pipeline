#!/bin/bash
# Last update: 20/05/2019

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham

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
dMRIFolder=`getopt1 "--workingdir" $@`
eddyFolder=`getopt1 "--eddyfolder" $@`
dataFolder=`getopt1 "--datafolder" $@`
CombineMatched=`getopt1 "--combinematched" $@`
Apply_Topup=`getopt1 "--applytopup" $@`
do_REG=`getopt1 "--doreg" $@`
do_TBSS=`getopt1 "--dotbss" $@`
tbssFolder=`getopt1 "--tbssfolder" $@`
MultChanT1Folder=`getopt1 "--multchant1folder" $@`
SinChanT1Folder=`getopt1 "--sinchant1folder" $@`
regFolder=`getopt1 "--regfolder" $@`
T1wImage=`getopt1 "--t1" $@`
T1wRestoreImage=`getopt1 "--t1restore" $@`
T1wRestoreImageBrain=`getopt1 "--t1brain" $@`
dof=`getopt1 "--dof" $@`
dataT1Folder=`getopt1 "--datat1folder" $@`
regT1Folder=`getopt1 "--regt1folder" $@`
data2strFolder=`getopt1 "--outstr" $@`
data2stdFolder=`getopt1 "--outstd" $@`
Start_Time=`getopt1 "--start" $@`
Subject=`getopt1 "--subject" $@`
HIRES=`getopt1 "--hires" $@`
do_NODDI=`getopt1 "--donoddi" $@`
LogFile=`getopt1 "--logfile" $@`

#=====================================================================================
###                                   DO WORK
#=====================================================================================

${BRC_DMRI_SCR}/eddy_postproc.sh \
      --workingdir=${dMRIFolder} \
      --eddyfolder=${eddyFolder} \
      --datafolder=${dataFolder} \
      --combinematched=${CombineMatched} \
      --Apply_Topup=${Apply_Topup} \
      --hires=${HIRES} \
      --donoddi=${do_NODDI} \
      --logfile=${LogFile}


if [[ $do_REG == "yes" ]]; then

#    if [ `$FSLDIR/bin/imtest ${MultChanT1Folder}/T1_WM_mask` = 1 ] ; then
#        wmseg="${MultChanT1Folder}/T1_WM_mask"
#    el
    if [[ `$FSLDIR/bin/imtest ${SinChanT1Folder}/T1_WM_mask` = 1 ]]; then
        wmseg="${SinChanT1Folder}/T1_WM_mask"
    fi

    ${BRC_DMRI_SCR}/diff_reg.sh \
          --datafolder=${dataFolder} \
          --regfolder=${regFolder} \
          --t1=${T1wImage} \
          --t1restore=${T1wRestoreImage} \
          --t1brain=${T1wRestoreImageBrain} \
          --wmseg=${wmseg} \
          --dof=${dof} \
          --datat1folder=${dataT1Folder} \
          --regt1folder=${regT1Folder} \
          --outstr=${data2strFolder} \
          --outstd=${data2stdFolder} \
          --logfile=${LogFile}
fi


if [[ $do_TBSS == "yes" ]]; then

    ${BRC_DMRI_SCR}/run_tbss.sh \
        --workingdir=${dMRIFolder} \
        --tbssfolder=${tbssFolder} \
        --datafolder=${dataFolder} \
        --logfile=${LogFile}

fi


END_Time="$(date -u +%s)"


${BRCDIR}/Show_version.sh \
      --showdiff="yes" \
      --start=${Start_Time} \
      --end=${END_Time} \
      --subject=${Subject} \
      --type=2 \
      --logfile=${LogFile}
