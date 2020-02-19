%Flicker Test


clear all
clc

% This script calls Psychtoolbox commands available only in OpenGL-based
% versions of the Psychtoolbox. (So far, the OS X Psychtoolbox is the
% only OpenGL-base Psychtoolbox.)  The Psychtoolbox command AssertPsychOpenGL will issue
% an error message if someone tries to execute this script on a computer without
% an OpenGL Psychtoolbox
AssertOpenGL;

% Get the list of screens and choose the one with the highest screen number.
% Screen 0 is, by definition, the display with the menu bar. Often when
% two monitors are connected the one without the menu bar is used as
% the stimulus display.  Chosing the display with the highest dislay number is
% a best guess about where you want the stimulus displayed.
screens=Screen('Screens');
screenNumber=min(screens);

Screen('Preference', 'SkipSyncTests', 1);
ScreenRect=[0 0 750 750];
w = Screen('OpenWindow',screenNumber, 128,ScreenRect);
ifi = Screen('GetFlipInterval', w);
graylevels=[0 0 0; 255 255 255];
FlickerRt_Hz=30;
FlickerPeriod=1./(2.*FlickerRt_Hz);

i=1;
j=1;
tic;
while toc<3
    
    Screen('FillRect',w,graylevels(i+1,:));
    Screen('Flip',w);
    timeelapsed(j)=toc;
    j=j+1;
    WaitSecs(FlickerPeriod);
    i=abs(i-1);
    
    
end
figure,plot(diff(timeelapsed))

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

