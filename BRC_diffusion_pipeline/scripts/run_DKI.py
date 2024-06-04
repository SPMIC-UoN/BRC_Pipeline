#!/bin/env python

import numpy as np
import sys
import dipy.reconst.dki as dki
import dipy.reconst.dki_micro as dki_micro
import dipy.reconst.fwdti as fwdti
from dipy.core.gradients import gradient_table
from dipy.io.gradients import read_bvals_bvecs
from dipy.io.image import load_nifti, save_nifti
from dipy.segment.mask import median_otsu
from scipy.ndimage import gaussian_filter

#-----------------------------------------
datadir     = sys.argv[1]
do_MPPCA    = sys.argv[2]
do_DKI      = sys.argv[3]
do_WMTI     = sys.argv[4]
do_FWDTI    = sys.argv[5]
#-----------------------------------------

if do_MPPCA == "yes":
    fraw        = datadir + "/data.nii.gz"
    data, affine = load_nifti(fraw)

elif do_MPPCA != "yes":
    fraw        = datadir + "/data_brain.nii.gz"
    fbval       = datadir + "/bvals"
    fbvec       = datadir + "/bvecs"
    # mask        = datadir + "/nodif_brain_mask.nii.gz"

    # mask         = load_nifti(mask)
    data, affine = load_nifti(fraw)
    bvals, bvecs = read_bvals_bvecs(fbval, fbvec)
    gtab = gradient_table(bvals, bvecs)

    # Create brain mask
    maskdata, mask = median_otsu(data, vol_idx=[0], autocrop=False, dilate=1)

    # save_nifti(datadir + '/mask.nii.gz', mask.astype(np.float32), affine)

# Marcenko-Pastur PCA denoising
if do_MPPCA == "yes":
    fwhm = 1.25
    gauss_std = fwhm / np.sqrt(8 * np.log(2))  # converting fwhm to Gaussian std
    data_smooth = np.zeros(data.shape)
    for v in range(data.shape[-1]):
        data_smooth[..., v] = gaussian_filter(data[..., v], sigma=gauss_std)

    save_nifti(datadir + '/data_denoised.nii.gz', data_smooth.astype(np.float32), affine)

if do_DKI == "yes":

    # apply DKI model
    dkimodel = dki.DiffusionKurtosisModel(gtab)
    dkifit = dkimodel.fit(data, mask=mask)
    # dkifit = dkimodel.fit(data_smooth, mask=mask)

    MK = dkifit.mk(0, 3)
    AK = dkifit.ak(0, 3)
    RK = dkifit.rk(0, 3)

    save_nifti(datadir + '/data.dki/dki_MK.nii.gz', MK.astype(np.float32), affine)
    save_nifti(datadir + '/data.dki/dki_AK.nii.gz', AK.astype(np.float32), affine)
    save_nifti(datadir + '/data.dki/dki_RK.nii.gz', RK.astype(np.float32), affine)

if do_WMTI == "yes":

    # apply WMTI model
    wmtimodel = dki_micro.KurtosisMicrostructureModel(gtab)

    wmtifit = wmtimodel.fit(data, mask=mask)

    AWF = wmtifit.awf
    ADia = wmtifit.axonal_diffusivity
    ADea = wmtifit.hindered_ad
    RDea = wmtifit.hindered_rd
    TORT = wmtifit.tortuosity

    save_nifti(datadir + '/data.wmti/wmti_AWF.nii.gz', AWF.astype(np.float32), affine)
    save_nifti(datadir + '/data.wmti/wmti_ADia.nii.gz', ADia.astype(np.float32), affine)
    save_nifti(datadir + '/data.wmti/wmti_ADea.nii.gz', ADea.astype(np.float32), affine)
    save_nifti(datadir + '/data.wmti/wmti_RDea.nii.gz', RDea.astype(np.float32), affine)
    save_nifti(datadir + '/data.wmti/wmti_TORT.nii.gz', TORT.astype(np.float32), affine)

if do_FWDTI == "yes":

    # remove DTI free water contamination
    fwdtimodel = fwdti.FreeWaterTensorModel(gtab)

    fwdtifit = fwdtimodel.fit(data, mask=mask)

    FA  = fwdtifit.fa
    MD  = fwdtifit.md
    F   = fwdtifit.f

    save_nifti(datadir + '/data.fwdti/fwdti_FA.nii.gz', FA.astype(np.float32), affine)
    save_nifti(datadir + '/data.fwdti/fwdti_MD.nii.gz', MD.astype(np.float32), affine)
    save_nifti(datadir + '/data.fwdti/fwdti_F.nii.gz', F.astype(np.float32), affine)
