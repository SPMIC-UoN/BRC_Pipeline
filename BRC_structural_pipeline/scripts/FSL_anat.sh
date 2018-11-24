#!/bin/bash
# Last update: 02/10/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
export LC_ALL=C

source $BRC_GLOBAL_SCR/log.shlib  # Logging related functions

set -e

# The following is a debugging line (displays all commands as they are executed)
# set -x

# extracts the option name from any version (-- or -)
get_opt1()
{
    arg=`echo $1 | sed 's/=.*//'`
    echo $arg
}

# get arg for -- options
get_arg1()
{
    if [ X`echo $1 | grep '='` = X ] ; then
	       echo "Option $1 requires an argument" 1>&2
         exit 1
    else
	       arg=`echo $1 | sed 's/.*=//'`
         if [ X$arg = X ] ; then
            echo "Option $1 requires an argument" 1>&2
	          exit 1
        fi
	      echo $arg
    fi
}

# get image filename from -- options
get_imarg1()
{
    arg=`get_arg1 $1`;
    arg=`$FSLDIR/bin/remove_ext $arg`;
    echo $arg
}

# get arg for - options (need to pass both $1 and $2 to this)
get_arg2()
{
    if [ X$2 = X ] ; then
      	echo "Option $1 requires an argument" 1>&2
      	exit 1
    fi
    echo $2
}

# get arg of image filenames for - options (need to pass both $1 and $2 to this)
get_imarg2()
{
    arg=`get_arg2 $1 $2`;
    arg=`$FSLDIR/bin/remove_ext $arg`;
    echo $arg
}

run()
{
    log_Msg 2 "$@"
    $@
}


quick_smooth()
{
    in=$1
    out=$2
    run $FSLDIR/bin/fslmaths $in -subsamp2 -subsamp2 -subsamp2 -subsamp2 vol16
    run $FSLDIR/bin/flirt -in vol16 -ref $in -out $out -noresampblur -applyxfm -paddingsize 16
    # possibly do a tiny extra smooth to $out here?
    run $FSLDIR/bin/imrm vol16
}

# Parse input arguments

# default values
inputimage=
imagelist=
outputname=
anatdir=
lesionmask=

strongbias=no;
do_reorient=yes;
do_crop=yes;
do_bet=yes;
do_biasrestore=yes;
do_reg=yes;
do_nonlinreg=yes;
do_seg=yes;
do_subcortseg=yes;
do_cleanup=yes;
clobber=no;
multipleimages=no;
use_lesionmask=no;
do_anat_based_on_FS=no;

nosearch=
niter=10;
smooth=20;
betfparam=0.1;
type=1  # For FAST: 1 = T1w, 2 = T2w, 3 = PD



# Parse! Parse! Parse!

if [ $# -eq 0 ] ; then Usage; exit 0; fi
if [ $# -lt 2 ] ; then Usage; exit 1; fi

while [ $# -ge 1 ] ; do
    iarg=`get_opt1 $1`;

    case "$iarg" in
      -i)     inputimage=`get_imarg2 $1 $2`;
	            shift 2
              ;;

      -o)     outputname=`get_arg2 $1 $2`;
              shift 2
              ;;

      -d)     anatdir=`get_arg2 $1 $2`;
	            shift 2
              ;;

	    -s)     smooth=`get_arg2 $1 $2`;
              shift 2
              ;;

      -m)     use_lesionmask=yes;
	            lesionmask=`get_arg2 $1 $2`;
	            shift 2
              ;;

	    -t)     typestr=`get_arg2 $1 $2`;
	            if [ $typestr = T1 ] ; then type=1; fi
	            if [ $typestr = T2 ] ; then type=2; fi
	            if [ $typestr = PD ] ; then type=3; fi
	            shift 2
              ;;

	    --list)  imagelist=`get_arg1 $1`;
	             multipleimages=yes;
	             shift
               ;;

	    --clobber)   clobber=yes;
	                 shift
                   ;;

    	--noreorient)  do_reorient=no;
	                   shift
                     ;;

      --nocrop)      do_crop=no;
                     shift
                     ;;

 	    --nobet)       do_bet=no;
                     shift
                     ;;

	    --noreg)       do_reg=no;
	                   shift
                     ;;

	   --nononlinreg)  do_nonlinreg=no;
	                   shift
                     ;;

    --noseg)         do_seg=no;
	                   shift
                     ;;

    --nosubcortseg)  do_subcortseg=no;
	                   shift
                     ;;

    --nobias)        do_biasrestore=no;
	                   shift
                     ;;

    --nosearch)      nosearch=-nosearch;
	                   shift
                     ;;

	  --strongbias)    strongbias=yes;
	                   niter=5;
	                   smooth=10;
	                   shift
                     ;;

    --weakbias)	    strongbias=no;
	                  niter=10;
	                  smooth=20;
	                  shift
                    ;;

    --betfparam)    betfparam=`get_arg1 $1`;
	                  shift
                    ;;

    --nocleanup)    do_cleanup=no;
	                  shift
                    ;;

    --anatbasedFS)  do_anat_based_on_FS=yes;
                    shift
                    ;;

    -logfile)       LogFile=`get_arg2 $1 $2`;
	                  shift 2
                    ;;

    -mridir)        mridir=`get_arg2 $1 $2`;
	                  shift 2
                    ;;

    -orig)          Orig_T1=`get_arg2 $1 $2`;
	                  shift 2
                    ;;

    -v)             verbose=yes;
              	    shift
                    ;;

    -h)             Usage;
	                  exit 0
                    ;;

    *)
  	    #if [ `echo $1 | sed 's/^\(.\).*/\1/'` = "-" ] ; then
  	    echo "Unrecognised option $1" 1>&2
  	    exit 1
  	    #fi
  	    #shift;;
    esac
