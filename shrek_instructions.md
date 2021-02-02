# Overall Steps

1. Transfer files to Shrek, connect to Shrek
2. Enter docker container, navigate to correct directories
3. Start ipython, start trainining.

# Transfering files and connecting to Shrek

## Transfering files

`scp -r local_directory your_username@Shrek:/home/abs9091/dlc_folder` -> i think this is right, but check the directory

## Connect to Shrek

`ssh your_username@Shrek`

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

`config = 'config.yaml'

## start training

`deeplabcut.train_network(config)`
