#!/bin/sh
#
#   Moises Hernandez-Fernandez - FMRIB Image Analysis Group
#
#   Copyright (C) 2004 University of Oxford
#
#   SHCOPYRIGHT
#
# Pipeline for fitting NODDI-Watson

if [ "x$CUDIMOT" == "x" ]; then
	echo ""
	echo "Please, set enviroment variable CUDIMOT with the path where cuDIMOT is installed"
	echo "The path must contain a bin directory with binary files, i.e. \$CUDIMOT/bin"
	echo "For instance:   export CUDA=/home/moises/CUDIMOT"
	echo ""
  exit 1
fi

bindir=${CUDIMOT}/bin

make_absolute(){
    dir=$1;
    if [ -d ${dir} ]; then
	OLDWD=`pwd`
	cd ${dir}
	dir_all=`pwd`
	cd $OLDWD
    else
	dir_all=${dir}
    fi
    echo ${dir_all}
}
Usage() {
    echo ""
    echo "Usage: Pipeline_NODDI_Watson.sh <subject_directory> [options]"
    echo ""
    echo "expects to find data and nodif_brain_mask in subject directory"
    echo ""
    echo "<options>:"
    echo "-Q (name of the GPU(s) queue, default cuda.q (defined in environment variable: FSLGECUDAQ)"
    echo "-NJOBS (number of jobs to queue, the data is divided in NJOBS parts, usefull for a GPU cluster, default 4)"
    echo "--runMCMC (if you want to run MCMC)"
    echo "-b (burnin period, default 5000)"
    echo "-j (number of jumps, default 1250)"
    echo "-s (sample every, default 25)"
    echo "--BIC_AIC (calculate BIC & AIC)"
    echo ""
    exit 1
}

[ "$1" = "" ] && Usage

modelname=NODDI_Watson
step1=GridSeach
step2=FitFractions

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${FSLDIR}/lib

subjdir=`make_absolute $1`
subjdir=`echo $subjdir | sed 's/\/$/$/g'`

echo "---------------------------------------------------------------------------------"
echo "------------------------------------ CUDIMOT ------------------------------------"
echo "----------------------------- MODEL: $modelname -----------------------------"
echo "---------------------------------------------------------------------------------"
echo subjectdir is $subjdir

start=`date +%s`

#parse option arguments
njobs=4
burnin=1000
njumps=1250
sampleevery=25
other=""
queue=""
lastStepModelOpts=""

shift
while [ ! -z "$1" ]
do
  case "$1" in
      -Q) queue="-q $2";shift;;
      -NJOBS) njobs=$2;shift;;
      -b) burnin=$2;shift;;
      -j) njumps=$2;shift;;
      -s) sampleevery=$2;shift;;
      --runMCMC) lastStepModelOpts=$lastStepModelOpts" --runMCMC";;
      --BIC_AIC) lastStepModelOpts=$lastStepModelOpts" --BIC_AIC";;
      *) other=$other" "$1;;
  esac
  shift
done

#Set options
opts="--bi=$burnin --nj=$njumps --se=$sampleevery"
opts="$opts $other"

if [ "x$SGE_ROOT" != "x" ]; then
	queue="-q $FSLGECUDAQ"
fi

#check that all required files exist

if [ ! -d $subjdir ]; then
	echo "subject directory $1 not found"
	exit 1
fi

if [ `${FSLDIR}/bin/imtest ${subjdir}/data` -eq 0 ]; then
	echo "${subjdir}/data not found"
	exit 1
fi

if [ `${FSLDIR}/bin/imtest ${subjdir}/nodif_brain_mask` -eq 0 ]; then
	echo "${subjdir}/nodif_brain_mask not found"
	exit 1
fi

if [ -e ${subjdir}.${modelname}/xfms/eye.mat ]; then
	echo "${subjdir} has already been processed: ${subjdir}.${modelname}."
	echo "Delete or rename ${subjdir}.${modelname} before repeating the process."
	exit 1