done

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                     START: T1w image preprocessing                     +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "inputimage=$inputimage"
log_Msg 2 "outputname=$outputname"
log_Msg 2 anatdir=$anatdir
log_Msg 2 smooth=$smooth
log_Msg 2 use_lesionmask=$use_lesionmask
log_Msg 2 lesionmask=$lesionmask
log_Msg 2 typestr=$typestr
log_Msg 2 imagelist=$imagelist
log_Msg 2 multipleimages=$multipleimages
log_Msg 2 clobber=$clobber
log_Msg 2 do_reorient=$do_reorient
log_Msg 2 do_crop=$do_crop
log_Msg 2 do_bet=$do_bet
log_Msg 2 do_reg=$do_reg
log_Msg 2 do_nonlinreg=$do_nonlinreg
log_Msg 2 do_seg=$do_seg
log_Msg 2 do_subcortseg=$do_subcortseg
log_Msg 2 do_biasrestore=$do_biasrestore
log_Msg 2 strongbias=$strongbias
log_Msg 2 betfparam=$betfparam
log_Msg 2 do_cleanup=$do_cleanup
log_Msg 2 do_anat_based_on_FS=$do_anat_based_on_FS
log_Msg 2 LogFile=$LogFile
log_Msg 2 verbose=$verbose
log_Msg 2 mridir=$mridir
log_Msg 2 Orig_T1=$Orig_T1
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### Sanity checking of arguments

if [ X$inputimage = X ] && [ X$anatdir = X ] && [ X"$imagelist" = X ] ; then
    #echo "One of the compulsory arguments -i, -d or --list MUST be used"
    log_Msg 3 "One of the compulsory arguments -i or -d MUST be used"
    exit 1;
fi

if [ $type != 1 ] ; then
    if [ $do_nonlinreg = yes ] ; then
      	log_Msg 3 "ERROR: Cannot do non-linear registration with non-T1 images, please re-run with --nononlinreg" ;
      	exit 1;
    fi ;
    if [ $do_subcortseg = yes ] ; then
      	log_Msg 3 "ERROR: Cannot perform subcortical segmentation (with FIRST) on a non-T1 image, please re-run with --nosubcortseg"
      	exit 1;
    fi ;
fi

T1=T1;
if [ $type = 2 ] ; then T1=T2; fi
if [ $type = 3 ] ; then T1=PD; fi

betopts="-f ${betfparam}"

###### Now do some work!

# setup output directory (or go to existing one)

#if [ $do_anat_based_on_FS = yes ]; then
#    do_crop=yes
#fi

outputname=$outputname/temp;

if [ X$anatdir = X ] ; then
    if [ X${outputname} = X ] ; then
        outputname=$inputimage;
    fi

    if [ -d ${outputname}.anat ] ; then
        if [ $clobber = no ] ; then
            log_Msg 3 "ERROR: Directory ${outputname}.anat already exists!"
            exit 1;
        else
            rm -rf ${outputname}.anat
        fi
    fi
    mkdir ${outputname}.anat
