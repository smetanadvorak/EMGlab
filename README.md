# EMGlab 1.031
This is a modified version of EMGlab software. It contains slight changes to the original version that I made to facilitate the work with it. First, it supresses the warning message that appeared during scrolling of the EMG scope and slowed the animation. Second, it masks the original findpeaks.m function so that it doesn't collide with the Matlab's one. No other changes were applied. 

The licence file is provided without changes. 
 
Original EMGlab:
McGill KC, Lateva ZC, Marateb HR. EMGLAB: an interactive EMG decomposition program. J Neurosci Methods 149(2):121-133, 2005.
[http://www.emglab.net]
 
 
 # Official README.txt of EMGlab 1.03:
 EMGLab 1.03

## Introduction
  EMGlab is an interactive program for viewing and decomposing EMG signals.

## System Requirements
  Matlab version 6.5 or higher. No Matlab toolboxes are required.

## Installation Instructions 
  1. Run Matlab
  2. In Matlab, select the emglab1.03 folder as the current directory. You can do 
     this using the Current Directory window, the cd command, or the File Open
     Menu.
  3. At the Matlab command prompt, type:
     >>install

## Running EMGLAB
  To run EMGlab, type "emglab" in the Matlab command window.

## Release Notes 
1.03  2009 - 05 - 28: 
  Fixed navigation slider text in fast draw mode. 
  Changed filter order in Open EMG file dialog.
  Fixed errors with saving annotations when quitting.
  Fixed scaling of .smr files.
                
1.02  2009 - 02 - 26:
  Fixed problem with saving and loading .eaf files.       

1.01  2009 - 01 - 27:
  Fixed problem with playing the signal.
  Fixed problem with importing EMG signal.
  Fixed mtlplugin bug that caused crash in Matlab 6.5. 
 