fi

echo Making output directory structure

mkdir -p ${subjdir}.${modelname}/
mkdir -p ${subjdir}.${modelname}/diff_parts
mkdir -p ${subjdir}.${modelname}/logs
mkdir -p ${subjdir}.${modelname}/Dtifit
mkdir -p ${subjdir}.${modelname}/${step1}
mkdir -p ${subjdir}.${modelname}/${step1}/diff_parts
mkdir -p ${subjdir}.${modelname}/${step1}/logs
mkdir -p ${subjdir}.${modelname}/${step2}
mkdir -p ${subjdir}.${modelname}/${step2}/diff_parts
mkdir -p ${subjdir}.${modelname}/${step2}/logs
part=0

echo Copying files to output directory

${FSLDIR}/bin/imcp ${subjdir}/nodif_brain_mask ${subjdir}.${modelname}
if [ `${FSLDIR}/bin/imtest ${subjdir}/nodif` = 1 ] ; then
    ${FSLDIR}/bin/fslmaths ${subjdir}/nodif -mas ${subjdir}/nodif_brain_mask ${subjdir}.${modelname}/nodif_brain
fi

# Specify Common Fixed Parameters
CFP_file=$subjdir.${modelname}/CFP
cp ${subjdir}/bvecs $subjdir.${modelname}
cp ${subjdir}/bvals $subjdir.${modelname}
echo  $subjdir.${modelname}/bvecs > $CFP_file
echo  $subjdir.${modelname}/bvals >> $CFP_file

#Set more options
opts=$opts" --data=${subjdir}/data --maskfile=$subjdir.${modelname}/nodif_brain_mask --forcedir --CFP=$CFP_file"

# Calculate S0 with the mean of the volumes with bval<50
bvals=`cat ${subjdir}/bvals`
mkdir -p ${subjdir}.${modelname}/temporal
pos=0
for i in $bvals; do
    if [ $i -le 50 ]; then
       	fslroi ${subjdir}/data  ${subjdir}.${modelname}/temporal/volume_$pos $pos 1
    fi
    pos=$(($pos + 1))
done
fslmerge -t ${subjdir}.${modelname}/temporal/S0s ${subjdir}.${modelname}/temporal/volume*
fslmaths ${subjdir}.${modelname}/temporal/S0s -Tmean ${subjdir}.${modelname}/S0
rm -rf ${subjdir}.${modelname}/temporal

# Specify Fixed parameters: S0
FixPFile=${subjdir}.${modelname}/FixP
echo ${subjdir}.${modelname}/S0 >> $FixPFile

##############################################################################
################################ First Dtifit  ###############################
##############################################################################
echo "Queue Dtifit"
PathDTI=${subjdir}.${modelname}/Dtifit
dtifit_command="${bindir}/Run_dtifit.sh ${subjdir} ${subjdir}.${modelname} ${bindir}"
#SGE
dtifitProcess=`${FSLDIR}/bin/fsl_sub $queue -l $PathDTI/logs -N dtifit $dtifit_command`

##### Model Parameters: fiso, fintra, kappa, th, ph  ######
#############################################################
##################### Grid Search Step ######################
#############################################################
echo "Queue GridSearch process"
PathStep1=$subjdir.${modelname}/${step1}

# Create file to specify initialisation parameters (2 parameters: th,ph)
InitializationFile=$PathStep1/InitializationParameters
echo "" > $InitializationFile #fiso
echo "" >> $InitializationFile #fintra
echo "" >> $InitializationFile #kappa
echo ${PathDTI}/dtifit_V1_th.nii.gz >> $InitializationFile #th
echo ${PathDTI}/dtifit_V1_ph.nii.gz >> $InitializationFile #ph

# Do GridSearch (fiso,fintra,kappa)
GridFile=$PathStep1/GridSearch
echo "search[0]=(0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0)" > $GridFile #fiso
echo "search[1]=(0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0)" >> $GridFile #fintra
echo "search[2]=(1,2,3,4,5,6,7,8)" >> $GridFile #kappa

