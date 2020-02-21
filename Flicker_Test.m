%Flicker Test


% clear all
% clc
% 
% % This script calls Psychtoolbox commands available only in OpenGL-based
% % versions of the Psychtoolbox. (So far, the OS X Psychtoolbox is the
% % only OpenGL-base Psychtoolbox.)  The Psychtoolbox command AssertPsychOpenGL will issue
% % an error message if someone tries to execute this script on a computer without
% % an OpenGL Psychtoolbox
% AssertOpenGL;
% 
% % Get the list of screens and choose the one with the highest screen number.
% % Screen 0 is, by definition, the display with the menu bar. Often when
% % two monitors are connected the one without the menu bar is used as
% % the stimulus display.  Chosing the display with the highest dislay number is
% % a best guess about where you want the stimulus displayed.
% screens=Screen('Screens');
% screenNumber=min(screens);
% 
% Screen('Preference', 'SkipSyncTests', 1);
% ScreenRect=[0 0 750 750];
% w = Screen('OpenWindow',screenNumber, 128,ScreenRect);
% ifi = Screen('GetFlipInterval', w);
% graylevels=[0 0 0; 255 255 255];
% FlickerRt_Hz=30;
% FlickerPeriod=1./(2.*FlickerRt_Hz);
% 
% i=1;
% j=1;
% tic;
% while toc<3
%     
%     Screen('FillRect',w,graylevels(i+1,:));
%     Screen('Flip',w);
%     timeelapsed(j)=toc;
%     j=j+1;
%     WaitSecs(FlickerPeriod);
%     i=abs(i-1);
%     
%     
% end
% figure,plot(diff(timeelapsed))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%Iona - 2/19/20 taken from WaitFramesDemo

sca;
close all;
clearvars;

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers. This gives us a number for each of the screens
% attached to our computer.
screens = Screen('Screens');

% To draw we select the maximum of these numbers. So in a situation where we
% have two screens attached to our monitor we will draw to the external
% screen.
screenNumber = max(screens);

greylevels = [0, 0, 0; 0.5, 0.5, 0.5];

% Define black and white (white will be 1 and black 0). This is because
% in general luminace values are defined between 0 and 1 with 255 steps in
% between. All values in Psychtoolbox are defined between 0 and 1
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
% Do a simply calculation to calculate the luminance value for grey. This
% will be half the luminace values for white
grey = white / 2;

% Open an on screen window using PsychImaging and color it grey.
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

% Measure the vertical refresh rate of the monitor
ifi = Screen('GetFlipInterval', window);

% Retreive the maximum priority number and set max priority
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);

% Here we use to a waitframes number greater then 1 to flip at a rate not
% equal to the monitors refreash rate. For this example, once per second,
% to the nearest frame
flipSecs = 1;
waitframes = round(flipSecs / ifi);

% Flip outside of the loop to get a time stamp
vbl = Screen('Flip', window);

% Run until a key is pressed
%create an array of 1s and 2s to index into 
Flicker = repelem([1,2],1000);
i=1;
while ~KbCheck
    

    % Color the screen a random color
   % Screen('FillRect', window, rand(1, 3));
%   Screen('FillRect', window, greylevels(i+1,:));
    Screen('FillRect', window, greylevels(Flicker(1,i),:));

    % Flip to the screen
    vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    %i=abs(i-1);
    i=i+1;
end

% Clear the screen.
sca;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% WaitSecs(3);
% 
% frameRate=Screen('FrameRate',screenNumber);
% movieDurationSecs=5;
% 
% waitframes=FlickerPeriod.*frameRate;
% fprintf('waitframes=%.2f',waitframes);
% movieDurationFrames=round(movieDurationSecs * frameRate / waitframes);
% movieFrameIndices=mod(0:(movieDurationFrames-1), size(graylevels,1)) + 1;
% 
% %Make Textures
% for i = 1:size(graylevels,1)
%     testIm = repmat(reshape(graylevels(1,:), [1 1 3]), [ScreenRect(4) ScreenRect(3) 1]);
%     tex(i) = Screen('MakeTexture', w, testIm); %#ok<SAGROW>
% end
% 
%   ifi = Screen('GetFlipInterval', w);
%    % Perform initial Flip to sync us to the VBL and for getting an initial
%     % VBL-Timestamp for our "WaitBlanking" emulation:
% %     vbl=Screen('Flip', w);
%     currentTime = GetSecs;
% 
%     for i=1:movieDurationFrames
%         % Draw image:
%         Screen('DrawTexture', w, tex(movieFrameIndices(i)));
% 
%         % NEW: We only flip every 'waitframes' monitor refresh intervals:
%         % For this, we calculate a point in time after which Flip should flip
%         % at the next possible VBL.
%         % This should happen waitframes * ifi seconds after the last flip
%         % has happened (=vbl). ifi is the monitor refresh interval
%         % duration. We subtract 0.5 frame durations, so we have some
%         % headroom to take possible timing jitter or roundoff-errors into
%         % account.
%         % This is basically the old Screen('WaitBlanking', w, waitframes)
%         % as known from the old PTB...
%         Screen('Flip', w, currentTime + (waitframes - 0.5) * ifi);
%         currentTime = GetSecs;
%     end
%   
sca;

