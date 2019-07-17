#!/bin/bash
# Last update: 07/05/2019

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

################################################## OPTION PARSING #####################################################

# parse arguments
WD=`getopt1 "--workingdir" $@`
InfMRI=`getopt1 "--infmri" $@`
MotionParam=`getopt1 "--motionparam" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+         START: Performing Quality Control and Outlier Detection        +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "InfMRI:$InfMRI"
log_Msg 2 "MotionParam:$MotionParam"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

mkdir -p $WD
########################################## DO WORK ##########################################

if [ $CLUSTER_MODE = "YES" ] ; then

    matlab -nodesktop -r "addpath('${BRC_FMRI_SCR}'); \
                                        run_QC_analysis('${DVARSpath}' , \
                                        '${BRC_GLOBAL_DIR}' , \
                                        '${WD}' , \
                                        '${InfMRI}' , \
                                        '${MotionParam}'); \
                                        exit"

else

    ${MATLABpath}/matlab -nodesktop -r "addpath('${BRC_FMRI_SCR}'); \
                                        run_QC_analysis('${DVARSpath}' , \
                                        '${BRC_GLOBAL_DIR}' , \
                                        '${WD}' , \
                                        '${InfMRI}' , \
                                        '${MotionParam}'); \
                                        exit"

fi

echo 'DVARS.mat:      a vector of size 1xT-1 of classic DVARS measure' > ${WD}/readme.txt
echo 'DVARS_Stat.mat: a structure contains all the details of the statistical inference' >> ${WD}/readme.txt
echo '                including the standardised DVARS, pvals and further summary stats.' >> ${WD}/readme.txt
echo 'V.mat:          Structure contains the variance components:' >> ${WD}/readme.txt
echo '                V.{A,S,D,E}var:    time series of var components' >> ${WD}/readme.txt
echo '                V.w_{A,S,D,E}var:  sum of mean squared of components' >> ${WD}/readme.txt
echo '                V.g_{A,S,D,E}var:  sum of mean squared of global components' >> ${WD}/readme.txt
echo '                V.ng_{A,S,D,E}var: sum of mean squared of non-global components' >> ${WD}/readme.txt
echo 'DSE_Stat.mat:   Structure contains the higher level parameters of the comps:' >> ${WD}/readme.txt
echo '                Stat.Labels:    Labels indicating the order of next vars' >> ${WD}/readme.txt
echo '                Stat.SS:        Sum-squared' >> ${WD}/readme.txt
echo '                Stat.MS:        Mean-squared' >> ${WD}/readme.txt
echo '                Stat.RMS:       Root-Mean-Squared' >> ${WD}/readme.txt
echo '                Stat.Prntg:     Percentage of the whole variance' >> ${WD}/readme.txt
echo '                Stat.RelVar:    Percentage of the whole variance relative to the iid case.' >> ${WD}/readme.txt
echo '                Stat.DeltapDvar: \Delta\%D-var' >> ${WD}/readme.txt
echo '                Stat.pDvar:      \%D-var' >> ${WD}/readme.txt
echo '                Stat.DeltapSvar: \Delta\%S-var' >> ${WD}/readme.txt
echo '                Stat.pSvar:      \%S-var' >> ${WD}/readme.txt
echo 'FDts.mat:       Frame-Wise Displacement' >> ${WD}/readme.txt
echo 'FD_Stat.mat:    ' >> ${WD}/readme.txt
echo '                Stat.SS             : Sum of square of the movements.' >> ${WD}/readme.txt
echo '                Stat.FD_0{2,5}_Idx  : Index of scans exceeding the 0.2/0.5mm threshold' >> ${WD}/readme.txt
echo '                Stat.FD_0{2,5}_p    : % of the scans explained above' >> ${WD}/readme.txt
echo '                Stat.AbsRot         : Absolute sum of rotation dip' >> ${WD}/readme.txt
echo '                Stat.AbsTrans       : Absolute sum of translational disp' >> ${WD}/readme.txt
echo '                Stat.AbsRot & Stat.AbsRot : Absolute sum of one-lag difference' >> ${WD}/readme.txt
echo 'Idx.txt         The index of significant DVARS spikes' >> ${WD}/readme.txt
echo 'DVARSreg.txt    a binary regressor, where the significant DVARS data-points are 1 and the remaining data-points are 0' >> ${WD}/readme.txt

#if [ X$InMask == X ] ; then
#    log_Msg 3 "Generating mask for outlier detection"
#
#    mask=${WD}/mask
#    thr2=`$FSLDIR/bin/fslstats $InfMRI -P 2`;
#    thr98=`$FSLDIR/bin/fslstats $InfMRI -P 98`;
#    robthr=`echo "$thr2 + 0.1 * ( $thr98 - $thr2 )" | bc -l`;
#    $FSLDIR/bin/fslmaths $InfMRI -Tmean -thr $robthr -bin $mask
#else
#    mask=${InMask}
#fi
#
#
#log_Msg 3 "Outlier detection"
#${FSLDIR}/bin/fsl_motion_outliers \
#      -i ${InfMRI} \
#      -o ${WD}/mc_regressors \
#      -m ${mask} \
#      -s ${WD}/outvalues \
#      -p ${WD}/outplot \
#      --dvars \
#      --nomoco \
#      -v

log_Msg 3 ""
log_Msg 3 "           END: Performing Quality Control and Outlier Detection"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################
