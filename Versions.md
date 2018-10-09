## Versions

09-Oct-2018 (V1.0.6)
 - Bug fixed in Intensity Normalization inputs.
 - Run Time is added to the `BRC_functional_pipeline`.
 - Bug fixed in Eddy processing in `BRC_functional_pipeline` project.
 - Extracting TR from the data. Option --tr in `BRC_functional_pipeline` project is deleted.
 - The output results of functional processing are organized in `BRC_functional_pipeline` project.

08-Oct-2018 (V1.0.5)
 - Bug fixed in running Freesurfer and saving the outputs in `BRC_structural_pipeline`.

04-Oct-2018 (V1.0.4)
 - Minor bug to create Intensity_Norm folder is fixed in `fMRI_preproc.sh` function in the `BRC_functiona_pipeline`.
 - Minor bug fixed in `One_Step_Resampling` function in the `BRC_functional_pipeline`.
 - To reduce the ambiguity, version of the software is added to all pipelines.

03-Oct-2018 (V1.0.3)
 - Spatial smoothing and physiological noise removal inputs are updated in the `BRC_functiona_pipeline`.
 - Using `--slspec` option, the `BRC_functional_pipeline` can extract SliceTiming information from the fMRI DICOM file.

02-Oct-2018 (V1.0.1)
 - Intensity Normasization is added to `BRC_functional_pipeline`.