else
    if [ X${inputimage} != X ] ; then
        log_Msg 3 "ERROR: Cannot specify both -d and -i";
        exit 1;
    fi

    if [ $multipleimages = yes ] ; then
        log_Msg 3 "ERROR: Cannot specify both -d and --list";
        exit 1;
    fi

    outputname=`$FSLDIR/bin/fsl_abspath $anatdir`;
    outputname=`echo $outputname | sed 's/\.anat$//'`;

    if [ ! -d ${outputname}.anat ] ; then
        log_Msg 3 "ERROR: Directory ${outputname}.anat not found"
        exit 1;
    fi

    inputimage=$anatdir/T1
fi

# some initial reporting for the log file
log_Msg 3 "Script invoked from directory = `pwd`"
log_Msg 3 "Output directory = ${outputname}.anat"

if [ $multipleimages = yes ] ; then
    if [ X${inputimage} != X ] ; then
        log_Msg 3 "ERROR: Cannot specify both -i and --list";
        exit 1;
    fi

    im1=`echo $imagelist | sed 's/,/ /g' | awk '{ print $1 }'`;

    if [ $FSLDIR/bin/imtest $im1 = 1 ] ; then
    	  # this is a comma separated list of image names
      	namelist="`echo ${imagelist} | sed 's/,/ /g'`";
    else
      	# this is a file containing the image names
      	namelist="`cat ${imagelist}`";
    fi

    for name in $namelist ; do
        if [ $FSLDIR/bin/imtest $name = 0 ] ; then
      	    log_Msg 3 "ERROR: Cannot find image $name"
      	    exit 1;
        fi

        $FSLDIR/bin/fslmaths $name ${outputname}.anat/${T1}_${num}
    done

    log_Msg 3 "Input images are ${namelist}"
else
    $FSLDIR/bin/fslmaths ${inputimage} ${outputname}.anat/${T1}
    log_Msg 3 "Input image is ${inputimage}"
fi


if [ $use_lesionmask = yes ] ; then
    $FSLDIR/bin/fslmaths $lesionmask ${outputname}.anat/lesionmask
    log_Msg 3 "Lesion mask is ${lesionmask}"
fi

cd ${outputname}.anat
log_Msg 3 " "

# now the real work

#### AVERAGING MULTIPLE SCANS
if [ $multipleimages = yes ] ; then
    date; log_Msg 3 "Averaging list of input images"

    mkdir average_dir
    run $FSLDIR/bin/AnatomicalAverage -w average_dir -o ${T1} `$FSLDIR/bin/imglob ${T1}_*`
fi

#### FIXING NEGATIVE RANGE
minval=`$FSLDIR/bin/fslstats ${T1} -p 0`;
maxval=`$FSLDIR/bin/fslstats ${T1} -p 100`;

if [ X`echo "if ( $minval < 0 ) { 1 }" | bc -l` = X1 ] ; then
    if [ X`echo "if ( $maxval > 0 ) { 1 }" | bc -l` = X1 ] ; then
      	# if there are just some negative values among the positive ones then reset zero to the min value
      	run ${FSLDIR}/bin/fslmaths ${T1} -sub $minval ${T1} -odt float
    else
      	# if all values are negative then make them positive, but retain any zeros as zeros
      	run ${FSLDIR}/bin/fslmaths ${T1} -bin -binv zeromask
      	run ${FSLDIR}/bin/fslmaths ${T1} -sub $minval -mas zeromask ${T1} -odt float
    fi
fi

#### REORIENTATION 2 STANDARD
if [ $do_reorient = yes ] ; then
    log_Msg 3 `date`
    log_Msg 3 "Reorienting to standard orientation"

    $FSLDIR/bin/fslmaths ${T1} ${T1}_orig
    $FSLDIR/bin/fslreorient2std ${T1} > ${T1}_orig2std.mat
    $FSLDIR/bin/convert_xfm -omat ${T1}_std2orig.mat -inverse ${T1}_orig2std.mat
    $FSLDIR/bin/fslreorient2std ${T1} ${T1}
fi

