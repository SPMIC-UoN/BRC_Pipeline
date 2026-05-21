#!/bin/bash
# Last update: 21/06/2024

# Authors: Stefan Pszczolkowski, Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
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
Inputasl=`getopt1 "--inputasl" $@`
TR=`getopt1 "--tr" $@`
TI=`getopt1 "--ti" $@`
Bolus=`getopt1 "--bolus" $@`
Cgain=`getopt1 "--cgain" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                     START: CBF quantification                          +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "Inputasl:$Inputasl"
log_Msg 2 "TR:$TR"
log_Msg 2 "TI:$TI"
log_Msg 2 "Bolus:$Bolus"
log_Msg 2 "Inputasl:$Cgain"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

tmp_folder=`mktemp -d -p /tmp cbf_quant_XXXXXXXXX`

log_Msg 3 "Performing quatification"
$FSLDIR/bin/oxford_asl -i ${Inputasl}_PWI.nii.gz \
                       -c ${Inputasl}_M0.nii.gz \
                       -o ${tmp_folder} \
                       --tr=${TR} \
                       --tis=${TI} \
                       --bolus=${Bolus} \
                       --cgain=${Cgain} \
                       --iaf=diff \
                       --ibf=rpt \
                       --casl \
                       --rpts=1 \
                       --cmethod=voxel \
                       --alpha=0.85

log_Msg 3 "Copying data and removing temporal folder"
$FSLDIR/bin/imcp ${tmp_folder}/native_space/perfusion_calib.nii.gz ${Inputasl}_CBF.nii.gz
rm -rf ${tmp_folder}

log_Msg 3 ""
log_Msg 3 "                       END: CBF quantification"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "
