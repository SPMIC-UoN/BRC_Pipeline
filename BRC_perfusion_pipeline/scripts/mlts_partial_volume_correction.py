import argparse
import os
import sys
import nibabel as nib
import numpy as np
from  scipy.stats import chi2

def mlts_with_priors(x, y, xstart, ystart, gamma):
    nc = 10
    delta = 0.01

    p = x.shape[1]
    n = x.shape[0]
    h = int(np.floor(n * (1 - gamma))) + 1

    bstart = np.linalg.pinv(xstart).dot(ystart)
    res1 = ystart - xstart.dot(bstart)
    sigmastart = np.transpose(res1).dot(res1)
    beta = bstart
    sigma = sigmastart
    for loop in np.arange(nc):
        res2 =  y - x.dot(bstart)
        dist2 = np.sum((res2 / (sigmastart+1e-10)) * res2, axis=1)
        idist2 = np.argsort(dist2)[:h]
        xstart = x[idist2, :]
        ystart = y[idist2, :]
        bstart = np.linalg.pinv(xstart).dot(ystart)
        res1 = ystart - xstart.dot(bstart)
        sigmastart = np.transpose(res1).dot(res1) / (h-p+1e-10)

    if sigmastart < 1e10:
        beta = bstart
        sigma = sigmastart

    cgamma = (1 - gamma) / chi2.cdf(chi2.ppf(1 - gamma, 1), 3)
    sigma = cgamma * sigma
    res2 =  y - x.dot(beta)
    dres =  np.sqrt(np.sum((res2 / (sigma+1e-10)) * res2, axis=1))

    qdelta = np.sqrt(chi2.ppf(1 - delta, 1))
    nooutlier = (dres <= qdelta * np.ones([1, n])).flatten()
    xgood = x[nooutlier, :]
    ygood = y[nooutlier, :]
    return np.linalg.pinv(xgood).dot(ygood)


def least_squares(x, y):
    return np.linalg.pinv(x).dot(y)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Computes a partial volume correction of an input perfusion-weighted or CBF Nifti image.',
                                     epilog='(c) 2020-2021. Written by Dr. Stefan Pszczolkowski (stefan.pszczolkowskiparraguez@nottingham.ac.uk), based on previous MATLAB code by Dr. Duncan Hodkinson (duncan.hodkinson@nottingham.ac.uk) and the original code by Xiaoyun Liang (https://www.nitrc.org/projects/pvc_mlts/).',
                                     formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('--nifti-input', dest='nifti_input_file', required=True, help='Path to Nifti input file of perfusion or CBF.')
    parser.add_argument('--nifti-pve-gm', dest='nifti_pve_gm_file', required=True, help='Path to Nifti input file of the grey matter partial volume estimations.')
    parser.add_argument('--nifti-pve-wm', dest='nifti_pve_wm_file', required=True, help='Path to Nifti input file of the white matter partial volume estimations.')
    parser.add_argument('--nifti-output-gm', dest='nifti_output_gm_file', required=False, default=None, help='Path to Nifti output file of corrected grey matter perfusion.')
    parser.add_argument('--nifti-output-wm', dest='nifti_output_wm_file', required=False, default=None, help='Path to Nifti output file of corrected white matter perfusion.')
    parser.add_argument('--kernel-size', dest='kernel_size', required=False, default=5, type=int, help='Size of the kernel window for regression estimation. Accepted sizes are 3, 5, 7, and 9. Default is 5.')
    parser.add_argument('--gamma', dest='gamma', required=False, default=0.4, type=float, help='Trimming proportion for Least Trimmed Squares algorithm. Must be a number greater than 0 and less than 1. Default is 0.4.')

    args = parser.parse_args()

    nifti_input_file = args.nifti_input_file
    nifti_pve_gm_file = args.nifti_pve_gm_file
    nifti_pve_wm_file = args.nifti_pve_wm_file
    nifti_output_gm_file = args.nifti_output_gm_file
    nifti_output_wm_file = args.nifti_output_wm_file
    kernel_size = args.kernel_size
    gamma = args.gamma

    if not os.path.isfile(nifti_input_file):
        sys.stderr.write('\nError: File "{}". does not exist!\n\n'.format(nifti_input_file))
        sys.exit()

    if (nifti_pve_gm_file is not None) and (not os.path.isfile(nifti_pve_gm_file)):
        sys.stderr.write('\nError: File "{}". does not exist!\n\n'.format(nifti_pve_gm_file))
        sys.exit()

    if (nifti_pve_wm_file is not None) and (not os.path.isfile(nifti_pve_wm_file)):
        sys.stderr.write('\nError: File "{}". does not exist!\n\n'.format(nifti_pve_wm_file))
        sys.exit()

    if (nifti_output_gm_file is None) and (nifti_output_wm_file is None):
        sys.stderr.write('\nError: At least one of --nifti-output-gm or --nifti-output-wm must be provided.\n\n')
        sys.exit()

    if nifti_output_gm_file == nifti_output_wm_file:
        sys.stderr.write('\nError: Output grey matter and white matter files cannot be the same.\n\n')
        sys.exit()

    if (not np.isscalar(kernel_size)) or (not kernel_size in [3, 5, 7, 9]):
        sys.stderr.write('\nError: Kernel size must be 3, 5, 7 or 9.\n\n')
        sys.exit()

    if (not np.isscalar(gamma)) or (gamma <= 0) or (gamma >= 1):
        sys.stderr.write('\nError: Trimming proportion must be a number greater than 0 and less than 1.\n\n')
        sys.exit()

    nii_img = nib.load(nifti_input_file)
    nii_pve_gm = nib.load(nifti_pve_gm_file)
    nii_pve_wm = nib.load(nifti_pve_wm_file)

    if (not np.equal(nii_img.header['dim'][1:4], nii_pve_gm.header['dim'][1:4]).all()) or \
       (not np.equal(nii_img.header['dim'][1:4], nii_pve_wm.header['dim'][1:4]).all()) or \
       (not np.equal(nii_pve_gm.header['dim'][1:4], nii_pve_wm.header['dim'][1:4]).all()) or \
       (not np.equal(nii_img.header['pixdim'][1:4], nii_pve_gm.header['pixdim'][1:4]).all()) or \
       (not np.equal(nii_img.header['pixdim'][1:4], nii_pve_wm.header['pixdim'][1:4]).all()) or \
       (not np.equal(nii_pve_gm.header['pixdim'][1:4], nii_pve_wm.header['pixdim'][1:4]).all()):
            sys.stderr.write('\nError: All images have to be in the same space.\n\n')
            sys.exit()

    img_data = nii_img.get_data()

    img_size = img_data.shape
    pve_gm_data = nii_pve_gm.get_data().reshape(img_size)
    pve_wm_data = nii_pve_wm.get_data().reshape(img_size)
    pve_csf_data = np.ones(img_size) - pve_gm_data - pve_wm_data

    kernel_radius = int((kernel_size - 1) / 2)

    corrected_img_gm = np.zeros(img_size, dtype=np.int16)
    corrected_img_wm = np.zeros(img_size, dtype=np.int16)
    diff = np.zeros([kernel_size ** 2, 1])
    P = np.zeros([kernel_size ** 2, 3])
    M = np.zeros([kernel_size ** 2, 1])

    epsilon = 10e-2
    is_gm_voxel = (pve_gm_data >= epsilon)
    is_wm_voxel = (pve_wm_data >= epsilon)
    is_valid_voxel = (img_data > 0) & (is_gm_voxel | is_wm_voxel)
    max_allowed_value = int(1.1 * np.max(img_data[is_valid_voxel]))

    for z in np.arange(img_size[2]):
        for y in np.arange(kernel_radius, img_size[1]-kernel_radius):
            for x in np.arange(kernel_radius, img_size[0]-kernel_radius):

                if is_valid_voxel[x, y, z]:
                    k = 0

                    for j in np.arange(kernel_size):
                        for i in np.arange(kernel_size):
                            if is_valid_voxel[x + i - kernel_radius, y + j - kernel_radius, z]:
                                diff[k] = np.abs(img_data[x + i - kernel_radius, y + j - kernel_radius, z] - img_data[x, y, z])
                                P[k, 0] = pve_gm_data[x + i - kernel_radius, y + j - kernel_radius, z]
                                P[k, 1] = pve_wm_data[x + i - kernel_radius, y + j - kernel_radius, z]
                                P[k, 2] = pve_csf_data[x + i - kernel_radius, y + j - kernel_radius, z]
                                M[k] = img_data[x + i - kernel_radius, y + j - kernel_radius, z]
                                k += 1

                    idx = np.argsort(diff[:k], axis=None, kind='mergesort')

                    P_sort = P[idx, :]
                    M_sort = M[idx]

                    w = 1
                    P_sort_rank = np.linalg.matrix_rank((P_sort[0, :]).reshape(1,3))
                    while (P_sort_rank < 2) and (w < k):
                        w += 1
                        P_sort_rank = np.linalg.matrix_rank((P_sort[:w, :]).reshape(w,3))

                    if P_sort_rank >= 2:
                        m_estim_mlts = mlts_with_priors(P[:k,:], M[:k], P_sort[:w,:], M_sort[:w], gamma)
                        m_estim_ls = least_squares(P[:k,:], M[:k])

                        if is_gm_voxel[x, y, z]:
                            if (m_estim_mlts[0] > 0) and (m_estim_mlts[0] <= max_allowed_value):
                                corrected_img_gm[x, y, z] = np.round(m_estim_mlts[0]).astype(int)
                            elif (m_estim_ls[0] > 0) and (m_estim_ls[0] <= max_allowed_value):
                                corrected_img_gm[x, y, z] = np.round(m_estim_ls[0]).astype(int)

                        if is_wm_voxel[x, y, z]:
                            if (m_estim_mlts[1] > 0) and (m_estim_mlts[1] <= max_allowed_value):
                                corrected_img_wm[x, y, z] = np.round(m_estim_mlts[1]).astype(int)
                            elif (m_estim_ls[1] > 0) and (m_estim_ls[1] <= max_allowed_value):
                                corrected_img_wm[x, y, z] = np.round(m_estim_ls[1]).astype(int)


    if nifti_output_gm_file is not None:
        nii_out = nib.nifti1.Nifti1Image(corrected_img_gm, None, header=nii_img.header)
        nib.save(nii_out, nifti_output_gm_file)

    if nifti_output_wm_file is not None:
        nii_out = nib.nifti1.Nifti1Image(corrected_img_wm, None, header=nii_img.header)
        nib.save(nii_out, nifti_output_wm_file)
