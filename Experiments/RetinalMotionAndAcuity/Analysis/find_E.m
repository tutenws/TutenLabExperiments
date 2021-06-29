function [X, Y, frames_w_E, max_val] = find_E(filename, E_size_pix, ...
    orientation, xcorr_threshold, print_output, show_error_dlg)
% Find the center of a tumbling E stimulus in a video frame by frame
%
% USAGE
% [X, Y, frames_w_E, max_val] = find_E(filename, E_size_pix, ...
%    orientation, xcorr_threshold, print_output, show_error_dlg)
%    
%
% INPUT
% filename:             name of video file to read.
% E_size_pix:           size of the E in pixels (imported into main script)
%                           to use in correlation
% orientation:          loads the orientation of the stimulus on the retina
% xcorr_threshold:      threshold for detecting the E, set to .5 default
% print_output:         0 or 1. Decide whether to print results, 1 = print
% show_error_dlg:       choose to show an error dialogue box with information
%                           for the user or not
% 
% OUTPUT
% X:          location of E center in X, this will be a vector with 
%                       values for each frame where the E center was found.
% Y:          location of E center in Y. Same as above.
% frames_w_E:       array containing frame numbers that contained an E.
% max_val:          maximum correlation value between image and stimulus.


import util.*

if nargin < 2 %setting default params
    E_size_pix = 10;
end
if nargin < 3
    orientation = 0;
end
if nargin < 4
    xcorr_threshold = 0.5; %.5 default
end
if nargin < 5
    print_output = 0;
end
if nargin < 6
    show_error_dlg = 0;
end


% generate an E to scale of size presented
basicE = ones(5,5);
basicE(:,1) = 0;
basicE(1:2:5,:) = 0;
scale = E_size_pix;
stimE = imresize(basicE, scale, 'nearest');
stimE = 1-stimE;

% rotate filter E to match presentation stimulus
stimE = imrotate(stimE, orientation);

try
    % create video reader object
    reader = VideoReader(filename);
    
catch ME
    disp(filename);
    rethrow(ME);
    
end

frameN = 1;
n = 1;

while hasFrame(reader)  
    
    % select the current frame
    currentframe = readFrame(reader);
    
    % convert to a double (necessary for cross corr)
    currentframe = im2double(currentframe(:, :, 1));
    
    % change the background values to 0
    currentframe(currentframe==0) = [1];
    
    % invert the image
    currentframe = 1 - currentframe;
    
    % do the cross correlation, calls script to find largest values in each
    % row & column
    xcorr = imfilter(currentframe, stimE)./sum(stimE(:));
    % find the position of highest correlation
    [corr, Yr, Xr] = array.max2D_RS(xcorr);

    % check if corr was above threshold
    if corr > xcorr_threshold
        Y(n, 1)  = Yr;
        X(n, 1)  = Xr;
        max_val(n,1) = corr;
        frames_w_E(n, 1) = frameN;
        n = n+1; 
    end
    
    % increment frame number
    frameN = frameN + 1;
end

% create variables with the locations
if exist('X', 'var') && exist('Y', 'var')
    if print_output == 1 % print
        disp(X); disp(std(X))
        disp(Y); disp(std(Y))

    end
else
    % in the case where E was not found in any frames, return nan values
    X = nan;
    Y = nan;
    max_val = corr;
    frames_w_E(n, 1) = frameN;
    if show_error_dlg
        errordlg('IR E loc not found', 'Record another movie.');
    end
end