partsdir=$PathStep1/diff_parts
outputdir=$PathStep1
Step1Opts=$opts" --outputdir=$outputdir --partsdir=$partsdir --FixP=$FixPFile --gridSearch=$GridFile --no_LevMar --init_params=$InitializationFile --fixed=3,4"

postproc=`${bindir}/jobs_wrapper.sh $PathStep1 $dtifitProcess $modelname GS $njobs $Step1Opts`

###############################################################
##################### Fit only Fractions ######################
###############################################################
echo "Queue Fitting Fractions process"
PathStep2=$subjdir.${modelname}/${step2}

# Create file to specify initialisation parameters (2 parameters: fiso,fintra)
InitializationFile=$PathStep2/InitializationParameters
echo $PathStep1/Param_0_samples > $InitializationFile #fiso
echo $PathStep1/Param_1_samples >> $InitializationFile #fintra
echo $PathStep1/Param_2_samples >> $InitializationFile #kappa
echo ${PathDTI}/dtifit_V1_th.nii.gz >> $InitializationFile #th
echo ${PathDTI}/dtifit_V1_ph.nii.gz >> $InitializationFile #ph

partsdir=$PathStep2/diff_parts
outputdir=$PathStep2
Step2Opts=$opts" --outputdir=$outputdir --partsdir=$partsdir --FixP=$FixPFile --init_params=$InitializationFile --fixed=2,3,4"

postproc=`${bindir}/jobs_wrapper.sh $PathStep2 $postproc $modelname FitFractions $njobs $Step2Opts`

######################################################################################
######################### Fit all the parameters of the Model ########################
######################################################################################
echo "Queue Fitting process"

# Create file to specify initialization parameters (5 parameters: fiso,fintra,kappa,th,ph)
InitializationFile=$subjdir.${modelname}/InitializationParameters
echo $PathStep2/Param_0_samples > $InitializationFile #fiso
echo $PathStep2/Param_1_samples >> $InitializationFile #fintra
echo ${PathStep1}/Param_2_samples >> $InitializationFile #kappa
echo ${PathDTI}/dtifit_V1_th.nii.gz >> $InitializationFile #th
echo ${PathDTI}/dtifit_V1_ph.nii.gz  >> $InitializationFile #ph

partsdir=${subjdir}.${modelname}/diff_parts
outputdir=${subjdir}.${modelname}
ModelOpts=$opts" --outputdir=$outputdir --partsdir=$partsdir --FixP=$FixPFile --init_params=$InitializationFile $lastStepModelOpts"

postproc=`${bindir}/jobs_wrapper.sh ${subjdir}.${modelname} $postproc $modelname FitProcess $njobs $ModelOpts`

#########################################
### Calculate Dispersion Index & dyads ###
##########################################
finish_command="${bindir}/${modelname}_finish.sh ${subjdir}.${modelname} ${subjdir}"
#SGE
finishProcess=`${FSLDIR}/bin/fsl_sub $queue -l ${subjdir}.${modelname}/logs -N ${modelname}_finish -j ${postproc} ${finish_command}`
jobID4=`echo -e $finishProcess | awk '{ print $NF }'`
echo "jobID_4: ${jobID4}"

#jobID3=`${JOBSUBpath}/jobsub -q cpu -p 1 -s BRC_4_dMRI_${Subject} -t 00:00:05 -m 1 -w ${jobID4} -c "${BRC_DMRI_SCR}/dMRI_preproc_part_4.sh --workingdir=${subjdir}.${modelname} --datadir=${subjdir}" &`
#jobID3=`echo -e $jobID3 | awk '{ print $NF }'`
#echo "jobID_3: ${jobID3}"

endt=`date +%s`
runtime=$((endt-start))
#echo Runtime $runtime
echo Everything Queued
