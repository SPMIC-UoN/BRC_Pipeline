#!/bin/bash
# Last update: 06/06/2018

set -e
echo -e "\n START: data_copy"

MissingFileFlag="EMPTY" #String used in the input arguments to indicate that a complete series is missing


min(){
  if [ $1 -le $2 ]; then
     echo $1
  else
     echo $2
  fi
}

outdir=$1
InputImages=$2
InputImages2=$3
PEdir=$4


if [ ${PEdir} -eq 1 ]; then    #RL/LR phase encoding
    basePos="RL"
    baseNeg="LR"
elif [ ${PEdir} -eq 2 ]; then  #AP/PA phase encoding
    basePos="AP"
    baseNeg="PA"
fi



echo "Copying raw data"
#Copy RL/AP images to workingdir
InputImages=`echo ${InputImages} | sed 's/@/ /g'`
Pos_count=1
for Image in ${InputImages} ; do
	if [[ ${Image} =~ ^.*EMPTY$  ]]  ;
	then
		Image=�EMPTY�
	fi

    if [ ${Image} = ${MissingFileFlag} ];
    then
        PosVols[${Pos_count}]=0
    else
	PosVols[${Pos_count}]=`${FSLDIR}/bin/fslval ${Image} dim4`
	absname=`${FSLDIR}/bin/imglob ${Image}`
	${FSLDIR}/bin/imcp ${absname} ${outdir}/raw/${basePos}_${Pos_count}
	cp ${absname}.bval ${outdir}/raw/${basePos}_${Pos_count}.bval
	cp ${absname}.bvec ${outdir}/raw/${basePos}_${Pos_count}.bvec
    fi
    Pos_count=$((${Pos_count} + 1))
done

#Copy LR/PA images to workingdir
InputImages=`echo ${InputImages2} | sed 's/@/ /g'`
Neg_count=1
for Image in ${InputImages} ; do
	if [[ ${Image} =~ ^.*EMPTY$  ]]  ;
	then
		Image=�EMPTY�
	fi

    if [ ${Image} = ${MissingFileFlag} ];
    then
	NegVols[${Neg_count}]=0
    else
	NegVols[${Neg_count}]=`${FSLDIR}/bin/fslval ${Image} dim4`
	absname=`${FSLDIR}/bin/imglob ${Image}`
	${FSLDIR}/bin/imcp ${absname} ${outdir}/raw/${baseNeg}_${Neg_count}
	cp ${absname}.bval ${outdir}/raw/${baseNeg}_${Neg_count}.bval
	cp ${absname}.bvec ${outdir}/raw/${baseNeg}_${Neg_count}.bvec
    fi
    Neg_count=$((${Neg_count} + 1))
done


if [ ${Pos_count} -ne ${Neg_count} ]; then
    echo "Wrong number of input datasets! Make sure that you provide pairs of input filenames."
    echo "If the respective file does not exist, use EMPTY in the input arguments."
    exit 1
fi

#Create two files for each phase encoding direction, that for each series contains the number of corresponding volumes and the number of actual volumes.
#The file e.g. RL_SeriesCorrespVolNum.txt will contain as many rows as non-EMPTY series. The entry M in row J indicates that volumes 0-M from RLseries J
#has corresponding LR pairs. This file is used in basic_preproc to generate topup/eddy indices and extract corresponding b0s for topup.
#The file e.g. Pos_SeriesVolNum.txt will have as many rows as maximum series pairs (even unmatched pairs). The entry M N in row J indicates that the RLSeries J has its 0-M volumes corresponding to LRSeries J and RLJ has N volumes in total. This file is used in eddy_combine.
Paired_flag=0
for (( j=1; j<${Pos_count}; j++ )) ; do
    CorrVols=`min ${NegVols[${j}]} ${PosVols[${j}]}`
    echo ${CorrVols} ${PosVols[${j}]} >> ${outdir}/preprocess/eddy/Pos_SeriesVolNum.txt
    if [ ${PosVols[${j}]} -ne 0 ]; then
	echo ${CorrVols} >> ${outdir}/raw/${basePos}_SeriesCorrespVolNum.txt
	if [ ${CorrVols} -ne 0 ]; then
	    Paired_flag=1
	fi
    fi
done
for (( j=1; j<${Neg_count}; j++ )) ; do
    CorrVols=`min ${NegVols[${j}]} ${PosVols[${j}]}`
    echo ${CorrVols} ${NegVols[${j}]} >> ${outdir}/preprocess/eddy/Neg_SeriesVolNum.txt
    if [ ${NegVols[${j}]} -ne 0 ]; then
	echo ${CorrVols} >> ${outdir}/raw/${baseNeg}_SeriesCorrespVolNum.txt
    fi
done

if [ ${Paired_flag} -eq 0 ]; then
    echo "Wrong Input! No pairs of phase encoding directions have been found!"
    echo "At least one pair is needed!"
    exit 1
fi
