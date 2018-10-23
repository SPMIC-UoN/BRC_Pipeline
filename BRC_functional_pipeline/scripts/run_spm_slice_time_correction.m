% Last update: 28/09/2018
%
% Author: Stefan Pszczolkowski
%
% Copyright 2018 University of Nottingham
%

function run_spm_slice_time_correction(spm_path, in_files_prefix, out_files_prefix, sliceorder, TR)
%
% run_spm_slice_time_correction(spm_path, in_files_prefix, out_files_prefix, sliceorder, nslices, TR)
%
% Inputs:
%
% spm_path         : Path to where the SPM library is installed.
% in_files_prefix  : Prefix of NIFTI volume files to correct, including the path to the folder where they are stored
% out_files_prefix : Prefix to prepend on output volume file names
% sliceorder       : Ordering of slices. Either 'forward', 'backward' or 'interleaved'
% TR               : Repetition time
%
%
    if nargin < 5
        error('Not enough input arguments');
    end

    if ~exist(spm_path, 'dir')
        error(['SPM path directory ''' spm_path ''' not found.']);
    end

  	if ~ismember(lower(sliceorder), {'forward', 'backward', 'interleaved'})
  		error(['Slice order must be either ''forward'', ''backward'' or ''interleaved''']);
  	end

    addpath(spm_path);

    vol_files = dir([in_files_prefix '*.nii']);

    num_volumes = numel(vol_files);

    if num_volumes == 0
        error(['No files with prefix ''' in_files_prefix ''' were found.']);
    end

    P = cell(num_volumes,1);

    for i = 1:num_volumes
        P{i} = [vol_files(i).folder '/' vol_files(i).name];
    end

    N = nifti(P{1});
    num_slices = N.dat.dim(3);

    TA = TR-TR/num_slices;
    timing = [TA/(num_slices-1) TR-TA];

	switch sliceorder
		case 'forward'
			sliceorder_arr = 1:1:num_slices;
		case 'backward'
			sliceorder_arr = num_slices:-1:1;
		case 'interleaved'
			sliceorder_arr = [1:2:num_slices 2:2:num_slices] ;
	end

    spm_slice_timing(P, sliceorder_arr, 1, timing, out_files_prefix);
end