#### AUTOMATIC CROPPING
# required input: ${T1}
# output: ${T1} (modified) [ and ${T1}_fullfov plus various .mats ]
if [ $do_crop = yes ] ; then
    log_Msg 3 `date`
    log_Msg 3 "Automatically cropping the image"

    head_offset=0
    run $FSLDIR/bin/immv ${T1} ${T1}_fullfov

    head_top=`${FSLDIR}/bin/robustfov -i ${T1}_fullfov | grep -v Final | head -n 1 | awk '{print $5}'`
    echo "head_top=$head_top"
    head_top=`${FSLDIR}/bin/robustfov -i ${Orig_T1} | grep -v Final | head -n 1 | awk '{print $5}'`
    echo "head_top=$head_top"

    run $FSLDIR/bin/robustfov -i ${Orig_T1} -r ${T1} -m ${T1}_roi2nonroi.mat --debug | grep [0-9] | tail -1 > ${T1}_roi.log

    run cat "${T1}_roi2nonroi.mat"

    corrected_head_top=`echo "scale=0; ${head_top%%.*} - $head_offset" | bc`
    #replace ${head_top%%.*} ${corrected_head_top} -- ${T1}_roi2nonroi.mat
    tmp=$(<${T1}_roi2nonroi.mat)
    echo "${tmp//${head_top%%.*}/${corrected_head_top}}" > ${T1}_roi2nonroi.mat
    ${FSLDIR}/bin/fslroi ${T1}_fullfov ${T1} 0 -1 0 -1 $corrected_head_top 170

    run cat "${T1}_roi2nonroi.mat"

    # combine this mat file and the one above (if generated)
    if [ $do_reorient = yes ] ; then
  	     run $FSLDIR/bin/convert_xfm -omat ${T1}_nonroi2roi.mat -inverse ${T1}_roi2nonroi.mat
         run $FSLDIR/bin/convert_xfm -omat ${T1}_orig2roi.mat -concat ${T1}_nonroi2roi.mat ${T1}_orig2std.mat
         run $FSLDIR/bin/convert_xfm -omat ${T1}_roi2orig.mat -inverse ${T1}_orig2roi.mat
    fi
fi


### LESION MASK
# make appropriate (reoreinted and cropped) lesion mask (or a default blank mask to simplify the code later on)
if [ $use_lesionmask = yes ] ; then
    if [ -f ${T1}_orig2std.mat ] ; then transform=${T1}_orig2std.mat ; fi
    if [ -f ${T1}_orig2roi.mat ] ; then transform=${T1}_orig2roi.mat ; fi   # this takes precedence if both exist

    if [ X$transform != X ] ; then
        $FSLDIR/bin/fslmaths lesionmask lesionmask_orig
        $FSLDIR/bin/flirt -in lesionmask_orig -ref ${T1} -applyxfm -interp nearestneighbour -init ${transform} -out lesionmask
    fi
else
    $FSLDIR/bin/fslmaths ${T1} -mul 0 lesionmask
fi

$FSLDIR/bin/fslmaths lesionmask -bin lesionmask
$FSLDIR/bin/fslmaths lesionmask -binv lesionmaskinv


