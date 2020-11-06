*Do these steps only once you've trained a model*

#Install anipose. 

Detailed instructions at [https://anipose.readthedocs.io/en/latest/installation.html](https://anipose.readthedocs.io/en/latest/installation.html), but the following likely should work:

1. first enter your DLC-CPU conda environment with `conda activate DLC-CPU.

2. Then, run `python -m pip install -U wxPython` ( `conda install wxPython`)

3. Next, run `pip install anipose`

4. And, then run `conda install mayavi ffmpeg`

#Set-up folder structure
1. Set-up the folder structure for your experiment, details here: [https://anipose.readthedocs.io/en/latest/start3d.html](https://anipose.readthedocs.io/en/latest/start3d.html). you can download a sample config.toml file here:

2. Edit your config.toml file to your own dataset, it'll be similar to editing your config.yaml file from DLC. Make sure you download your project from Google Drive, and then link to the path inside config.toml.

Inside your `session` folder (or osmething called similarly), create a folder called `raw-videos` and a folder called `calibration`. Upload the animal videos into raw-videos, and the calibration videos into calibration.

3. Enter the experiment folder (in the directory with the config.toml), and then run:

`anipose analyze`

`anipose filter`

`anipose calibrate`

`anipose triangulate`

these take variable times, but should spit out 3d outputs as a .h5 file in a created 3d pose folder.
