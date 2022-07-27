#!/bin/bash
# Last update: 28/09/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
set -e

source $BRC_GLOBAL_SCR/log.shlib  # Logging related functions

MissingFileFlag="EMPTY" #String used in the input arguments to indicate that a complete series is missing

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

min()
{
  if [ $1 -le $2 ]; then
     echo $1
  else
     echo $2
  fi
}

# parse arguments
dMRIrawFolder=`getopt1 "--dmrirawfolder" $@`
eddyFolder=`getopt1 "--eddyfolder" $@`
InputImages=`getopt1 "--inputimage" $@`
InputImages2=`getopt1 "--inputimage2" $@`
PEdir=`getopt1 "--pedirection" $@`
Apply_Topup=`getopt1 "--applytopup" $@`
do_NODDI=`getopt1 "--donoddi" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                          START: Data Handling                          +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "dMRIrawFolder:$dMRIrawFolder"
log_Msg 2 "eddyFolder:$eddyFolder"
log_Msg 2 "InputImages:$InputImages"
log_Msg 2 "InputImages2:$InputImages2"
log_Msg 2 "PEdir:$PEdir"
log_Msg 2 "Apply_Topup:$Apply_Topup"
log_Msg 2 "do_NODDI:$do_NODDI"
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

log_Msg 3 "Copying raw data"

#Copy RL/AP images to workingdir
InputImages=`echo ${InputImages} | sed 's/@/ /g'`
Pos_count=1

#echo "InputImages: ${InputImages}"

for Image in ${InputImages} ; do
    if [[ ${Image} =~ ^.*EMPTY$  ]]  ;
    then
		    Image="EMPTY"
    fi

    if [ ${Image} = ${MissingFileFlag} ];
    then
        PosVols[${Pos_count}]=0
    else
	      PosVols[${Pos_count}]=`${FSLDIR}/bin/fslval ${Image} dim4`
        absname=`${FSLDIR}/bin/imglob ${Image}`

        if [[ ${do_NODDI} == "yes" ]]; then

            bvalues=`cat ${absname}.bval`
#            echo "bvalues: $bvalues"

            Shells=($(echo ${bvalues[@]} | tr ' ' '\n' | sort -nu))
            Shells=${Shells[@]}
#            echo "Shells: $Shells"

            Shell_0000=0
            Shell_1000=0
            Shell_2000=0
            for i in ${Shells}; do
                if [ $i -ge 2000 ]; then
                    Shell_2000=$(($Shell_2000 + 1))
                elif [ $i -ge 1000 ]; then
                    Shell_1000=$(($Shell_1000 + 1))
                elif [ $i -lt 1000 ]; then
                    Shell_0000=$(($Shell_0000 + 1))
                fi
            done

#            echo "Shell_0000: $Shell_0000"
#            echo "Shell_1000: $Shell_1000"
#            echo "Shell_2000: $Shell_2000"

            if [ ${Shell_2000} == 0 ] && [ ${Shell_1000} == 0 ]; then
                echo ""
                echo "ERROR: --noddi option is just available in multishell datasets."
                echo ""
                exit 1;
            elif [ $Shell_2000 == 0 ]; then
                echo ""
                echo "ERROR: --noddi option is just available in multi-shell datasets with highest b-shell >= 2000."
                echo ""
                exit 1;
            fi
        fi

        ${FSLDIR}/bin/imcp ${absname} ${dMRIrawFolder}/${basePos}_${Pos_count}
        cp ${absname}.bval ${dMRIrawFolder}/${basePos}_${Pos_count}.bval
        cp ${absname}.bvec ${dMRIrawFolder}/${basePos}_${Pos_count}.bvec
    fi

    Pos_count=$((${Pos_count} + 1))
done

if [ $Apply_Topup = yes ] ; then
    #Copy LR/PA images to workingdir
    InputImages=`echo ${InputImages2} | sed 's/@/ /g'`
    Neg_count=1

    for Image in ${InputImages} ; do
        if [[ ${Image} =~ ^.*EMPTY$  ]]  ;
        then
            Image="EMPTY"
            echo "Image: $Image"
      	fi

        if [ ${Image} = ${MissingFileFlag} ];
        then
    	     NegVols[${Neg_count}]=0
        else
           NegVols[${Neg_count}]=`${FSLDIR}/bin/fslval ${Image} dim4`
           absname=`${FSLDIR}/bin/imglob ${Image}`
           ${FSLDIR}/bin/imcp ${absname} ${dMRIrawFolder}/${baseNeg}_${Neg_count}
           cp ${absname}.bval ${dMRIrawFolder}/${baseNeg}_${Neg_count}.bval
           cp ${absname}.bvec ${dMRIrawFolder}/${baseNeg}_${Neg_count}.bvec
        fi

        Neg_count=$((${Neg_count} + 1))
    done
else
    Neg_count=1
    NegVols[${Neg_count}]=0
    Neg_count=$((${Neg_count} + 1))
fi

log_Msg 3 "Copying raw data"

if [ $Apply_Topup = yes ] ; then
    if [ ${Pos_count} -ne ${Neg_count} ]; then
        log_Msg 3 ""
        log_Msg 3 "Wrong number of input datasets! Make sure that you provide pairs of input filenames."
        log_Msg 3 "If the respective file does not exist, use EMPTY in the input arguments."
        log_Msg 3 ""
        exit 1
    fi
fi

#Create two files for each phase encoding direction, that for each series contains the number of corresponding volumes and the number of actual volumes.
#The file e.g. RL_SeriesCorrespVolNum.txt will contain as many rows as non-EMPTY series. The entry M in row J indicates that volumes 0-M from RLseries J
#has corresponding LR pairs. This file is used in basic_preproc to generate topup/eddy indices and extract corresponding b0s for topup.
#The file e.g. Pos_SeriesVolNum.txt will have as many rows as maximum series pairs (even unmatched pairs). The entry M N in row J indicates that the RLSeries J has its 0-M volumes corresponding to LRSeries J and RLJ has N volumes in total. This file is used in eddy_combine.
Paired_flag=0

for (( j=1; j<${Pos_count}; j++ )) ; do
    CorrVols=`min ${NegVols[${j}]} ${PosVols[${j}]}`
    echo ${CorrVols} ${PosVols[${j}]} >> ${eddyFolder}/Pos_SeriesVolNum.txt

    if [ ${PosVols[${j}]} -ne 0 ]; then
      	echo ${CorrVols} >> ${dMRIrawFolder}/${basePos}_SeriesCorrespVolNum.txt
      	if [ ${CorrVols} -ne 0 ]; then
      	    Paired_flag=1
      	fi
    fi
done

for (( j=1; j<${Neg_count}; j++ )) ; do
    CorrVols=`min ${NegVols[${j}]} ${PosVols[${j}]}`
    echo ${CorrVols} ${NegVols[${j}]} >> ${eddyFolder}/Neg_SeriesVolNum.txt

    if [ ${NegVols[${j}]} -ne 0 ]; then
      	echo ${CorrVols} >> ${dMRIrawFolder}/${baseNeg}_SeriesCorrespVolNum.txt
    fi
done

if [ $Apply_Topup = yes ] ; then
    if [ ${Paired_flag} -eq 0 ]; then
        log_Msg 3 ""
        log_Msg 3 "Wrong Input! No pairs of phase encoding directions have been found!"
        log_Msg 3 "At least one pair is needed!"
        log_Msg 3 ""
        exit 1
    fi
fi

log_Msg 3 ""
log_Msg 3 "                            END: Data Handling"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################