#### BIAS FIELD CORRECTION (main work, although also refined later on if segmentation run)
# required input: ${T1}
# output: ${T1}_biascorr  [ other intermediates to be cleaned up ]
if [ $do_biasrestore = yes ] ; then
    if [ $strongbias = yes ] ; then
        log_Msg 3  `date`
        log_Msg 3 "Estimating and removing field (stage 1 - large-scale fields)"

        # for the first step (very gross bias field) don't worry about the lesionmask
        # the following is a replacement for : run $FSLDIR/bin/fslmaths ${T1} -s 20 ${T1}_s20
        quick_smooth ${T1} ${T1}_s20
        run $FSLDIR/bin/fslmaths ${T1} -div ${T1}_s20 ${T1}_hpf

        if [ $do_bet = yes ] ; then
            # get a rough brain mask - it can be *VERY* rough (i.e. missing huge portions of the brain or including non-brain, but non-background) - use -f 0.1 to err on being over inclusive
            run $FSLDIR/bin/bet ${T1}_hpf ${T1}_hpf_brain -m -f 0.1
        else
            run $FSLDIR/bin/fslmaths ${T1}_hpf ${T1}_hpf_brain
            run $FSLDIR/bin/fslmaths ${T1}_hpf_brain -bin ${T1}_hpf_brain_mask
        fi

        run $FSLDIR/bin/fslmaths ${T1}_hpf_brain_mask -mas lesionmaskinv ${T1}_hpf_brain_mask
        # get a smoothed version without the edge effects
        run $FSLDIR/bin/fslmaths ${T1} -mas ${T1}_hpf_brain_mask ${T1}_hpf_s20
        quick_smooth ${T1}_hpf_s20 ${T1}_hpf_s20
        quick_smooth ${T1}_hpf_brain_mask ${T1}_initmask_s20
        run $FSLDIR/bin/fslmaths ${T1}_hpf_s20 -div ${T1}_initmask_s20 -mas ${T1}_hpf_brain_mask ${T1}_hpf2_s20
        run $FSLDIR/bin/fslmaths ${T1} -mas ${T1}_hpf_brain_mask -div ${T1}_hpf2_s20 ${T1}_hpf2_brain
        # make sure the overall scaling doesn't change (equate medians)
        med0=`$FSLDIR/bin/fslstats ${T1} -k ${T1}_hpf_brain_mask -P 50`;
        med1=`$FSLDIR/bin/fslstats ${T1}_hpf2_brain -k ${T1}_hpf_brain_mask -P 50`;
        run $FSLDIR/bin/fslmaths ${T1}_hpf2_brain -div $med1 -mul $med0 ${T1}_hpf2_brain

        log_Msg 3  `date`
        log_Msg 3 "Estimating and removing bias field (stage 2 - detailed fields)"

        run $FSLDIR/bin/fslmaths ${T1}_hpf2_brain -mas lesionmaskinv ${T1}_hpf2_maskedbrain
        run $FSLDIR/bin/fast -o ${T1}_initfast -l ${smooth} -b -B -t $type --iter=${niter} --nopve --fixed=0 -v ${T1}_hpf2_maskedbrain
        run $FSLDIR/bin/fslmaths ${T1}_initfast_restore -mas lesionmaskinv ${T1}_initfast_maskedrestore
        run $FSLDIR/bin/fast -o ${T1}_initfast2 -l ${smooth} -b -B -t $type --iter=${niter} --nopve --fixed=0 -v ${T1}_initfast_maskedrestore
        run $FSLDIR/bin/fslmaths ${T1}_hpf_brain_mask ${T1}_initfast2_brain_mask
    else
        if [ $do_bet = yes ] ; then
            # get a rough brain mask - it can be *VERY* rough (i.e. missing huge portions of the brain or including non-brain, but non-background) - use -f 0.1 to err on being over inclusive
            run $FSLDIR/bin/bet ${T1} ${T1}_initfast2_brain -m -f 0.1
        else
      	    run $FSLDIR/bin/fslmaths ${T1} ${T1}_initfast2_brain
      	    run $FSLDIR/bin/fslmaths ${T1}_initfast2_brain -bin ${T1}_initfast2_brain_mask
        fi

        run $FSLDIR/bin/fslmaths ${T1}_initfast2_brain ${T1}_initfast2_restore
    fi

    # redo fast again to try and improve bias field
    run $FSLDIR/bin/fslmaths ${T1}_initfast2_restore -mas lesionmaskinv ${T1}_initfast2_maskedrestore
    run $FSLDIR/bin/fast -o ${T1}_fast -l ${smooth} -b -B -t $type --iter=${niter} --nopve --fixed=0 -v ${T1}_initfast2_maskedrestore

    log_Msg 3  `date`
    log_Msg 3 "Extrapolating bias field from central region"
    # use the latest fast output
    run $FSLDIR/bin/fslmaths ${T1} -div ${T1}_fast_restore -mas ${T1}_initfast2_brain_mask ${T1}_fast_totbias
    run $FSLDIR/bin/fslmaths ${T1}_initfast2_brain_mask -ero -ero -ero -ero -mas lesionmaskinv ${T1}_initfast2_brain_mask2
    run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -sub 1 ${T1}_fast_totbias
    run $FSLDIR/bin/fslsmoothfill -i ${T1}_fast_totbias -m ${T1}_initfast2_brain_mask2 -o ${T1}_fast_bias
    run $FSLDIR/bin/fslmaths ${T1}_fast_bias -add 1 ${T1}_fast_bias
    run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -add 1 ${T1}_fast_totbias
    # run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -sub 1 -mas ${T1}_initfast2_brain_mask -dilall -add 1 ${T1}_fast_bias  # alternative to fslsmoothfill
    run $FSLDIR/bin/fslmaths ${T1} -div ${T1}_fast_bias ${T1}_biascorr
