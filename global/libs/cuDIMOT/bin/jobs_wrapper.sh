#!/bin/sh
#
#   Moises Hernandez-Fernandez - FMRIB Image Analysis Group
#
#   Copyright (C) 2004 University of Oxford
#
#   SHCOPYRIGHT
#
#  Script to submit 3 jobs: Split_parts, FitModel, Merge_parts  

bindir=${CUDIMOT}/bin  

Usage() {
    echo ""
    echo "Usage: jobs_wrapper.sh <directory> <processID_to_Wait (can be 'none')> <modelname> <processname> <NJOBS> [options]"
    echo ""
    exit 1
}
    
[ "$5" = "" ] && Usage

queue=""
if [ "x$SGE_ROOT" != "x" ]; then
	queue="-q $FSLGECUDAQ"
fi

directory=$1
wait=""
if [ "$2" != "none" ]; then
    wait="-j $2"
fi
modelname=$3
procname=$4
njobs=$5
options=`echo "${@:6}"`

# Split the dataset into parts
partsdir=$directory/diff_parts
outputdir=$directory

PreprocOpts=$options" --idPart=0 --nParts=$njobs --logdir=$directory/logs/preProcess"
preproc_command="$bindir/split_parts_$modelname $PreprocOpts"

#SGE
preProcess=`${FSLDIR}/bin/fsl_sub $queue -l $directory/logs -N ${modelname}_${procname}_preproc $wait $preproc_command`

[ -f $directory/commands.txt ] && rm $directory/commands.txt
part=0
while [ $part -lt $njobs ]
do
    partzp=`$FSLDIR/bin/zeropad $part 4`
    
    Fitopts=$options

    echo "$bindir/$modelname --idPart=$part --nParts=$njobs --logdir=$directory/logs/${modelname}_$partzp $Fitopts" >> $directory/commands.txt
	    
    part=$(($part + 1))
done

#SGE
FitProcess=`${FSLDIR}/bin/fsl_sub $queue -l $directory/logs -N ${modelname}_${procname} -j $preProcess -t $directory/commands.txt`

PostprocOpts=$options" --idPart=0 --nParts=$njobs --logdir=$directory/logs/postProcess"
postproc_command="$bindir/merge_parts_$modelname $PostprocOpts"

#SGE
postProcess=`${FSLDIR}/bin/fsl_sub $queue -l $directory/logs -N ${modelname}_${procname}_postproc -j $FitProcess $postproc_command`
echo $postProcess
