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

isodd()
{
    echo "$(( $1 % 2 ))"
}

# parse arguments
rawdir=`getopt1 "--dmrirawfolder" $@`
topupdir=`getopt1 "--topupfolder" $@`
eddydir=`getopt1 "--eddyfolder" $@`
echo_spacing=`getopt1 "--echospacing" $@`
PEdir=`getopt1 "--pedir" $@`
b0dist=`getopt1 "--b0dist" $@`
b0maxbval=`getopt1 "--b0maxbval" $@`
GRAPPA=`getopt1 "--pifactor" $@`
Apply_Topup=`getopt1 "--applytopup" $@`
do_MPPCA=`getopt1 "--domppca" $@`
do_UNRING=`getopt1 "--dounring" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                       START: Basic Preprocessing                       +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "rawdir:$rawdir"
log_Msg 2 "topupdir:$topupdir"
log_Msg 2 "eddydir:$eddydir"
log_Msg 2 "echo_spacing:$echo_spacing"
log_Msg 2 "PEdir:$PEdir"
log_Msg 2 "b0dist:$b0dist"
log_Msg 2 "b0maxbval:$b0maxbval"
log_Msg 2 "GRAPPA:$GRAPPA"
log_Msg 2 "Apply_Topup:$Apply_Topup"
log_Msg 2 "do_MPPCA:$do_MPPCA"
log_Msg 2 "do_UNRING:$do_UNRING"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 3 `date`

if [ ${PEdir} -eq 1 ]; then    #RL/LR phase encoding
    basePos="RL"
    baseNeg="LR"
elif [ ${PEdir} -eq 2 ]; then  #AP/PA phase encoding
    basePos="AP"
    baseNeg="PA"
fi

#Compute Total_readout in secs with up to 6 decimal places
any=`ls ${rawdir}/${basePos}*.nii* |head -n 1`
if [ ${PEdir} -eq 1 ]; then    #RL/LR phase encoding
    dimP=`${FSLDIR}/bin/fslval ${any} dim1`
elif [ ${PEdir} -eq 2 ]; then  #AP/PA phase encoding
    dimP=`${FSLDIR}/bin/fslval ${any} dim2`
fi

nPEsteps=$(($dimP - 1))                         #If GRAPPA is used this needs to include the GRAPPA factor!
#Total_readout=Echo_spacing*(#of_PE_steps-1)
ro_time=`echo "scale=6; ${echo_spacing} / ${GRAPPA} * ${nPEsteps} " | bc -l`
log_Msg 3 "Total readout time is $ro_time secs"

if [ $Apply_Topup = yes ] ; then
    Files="${rawdir}/${basePos}*.nii* ${rawdir}/${baseNeg}*.nii*"
else
    Files="${rawdir}/${basePos}*.nii*"
fi

################################################################################################
## denoising
################################################################################################

if [[ ${do_MPPCA} == "yes" ]]; then

    log_Msg 3 "Denoising using MP-PCA approach"

    if [ ${CLUSTER_MODE} = "YES" ] ; then
        module load brcpython-img
    else
        module load brcpython
    fi

    ${FSLDIR}/bin/fslmerge -t ${rawdir}/data `echo ${Files}`

    python ${BRC_DMRI_SCR}/run_DKI.py ${rawdir} ${do_MPPCA} "no" "no" "no" "no"

    total_vol=0
    for entry in ${Files}  #For each series, get the mean b0 and rescale to match the first series baseline
    do
        basename=`imglob ${entry}`
        echo ${basename}

        dimt=`${FSLDIR}/bin/fslval ${basename} dim4`
        ${FSLDIR}/bin/fslroi ${rawdir}/data_denoised ${basename} ${total_vol} ${dimt}

        total_vol=$((${total_vol} + ${dimt}))
    done

    $FSLDIR/bin/imrm ${rawdir}/data
    $FSLDIR/bin/imrm ${rawdir}/data_denoised
fi

################################################################################################
## Unringing
################################################################################################

if [[ ${do_UNRING} == "yes" ]]; then

    log_Msg 3 "Unringing ..."

    for entry in ${Files}  #For each series, get the mean b0 and rescale to match the first series baseline
    do
        basename=`imglob ${entry}`
        echo ${basename}

        mrdegibbs "${basename}.nii.gz" "${basename}_unring.nii.gz"

        # $FSLDIR/bin/fslchfiletype ${basename}_unring.nii.gz ${basename}_unring.nii.gz
        $FSLDIR/bin/imrm  "${basename}.nii.gz"
        $FSLDIR/bin/immv  "${basename}_unring.nii.gz" "${basename}.nii.gz"
        $FSLDIR/bin/imrm  "${basename}_unring.nii.gz"

    done

fi

################################################################################################
## Intensity Normalisation across Series
################################################################################################

log_Msg 3 "Rescaling series to ensure consistency across baseline intensities"

entry_cnt=0
for entry in ${Files}  #For each series, get the mean b0 and rescale to match the first series baseline
do
    basename=`imglob ${entry}`

    ${FSLDIR}/bin/fslmaths ${basename} -mul 1 ${basename} -odt float   # conversion of all input files to the same datatype to ensure consistency

    log_Msg 3 "Processing $basename"
    ${FSLDIR}/bin/fslmaths ${entry} -Xmean -Ymean -Zmean ${basename}_mean

    Posbvals=`cat ${basename}.bval`
    mcnt=0

    for i in ${Posbvals} #extract all b0s for the series
    do
      	cnt=`$FSLDIR/bin/zeropad $mcnt 4`
      	if [ $i -lt ${b0maxbval} ]; then
      	    $FSLDIR/bin/fslroi ${basename}_mean ${basename}_b0_${cnt} ${mcnt} 1
      	fi
      	mcnt=$((${mcnt} + 1))
    done

    ${FSLDIR}/bin/fslmerge -t ${basename}_mean `echo ${basename}_b0_????.nii*`
    ${FSLDIR}/bin/fslmaths ${basename}_mean -Tmean ${basename}_mean #This is the mean baseline b0 intensity for the series
    ${FSLDIR}/bin/imrm ${basename}_b0_????

    if [ ${entry_cnt} -eq 0 ]; then      #Do not rescale the first series
        rescale=`${FSLDIR}/bin/fslmeants -i ${basename}_mean`
    else
        scaleS=`${FSLDIR}/bin/fslmeants -i ${basename}_mean`
        ${FSLDIR}/bin/fslmaths ${basename} -mul ${rescale} -div ${scaleS} ${basename}_new
        ${FSLDIR}/bin/imrm ${basename}   #For the rest, replace the original dataseries with the rescaled one
        ${FSLDIR}/bin/immv ${basename}_new ${basename}
    fi

    entry_cnt=$((${entry_cnt} + 1))
    ${FSLDIR}/bin/imrm ${basename}_mean
done

################################################################################################
## b0 extraction and Creation of Index files for topup/eddy
################################################################################################

log_Msg 3 "Extracting b0s from PE_Positive volumes and creating index and series files"

declare -i sesdimt #declare sesdimt as integer
tmp_indx=1

while read line ; do  #Read SeriesCorrespVolNum.txt file
    PCorVolNum[${tmp_indx}]=`echo $line | awk {'print $1'}`
    tmp_indx=$((${tmp_indx}+1))
done < ${rawdir}/${basePos}_SeriesCorrespVolNum.txt

scount=1
scount2=1
indcount=0

for entry in ${rawdir}/${basePos}*.nii*  #For each Pos volume
do
    #Extract b0s and create index file
    basename=`imglob ${entry}`
    Posbvals=`cat ${basename}.bval`

    count=0  #Within series counter
    count3=$((${b0dist} + 1))

    for i in ${Posbvals}
    do

        if [ $count -ge ${PCorVolNum[${scount2}]} ]; then
          	tmp_ind=${indcount}

          	if [ $[tmp_ind] -eq 0 ]; then
          	    tmp_ind=$((${indcount}+1))
          	fi
          	echo ${tmp_ind} >>${rawdir}/index.txt

        else  #Consider a b=0 a volume that has a bvalue<50 and is at least 50 volumes away from the previous
          	if [ $i -lt ${b0maxbval} ] && [ ${count3} -gt ${b0dist} ]; then
          	    cnt=`$FSLDIR/bin/zeropad $indcount 4`
          	    echo "Extracting Pos Volume $count from ${entry} as a b=0. Measured b=$i" >>${rawdir}/extractedb0.txt
          	    $FSLDIR/bin/fslroi ${entry} ${rawdir}/Pos_b0_${cnt} ${count} 1

          	    if [ ${PEdir} -eq 1 ]; then    #RL/LR phase encoding
          		      echo 1 0 0 ${ro_time} >> ${rawdir}/acqparams.txt
          	    elif [ ${PEdir} -eq 2 ]; then  #AP/PA phase encoding
          		      echo 0 1 0 ${ro_time} >> ${rawdir}/acqparams.txt
          	    fi

          	    indcount=$((${indcount} + 1))
          	    count3=0
          	fi

          	echo ${indcount} >>${rawdir}/index.txt
          	count3=$((${count3} + 1))
        fi

        count=$((${count} + 1))
    done

    #Create series file
    sesdimt=`${FSLDIR}/bin/fslval ${entry} dim4` #Number of datapoints per Pos series

    for (( j=0; j<${sesdimt}; j++ ))
    do
        echo ${scount} >> ${rawdir}/series_index.txt
    done

    scount=$((${scount} + 1))
    scount2=$((${scount2} + 1))
done

if [ ! $Apply_Topup = yes ] ; then
    count=0  #Within series counter
    indcount=0
    entry=${rawdir}/${basePos}*.nii*

    cnt=`$FSLDIR/bin/zeropad $indcount 4`
    echo "Extracting Pos Volume $count from ${entry} as a b=0. Measured b=$i" >>${rawdir}/extractedb0.txt
    $FSLDIR/bin/fslroi ${entry} ${rawdir}/Pos_b0_${cnt} ${count} 1

    if [ ${PEdir} -eq 1 ]; then    #RL/LR phase encoding
        echo 1 0 0 ${ro_time} >> ${rawdir}/acqparams.txt
    elif [ ${PEdir} -eq 2 ]; then  #AP/PA phase encoding
        echo 0 1 0 ${ro_time} >> ${rawdir}/acqparams.txt
    fi
fi

if [ $Apply_Topup = yes ] ; then
    log_Msg 3 "Extracting b0s from PE_Negative volumes and creating index and series files"
    tmp_indx=1

    while read line ; do  #Read SeriesCorrespVolNum.txt file
        NCorVolNum[${tmp_indx}]=`echo $line | awk {'print $1'}`
        tmp_indx=$((${tmp_indx}+1))
    done < ${rawdir}/${baseNeg}_SeriesCorrespVolNum.txt

    Poscount=${indcount}
    indcount=0
    scount2=1

    for entry in ${rawdir}/${baseNeg}*.nii* #For each Neg volume
    do
        #Extract b0s and create index file
        basename=`imglob ${entry}`
        Negbvals=`cat ${basename}.bval`

        count=0
        count3=$((${b0dist} + 1))

        for i in ${Negbvals}
        do
            if [ $count -ge ${NCorVolNum[${scount2}]} ]; then
            	  tmp_ind=${indcount}

            	  if [ $[tmp_ind] -eq 0 ]; then
            	      tmp_ind=$((${indcount}+1))
            	  fi

            	  echo $((${tmp_ind} + ${Poscount})) >>${rawdir}/index.txt
            else #Consider a b=0 a volume that has a bvalue<50 and is at least 50 volumes away from the previous
            	  if [ $i -lt ${b0maxbval} ] && [ ${count3} -gt ${b0dist} ]; then
            	      cnt=`$FSLDIR/bin/zeropad $indcount 4`
            	      echo "Extracting Neg Volume $count from ${entry} as a b=0. Measured b=$i" >>${rawdir}/extractedb0.txt
            	      $FSLDIR/bin/fslroi ${entry} ${rawdir}/Neg_b0_${cnt} ${count} 1

            	      if [ ${PEdir} -eq 1 ]; then    #RL/LR phase encoding
            		        echo -1 0 0 ${ro_time} >> ${rawdir}/acqparams.txt
            	      elif [ ${PEdir} -eq 2 ]; then  #AP/PA phase encoding
            		        echo 0 -1 0 ${ro_time} >> ${rawdir}/acqparams.txt
            	      fi

            	      indcount=$((${indcount} + 1))
            	      count3=0
            	  fi

            	  echo $((${indcount} + ${Poscount})) >>${rawdir}/index.txt
            	  count3=$((${count3} + 1))
            fi

            count=$((${count} + 1))
        done

        #Create series file
        sesdimt=`${FSLDIR}/bin/fslval ${entry} dim4`

        for (( j=0; j<${sesdimt}; j++ ))
        do
            echo ${scount} >> ${rawdir}/series_index.txt #Create series file
        done

        scount=$((${scount} + 1))
        scount2=$((${scount2} + 1))
    done
fi

################################################################################################
## Merging Files and correct number of slices
################################################################################################

${FSLDIR}/bin/fslmerge -t ${rawdir}/Pos_b0 `${FSLDIR}/bin/imglob ${rawdir}/Pos_b0_????.*`
${FSLDIR}/bin/imrm ${rawdir}/Pos_b0_????

if [ $Apply_Topup = yes ] ; then
    log_Msg 3 "Merging Pos and Neg images"

    ${FSLDIR}/bin/fslmerge -t ${rawdir}/Neg_b0 `${FSLDIR}/bin/imglob ${rawdir}/Neg_b0_????.*`
    ${FSLDIR}/bin/imrm ${rawdir}/Neg_b0_????

    ${FSLDIR}/bin/fslmerge -t ${rawdir}/Neg `echo ${rawdir}/${baseNeg}*.nii*`
fi

${FSLDIR}/bin/fslmerge -t ${rawdir}/Pos `echo ${rawdir}/${basePos}*.nii*`

paste `echo ${rawdir}/${basePos}*.bval` >${rawdir}/Pos.bval
paste `echo ${rawdir}/${basePos}*.bvec` >${rawdir}/Pos.bvec

if [ $Apply_Topup = yes ] ; then
    paste `echo ${rawdir}/${baseNeg}*.bval` >${rawdir}/Neg.bval
    paste `echo ${rawdir}/${baseNeg}*.bvec` >${rawdir}/Neg.bvec
fi

#dimz=`${FSLDIR}/bin/fslval ${rawdir}/Pos dim3`
#if [ `isodd $dimz` -eq 1 ];then
#    log_Msg 3 "Remove one slice from data to get even number of slices"
#
#    ${FSLDIR}/bin/fslroi ${rawdir}/Pos ${rawdir}/Posn 0 -1 0 -1 1 -1
#    ${FSLDIR}/bin/fslroi ${rawdir}/Pos_b0 ${rawdir}/Pos_b0n 0 -1 0 -1 1 -1
#
#    ${FSLDIR}/bin/imrm ${rawdir}/Pos
#    ${FSLDIR}/bin/imrm ${rawdir}/Pos_b0
#
#    ${FSLDIR}/bin/immv ${rawdir}/Posn ${rawdir}/Pos
#    ${FSLDIR}/bin/immv ${rawdir}/Pos_b0n ${rawdir}/Pos_b0
#
#    if [ $Apply_Topup = yes ] ; then
#        ${FSLDIR}/bin/fslroi ${rawdir}/Neg ${rawdir}/Negn 0 -1 0 -1 1 -1
#        ${FSLDIR}/bin/fslroi ${rawdir}/Neg_b0 ${rawdir}/Neg_b0n 0 -1 0 -1 1 -1
#
#        ${FSLDIR}/bin/imrm ${rawdir}/Neg
#        ${FSLDIR}/bin/imrm ${rawdir}/Neg_b0
#
#        ${FSLDIR}/bin/immv ${rawdir}/Negn ${rawdir}/Neg
#        ${FSLDIR}/bin/immv ${rawdir}/Neg_b0n ${rawdir}/Neg_b0
#    fi
#fi

if [ $Apply_Topup = yes ] ; then
    log_Msg 3 "Perform final merge"
    ${FSLDIR}/bin/fslmerge -t ${rawdir}/Pos_Neg_b0 ${rawdir}/Pos_b0 ${rawdir}/Neg_b0
    ${FSLDIR}/bin/fslmerge -t ${rawdir}/Pos_Neg ${rawdir}/Pos ${rawdir}/Neg
    paste ${rawdir}/Pos.bval ${rawdir}/Neg.bval >${rawdir}/Pos_Neg.bvals
    paste ${rawdir}/Pos.bvec ${rawdir}/Neg.bvec >${rawdir}/Pos_Neg.bvecs
    ${FSLDIR}/bin/imrm ${rawdir}/Neg
    ${FSLDIR}/bin/imrm ${rawdir}/Pos
fi

################################################################################################
## Move files to appropriate directories
################################################################################################

log_Msg 3 "Move files to appropriate directories"

if [ $Apply_Topup = yes ] ; then
    mv ${rawdir}/extractedb0.txt ${topupdir}
    cp ${rawdir}/acqparams.txt ${topupdir}
    ${FSLDIR}/bin/immv ${rawdir}/Pos_Neg_b0 ${topupdir}
    ${FSLDIR}/bin/immv ${rawdir}/Pos_b0 ${topupdir}
    ${FSLDIR}/bin/immv ${rawdir}/Neg_b0 ${topupdir}
fi

mv ${rawdir}/acqparams.txt ${eddydir}
mv ${rawdir}/index.txt ${eddydir}
mv ${rawdir}/series_index.txt ${eddydir}

if [ $Apply_Topup = yes ] ; then
    ${FSLDIR}/bin/immv ${rawdir}/Pos_Neg ${eddydir}
    mv ${rawdir}/Pos_Neg.bvals ${eddydir}
    mv ${rawdir}/Pos_Neg.bvecs ${eddydir}
    mv ${rawdir}/Neg.bv?? ${eddydir}
    mv ${rawdir}/Pos.bv?? ${eddydir}
else
  ${FSLDIR}/bin/immv ${rawdir}/Pos ${eddydir}
  ${FSLDIR}/bin/immv ${rawdir}/Pos_b0 ${eddydir}
  mv ${rawdir}/Pos.bv?? ${eddydir}
fi

log_Msg 3 ""
log_Msg 3 "                         END: Basic Preprocessing"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################