else
    run $FSLDIR/bin/fslmaths ${T1} ${T1}_biascorr
fi


#### REGISTRATION AND BRAIN EXTRACTION
# required input: ${T1}_biascorr
# output: ${T1}_biascorr_brain ${T1}_biascorr_brain_mask ${T1}_to_MNI_lin ${T1}_to_MNI [plus transforms, inverse transforms, jacobians, etc.]
if [ $do_reg = yes ] ; then
    if [ $do_bet != yes ] ; then
        log_Msg 3 "Skipping registration, as it requires a non-brain-extracted input image"
    else
        log_Msg 3  `date`
        log_Msg 3 "Registering to standard space (linear)"

        flirtargs="$flirtargs $nosearch"
        if [ $use_lesionmask = yes ] ; then flirtargs="$flirtargs -inweight lesionmaskinv" ; fi
        run $FSLDIR/bin/flirt -interp spline -dof 12 -in ${T1}_biascorr -ref $FSLDIR/data/standard/MNI152_${T1}_2mm -dof 12 -omat ${T1}_to_MNI_lin.mat -out ${T1}_to_MNI_lin $flirtargs

        if [ $do_nonlinreg = yes ] ; then
            log_Msg 3  `date`
            log_Msg 3 "Registering to standard space (non-linear)"

            #refmask=$FSLDIR/data/standard/MNI152_${T1}_2mm_brain_mask_dil1
            refmask=MNI152_${T1}_2mm_brain_mask_dil1
            fnirtargs=""

            if [ $use_lesionmask = yes ] ; then fnirtargs="$fnirtargs --inmask=lesionmaskinv" ; fi

            run $FSLDIR/bin/fslmaths $FSLDIR/data/standard/MNI152_${T1}_2mm_brain_mask -fillh -dilF $refmask
            run $FSLDIR/bin/fnirt --in=${T1}_biascorr --ref=$FSLDIR/data/standard/MNI152_${T1}_2mm --fout=${T1}_to_MNI_nonlin_field --jout=${T1}_to_MNI_nonlin_jac --iout=${T1}_to_MNI_nonlin --logout=${T1}_to_MNI_nonlin.txt --cout=${T1}_to_MNI_nonlin_coeff --config=$FSLDIR/etc/flirtsch/${T1}_2_MNI152_2mm.cnf --aff=${T1}_to_MNI_lin.mat --refmask=$refmask $fnirtargs

            log_Msg 3  `date`
            log_Msg 3 "Performing brain extraction (using FNIRT)"

            run $FSLDIR/bin/invwarp --ref=${T1}_biascorr -w ${T1}_to_MNI_nonlin_coeff -o MNI_to_${T1}_nonlin_field
            run $FSLDIR/bin/applywarp --interp=nn --in=$FSLDIR/data/standard/MNI152_${T1}_2mm_brain_mask --ref=${T1}_biascorr -w MNI_to_${T1}_nonlin_field -o ${T1}_biascorr_brain_mask
            run $FSLDIR/bin/fslmaths ${T1}_biascorr_brain_mask -fillh ${T1}_biascorr_brain_mask

#            if [ $do_anat_based_on_FS = yes ]; then
#               run $FSLDIR/bin/fslmaths $mridir/brainmask -thr 0.01 -bin ${T1}_biascorr_brain_mask
#            fi

            run $FSLDIR/bin/fslmaths ${T1}_biascorr -mas ${T1}_biascorr_brain_mask ${T1}_biascorr_brain
        fi

        ## In the future, could check the initial ROI extraction here
    fi
else
    if [ $do_bet = yes ] ; then
        log_Msg 3  `date`
        log_Msg 3 "Performing brain extraction (using BET)"
        run $FSLDIR/bin/bet ${T1}_biascorr ${T1}_biascorr_brain -m $betopts  ## results sensitive to the f parameter
    else
        run $FSLDIR/bin/fslmaths ${T1}_biascorr ${T1}_biascorr_brain
        run $FSLDIR/bin/fslmaths ${T1}_biascorr_brain -bin ${T1}_biascorr_brain_mask
    fi
fi

