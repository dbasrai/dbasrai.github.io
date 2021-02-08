# Overall Steps

1. Transfer files to Shrek, connect to Shrek
2. Enter docker container, navigate to correct directories
3. Start ipython, start trainining.

# Transfering files and connecting to Shrek

## Transfering files

`scp -r local_directory abs9091@Shrek:/home/abs9091/dlc_folder` -> i think this is right, but check the directory

## Connect to Shrek

`ssh abs9091@Shrek`

# Entering docker container, navigating to correct directories

## Enter docker container

`docker exec --user $USER -it alex_container /bin/bash`

## Navigate to correct directory

`cd ../../../home/abs9091/dlc_folder` -> again i think this is rght, but not sure

# Start ipython, tmux, and training

## Start tmux

`tmux`

this starts a tmux window, lets split the window.

`ctrl-b + %`

this splits the window, in the right window run `watch -n 1 nvidia-smi`, then use `ctrl-b + <-` to navigate to left window

## start ipython

`sudo ipython`

and then inside ipython

`%env DLClight True`

`import deeplabcut`

`config = 'config.yaml'`

## start training

`deeplabcut.train_network(config)`

## checking on training

if you closed your terminal, then make sure you're re-logged back into the docker container. then use `tmux ls` to see the # of your tmux session (it'llbe listed on the left).It is potentially `1`.

Then use the command `tmux a -t NUMBER`, replacing number with just the number checked above (usually `1`). This will allow you to re-enter your tmux session.

## finished training, analyze videos

once training is finished, we want to analyze our videos and created a labeled video. Your ipython should still be open i believe at this point, and if so, run the following commands.

`deeplabcut.analyze_videos(config)`

might take a little.

`deeplabcut.create_labeled_video(config, draw_skeleton=True)`

## closing tmux

Once training/analyzing/labeling is finished, we want to close our tmux session in order to make sure we're no longer using the GPU. 

Use `Ctrl-B, D` in order to detach from your tmux session.

Then use `tmux kill-session -t NUMBER` in order to kill your tmux session.

I would quickly use `nvidia-smi` to double check you're no longer using the GPU`.

## transfer files back to local

Disconnect from both the docker/Shrek and then use 

`scp -r asb9091@Shrek:/home/abs9091/dlc_folder .` -> i havent tried this, but I think it should work.
