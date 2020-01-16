% Grating masking experiment template
% We'll start here for coding an psychophysics experiment in Psychtoolbox
% in which we'll try to replicate the grating masking experiements of
% Breitmeyer and colleagues in the early 1980s.
%
% 1-16-2020     wst and im wrote it


%% Housekeeping
close all;
clear all;
clc;

%% Start by collecting experiment parameters from the command window
% Stash the experiment parameters in a single structure for easier saving
expParams.subjectID = GetWithDefault('Subject ID: ', '10001R');
expParams.displayPixelsPerDegree = GetWithDefault('Enter display scaling (ppd): ', 75);
expParams.gratingFlag = GetWithDefault('Select grating type (1 = square wave; 2 = sine wave): ', 1);
switch expParams.gratingFlag
    case 1
        expParams.gratingType = 'square';
    case 2
        expParams.gratingType = 'sine';
    otherwise
        error('Error in grating type selection');
end
        
expParams.gratingSpatialFrequency = GetWithDefault('Enter grating spatial frequency (cycles/deg): ', 4);
%...and so on as above

%% Next, initiate Psychtoolbox window


%% Experiment loop