if [ $do_anat_based_on_FS = yes ]; then
    run $FSLDIR/bin/imcp ${T1}_biascorr_brain ${T1}_biascorr_brain_tmp
    run $FSLDIR/bin/imcp ${T1}_biascorr_brain_mask ${T1}_biascorr_brain_mask_tmp

    $FSLDIR/bin/flirt -ref ${T1} -in $mridir/brainmask -omat $mridir/rigid_manToFs.mat -out ${T1}_biascorr_brain -dof 12 -cost normmi -searchcost normmi
    $FSLDIR/bin/flirt -ref ${T1} -in $mridir/brainmask -out ${T1}_biascorr_brain -init $mridir/rigid_manToFs.mat -applyxfm

#    run $FSLDIR/bin/imcp $mridir/brainmask ${T1}_biascorr_brain
    run $FSLDIR/bin/fslmaths ${T1}_biascorr_brain -thr 0.01 -bin ${T1}_biascorr_brain_mask
    run $FSLDIR/bin/fslmaths ${T1}_biascorr -mas ${T1}_biascorr_brain_mask ${T1}_biascorr_brain
fi

#### TISSUE-TYPE SEGMENTATION
# required input: ${T1}_biascorr ${T1}_biascorr_brain ${T1}_biascorr_brain_mask
# output: ${T1}_biascorr ${T1}_biascorr_brain (modified) ${T1}_fast* (as normally output by fast) ${T1}_fast_bias (modified)
if [ $do_seg = yes ] ; then
    log_Msg 3  `date`
    log_Msg 3 "Performing tissue-type segmentation"

    run $FSLDIR/bin/fslmaths ${T1}_biascorr_brain -mas lesionmaskinv ${T1}_biascorr_maskedbrain
    run $FSLDIR/bin/fast -o ${T1}_fast -l ${smooth} -b -B -t $type --iter=${niter} ${T1}_biascorr_maskedbrain
    run $FSLDIR/bin/imcp ${T1}_biascorr ${T1}_biascorr_init
    run $FSLDIR/bin/fslmaths ${T1}_fast_restore ${T1}_biascorr_brain
    # extrapolate bias field and apply to the whole head image
    run $FSLDIR/bin/fslmaths ${T1}_biascorr_brain_mask -mas lesionmaskinv ${T1}_biascorr_brain_mask2
    run $FSLDIR/bin/fslmaths ${T1}_biascorr_init -div ${T1}_fast_restore -mas ${T1}_biascorr_brain_mask2 ${T1}_fast_totbias
    run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -sub 1 ${T1}_fast_totbias
    run $FSLDIR/bin/fslsmoothfill -i ${T1}_fast_totbias -m ${T1}_biascorr_brain_mask2 -o ${T1}_fast_bias
    run $FSLDIR/bin/fslmaths ${T1}_fast_bias -add 1 ${T1}_fast_bias
    run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -add 1 ${T1}_fast_totbias
    # run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -sub 1 -mas ${T1}_biascorr_brain_mask2 -dilall -add 1 ${T1}_fast_bias # alternative to fslsmoothfill

    if [ $do_anat_based_on_FS = yes ]; then
        run $FSLDIR/bin/imcp ${T1}_biascorr_init ${T1}_biascorr
    else
        run $FSLDIR/bin/fslmaths ${T1}_biascorr_init -div ${T1}_fast_bias ${T1}_biascorr
    fi

    if [ $do_nonlinreg = yes ] ; then
        # regenerate the standard space version with the new bias field correction applied
        run $FSLDIR/bin/applywarp -i ${T1}_biascorr -w ${T1}_to_MNI_nonlin_field -r $FSLDIR/data/standard/MNI152_${T1}_2mm -o ${T1}_to_MNI_nonlin --interp=spline
    fi
fi

