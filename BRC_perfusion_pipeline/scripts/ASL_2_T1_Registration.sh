#!/bin/bash
# Last update: 12/07/2021

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
WD=`getopt1 "--workingdir" $@`
Inputasl=`getopt1 "--inputasl" $@`
InputT1=`getopt1 "--inputt1" $@`
NameOfaslMRI=`getopt1 "--aslname" $@`
WMseg=`getopt1 "--wmseg" $@`
WMpve=`getopt1 "--wmpve" $@`
GMpve=`getopt1 "--gmpve" $@`
dof=`getopt1 "--dof" $@`
superlevel=`getopt1 "--superlevel" $@`
aslMRI2strOutputTransform=`getopt1 "--owarp" $@`
str2aslMRIOutputTransform=`getopt1 "--oinwarp" $@`
aslMRI2StandardTransform=`getopt1 "--outasl2stdtrans" $@`
Standard2aslMRITransform=`getopt1 "--outstd2asltrans" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                   START: ASL to T1 Registration                        +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "Inputasl:$Inputasl"
log_Msg 2 "NameOfaslMRI:$NameOfaslMRI"
log_Msg 2 "WMseg:$WMseg"
log_Msg 2 "WMpve:$WMpve"
log_Msg 2 "GMpve:$GMpve"
log_Msg 2 "dof:$dof"
log_Msg 2 "superlevel:$superlevel"
log_Msg 2 "aslMRI2strOutputTransform:$aslMRI2strOutputTransform"
log_Msg 2 "str2aslMRIOutputTransform:$str2aslMRIOutputTransform"
log_Msg 2 "aslMRI2StandardTransform:$aslMRI2StandardTransform"
log_Msg 2 "Standard2aslMRITransform:$Standard2aslMRITransform"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 3 "Registering ASL to bias corrected brain extracted T1"
$FSLDIR/bin/flirt -in ${Inputasl} \
                  -ref ${InputT1} \
                  -omat ${WD}/${aslMRI2strOutputTransform} \
				  -wmseg ${WMseg} \
                  -dof ${dof} \
				  -cost bbr \
				  -searchcost bbr

log_Msg 3 "Computing structural to ASL warp"
$FSLDIR/bin/convert_xfm -omat ${WD}/${str2aslMRIOutputTransform} \
                        -inverse ${WD}/${aslMRI2strOutputTransform}

log_Msg 3 "Applying warp to structural grey matter partial volume estimation"
$FSLDIR/bin/applywarp -i ${GMpve} \
                      -r ${Inputasl} \
                      -o ${WD}/T1_pve_GM_${NameOfaslMRI}.nii.gz \
                      --premat=${WD}/${str2aslMRIOutputTransform} \
                      --super \
                      --superlevel=${superlevel} \
                      --interp=spline

log_Msg 3 "Applying warp to structural white matter partial volume estimation"
$FSLDIR/bin/applywarp -i ${WMpve} \
                      -r ${Inputasl} \
                      -o ${WD}/T1_pve_WM_${NameOfaslMRI}.nii.gz \
                      --premat=${WD}/${str2aslMRIOutputTransform} \
                      --super \
                      --superlevel=${superlevel} \
                      --interp=spline

log_Msg 3 ""
log_Msg 3 "                       END: ASL to T1 Registration"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