#### SKULL-CONSTRAINED BRAIN VOLUME ESTIMATION (only done if registration turned on, and segmentation done, and it is a T1 image)
# required inputs: ${T1}_biascorr
# output: ${T1}_vols.txt
if [ $do_reg = yes ] && [ $do_seg = yes ] && [ $T1 = T1 ] ; then
    log_Msg 3  "Skull-constrained registration (linear)"

    run ${FSLDIR}/bin/bet ${T1}_biascorr ${T1}_biascorr_bet -s -m $betopts
    run ${FSLDIR}/bin/pairreg ${FSLDIR}/data/standard/MNI152_T1_2mm_brain ${T1}_biascorr_bet ${FSLDIR}/data/standard/MNI152_T1_2mm_skull ${T1}_biascorr_bet_skull ${T1}2std_skullcon.mat

    if [ $use_lesionmask = yes ] ; then
        run ${FSLDIR}/bin/fslmaths lesionmask -max ${T1}_fast_pve_2 ${T1}_fast_pve_2_plusmask -odt float
        # ${FSLDIR}/bin/fslmaths lesionmask -bin -mul 3 -max ${T1}_fast_seg ${T1}_fast_seg_plusmask -odt int
    fi

    vscale=`${FSLDIR}/bin/avscale ${T1}2std_skullcon.mat | grep Determinant | awk '{ print $3 }'`;
    ugrey=`$FSLDIR/bin/fslstats ${T1}_fast_pve_1 -m -v | awk '{ print $1 * $3 }'`;
    ngrey=`echo "$ugrey * $vscale" | bc -l`;
    uwhite=`$FSLDIR/bin/fslstats ${T1}_fast_pve_2 -m -v | awk '{ print $1 * $3 }'`;
    nwhite=`echo "$uwhite * $vscale" | bc -l`;
    ubrain=`echo "$ugrey + $uwhite" | bc -l`;
    nbrain=`echo "$ngrey + $nwhite" | bc -l`;
    echo "Scaling factor from ${T1} to MNI (using skull-constrained linear registration) = $vscale" > ${T1}_vols.txt
    echo "Brain volume in mm^3 (native/original space) = $ubrain" >> ${T1}_vols.txt
    echo "Brain volume in mm^3 (normalised to MNI) = $nbrain" >> ${T1}_vols.txt
fi


#### SUB-CORTICAL STRUCTURE SEGMENTATION
# required input: ${T1}_biascorr
# output: ${T1}_first*
if [ $do_subcortseg = yes ] ; then
    log_Msg 3  `date`
    log_Msg 3  "Performing subcortical segmentation"

    # Future note, would be nice to use ${T1}_to_MNI_lin.mat to initialise first_flirt
    ffopts=""

    if [ $use_lesionmask = yes ] ; then ffopts="$ffopts -inweight lesionmaskinv" ; fi

    run $FSLDIR/bin/first_flirt ${T1}_biascorr ${T1}_biascorr_to_std_sub $ffopts
    run mkdir first_results

    log_Msg 2  "$FSLDIR/bin/run_first_all $firstreg -i ${T1}_biascorr -o first_results/${T1}_first -a ${T1}_biascorr_to_std_sub.mat"
    FIRSTID=`$FSLDIR/bin/run_first_all $firstreg -i ${T1}_biascorr -o first_results/${T1}_first -a ${T1}_biascorr_to_std_sub.mat`
#    ${ScriptsDir}/run_first_all.sh $firstreg -i ${T1}_biascorr -o first_results/${T1}_first -a ${T1}_biascorr_to_std_sub.mat

#    echo "$FSLDIR/bin/fsl_sub -T 1 -j $FIRSTID imcp first_results/${T1}_first_all_fast_firstseg.${ext} ${T1}_subcort_seg.${ext}" >> $LOGFILE
#    $FSLDIR/bin/fsl_sub -T 1 -j $FIRSTID imcp first_results/${T1}_first_all_fast_firstseg.${ext} ${T1}_subcort_seg.${ext}
    if [ -e first_results/${T1}_first_all_fast_firstseg ] ; then
        $FSLDIR/bin/imcp first_results/${T1}_first_all_fast_firstseg ${T1}_subcort_seg
    fi
fi


#### CLEANUP
if [ $do_cleanup = yes ] ; then
    log_Msg 3  `date`
    log_Msg 3  "Cleaning up intermediate files"
    run $FSLDIR/bin/imrm ${T1}_biascorr_bet_mask ${T1}_biascorr_bet ${T1}_biascorr_brain_mask2 ${T1}_biascorr_init ${T1}_biascorr_maskedbrain ${T1}_biascorr_to_std_sub ${T1}_fast_bias_idxmask ${T1}_fast_bias_init ${T1}_fast_bias_vol2 ${T1}_fast_bias_vol32 ${T1}_fast_totbias ${T1}_hpf* ${T1}_initfast* ${T1}_s20 ${T1}_initmask_s20
fi
