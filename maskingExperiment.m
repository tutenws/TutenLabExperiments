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

%%
% SKIP SYNC TEST
Screen('Preference', 'SkipSyncTests', 1); 
%it does not seem to be actually skipping the sync test 

%% Start by collecting experiment parameters from the command window
% Stash the experiment parameters in a single structure for easier saving
expParams.subjectID = GetWithDefault('Subject ID ', '10001R');
expParams.displayPixelsPerDegree = GetWithDefault('Enter display scaling (ppd) ', 75);
expParams.gratingFlag = GetWithDefault('Select grating type (1 = square wave; 2 = sine wave) ', 1);
switch expParams.gratingFlag
    case 1
        expParams.gratingType = 'square';
    case 2
        expParams.gratingType = 'sine';
    otherwise
        error('Error in grating type selection');
end
        
expParams.gratingSpatialFrequency = GetWithDefault('Enter grating spatial frequency (cycles/deg) ', 0.53);
expParams.GratingOscillationAmplitude = GetWithDefault('Oscillation Amplitude (Period)', 0.5);%oscilating one period would not change the image
expParams.GratingOscillationFrequency_Hz = GetWithDefault('OscillationFrequency (Hz)', 4);
    %the oscillation frequency should  be randomized

%...and so on as above

%% TO DO
%have to be able to move the circle around
%make an option for a sine wave rather than a square wave.
%oscillation frequency stair case?
%participant responses preceed each presentation
%click before each presentation
%problem: changing the frequency does not seem to be changing the oscillation frequency
%tototototot

%% Next, initiate Psychtoolbox window

%WINDOW PERAMETERS
%Identify the Number of screens
ScreenID = max(Screen('Screens')); %the largest number will be the screen that the stim is drawn to
%ScreenID = min(Screen('Screens')); %the largest number will be the screen that the stim is drawn to
  %for some reason using the max screen was not working
  
 %WHICH SCREEN TO DRAW ON
 [win]=Screen('OpenWindow',ScreenID); %window fills screen
 %[win]=Screen('OpenWindow',ScreenID,[],[0 0 1000 1000]); %window fills screen
 %    %??I can't figure out what win is??
 
%WINDOW DIMENTION IN PX 
[expParams.winXpx, expParams.winYpx]=Screen('WindowSize',ScreenID);
%Record visual angle of the window
expParams.SurroundW_dg=expParams.winXpx./expParams.displayPixelsPerDegree;
expParams.SurroundH_dg=expParams.winYpx./expParams.displayPixelsPerDegree;

%PIXELS IN THE CENTER OF THE WINDOW
[Xcent, Ycent] = RectCenter([0 0 expParams.winXpx expParams.winYpx]);
%these values will be used to position the surround and the circle


%% Additional Stimulus Variables

%TRIALS
TrialsPerCond = 40;
NumbOfCond = 5;
TotalTrials = NumbOfCond.*TrialsPerCond;


%Circle diameter in visual angle
expParams.CircDiam_dg=7;
%Circle Luminance
CircLum = [128,128,128];

%STIMULUS VARIABLES IN PX
CircDiam_px=expParams.displayPixelsPerDegree.*expParams.CircDiam_dg;

%FIXATION LINE VARIABLES - 4 tick marks will be on the circle to direct the 
%participant's gaze to the center of the circle 
FixLineWidth_px = 2;
FixLineLeangth_px = 100;
FixLinePos1_px = CircDiam_px./2;
FixLinePos2_px = (CircDiam_px./2)-FixLineLeangth_px;
%determine coordinates of the fixation lines
xCoords = [-FixLinePos1_px,-FixLinePos2_px,0,0,FixLinePos1_px,FixLinePos2_px,0,0];
yCoords = [0,0,FixLinePos1_px,FixLinePos2_px,0,0,-FixLinePos1_px,-FixLinePos2_px];
AllCoords = [xCoords; yCoords];

%% Subj Centers Circle
%this will allow the subject to use the game controller to adjust the
%position of the stimulus so that it is in the center of the projection

% %CHECK FOR KEY PRESSES
% GamePad = GamePadInput([]);
% 
% while GamePad.noChange == 1 %while keys are not pressed
%     Screen('FillOval',win,CircLum,CenteredCirc); %the circle is drawn in a box of the width and height of the circle
% 
%     Screen('FillRect',win,[0,0,0]); %grey background
% %DrawFormattedText(win,'Experiment Preparation/Press any button to Continue',center);
% 
% Screen('Flip');
% end



%% Work on drawing stimulus - Iona
    %Make a matrix to draw white and black lines to make the surround grating 
    %Determine width of one bar (white or black) in pixels
    WidthOfOneBar_px = round((0.5./expParams.gratingSpatialFrequency).*expParams.displayPixelsPerDegree); %determine visual angle of a stripe and then pixels
    BarNumb = 1+round(expParams.winXpx./WidthOfOneBar_px); %number of bars across the screen rounded up (matrix will later be cut to fit screen)
        %add one bar to provide wiggle room for cropping the bar series at the correct start location
        
    %Repeat correct RGB values the width and height of window
    twobars = repelem([255,0],WidthOfOneBar_px); %repeats 255 and 0 the width of two bars
    Grating = repmat(twobars,expParams.winYpx,BarNumb);%repeat numbers to make the bars repeat the height of the window
    
    %CROPING BAR SERIES TO FIT SCREEN AND FOR GRATING OSCILLATION
    Grating_Crop1 = Grating(1:expParams.winYpx,1:expParams.winXpx); %crop Grating to fit the window width & height
         %bar series begins with white
    %Determines how much to crop bar series 2 to simulate an oscillation of the specified period
    OscillationAmp = expParams.GratingOscillationAmplitude.*(2.*WidthOfOneBar_px);
    Grating_Crop2 = Grating(1:expParams.winYpx, OscillationAmp:(expParams.winXpx+OscillationAmp));
    
    
    %CENTER CIRCLE - white circle that surrounds test spot   
    CenteredCirc = CenterRectOnPointd([0, 0, CircDiam_px, CircDiam_px],Xcent,Ycent);

    
 OneOcillation_sec = (1./expParams.GratingOscillationFrequency_Hz ); %time interval between each oscillation
for i = 1:5 %change this later
    %OSCILLATING AT A FREQUENCY
    %beginning of experiment do I put the frequency?? or will It just
    %rotate through frequencies (look at paper) might need to be random
    %while thing with multiples of 2 - look at previous 
StartTime = GetSecs;
TimeNow = StartTime;
LastChange = GetSecs; %records the time the grating was last oscilated
%BAR SERIES 1
while (TimeNow == StartTime) || (TimeNow >= OneOcillation_sec + LastChange)
    %DRAW BAR SERIES 1
    Grating_Txt1 = Screen('MakeTexture',win,Grating_Crop1);
    Screen('DrawTexture',win,Grating_Txt1);
   
    %DRAW CIRCLE
    Screen('FillOval',win,CircLum,CenteredCirc); %the circle is drawn in a box of the width and height of the circle
    
    %DRAW FIXATION CROSS
    Screen('DrawLines',win,AllCoords,FixLineWidth_px,[0,0,0],[Xcent,Ycent]);
    
    Screen('Flip', win);
    
    TimeNow = GetSecs; %gets current time
end

%TIME VARIABLES FOR BAR SERIES 2
StartTime = GetSecs;
TimeNow = StartTime;
LastChange = GetSecs; %records the time the grating was last oscilated
%BAR SERIES 2
while (TimeNow == StartTime) || (TimeNow >= OneOcillation_sec + LastChange)
    
    %DRAW BAR SERIES 2
    Grating_Txt2 = Screen('MakeTexture',win,Grating_Crop2);
    Screen('DrawTexture',win,Grating_Txt2);
    
    %DRAW CIRCLE
    Screen('FillOval',win,CircLum,CenteredCirc);
    %the circle is drawn in a box of the width and height of the circle
    
    %DRAW FIXATION CROSS
    Screen('DrawLines',win,AllCoords,FixLineWidth_px,[0,0,0],[Xcent,Ycent]);
    
    Screen('Flip', win);
    
    TimeNow = GetSecs; %gets current time
    
end %end of second while loop
end %end of for loop
    
% KbWait;
% 
% sca;


%CHECK FOR KEY PRESSES
GamePad = GamePadInput([]);
ButtonPress =0;

%while ButtonPress == 0
for i = 0:10
    %DRAW BAR SERIES 2
    Grating_Txt2 = Screen('MakeTexture',win,Grating_Crop2);
    Screen('DrawTexture',win,Grating_Txt2);
    
    %DRAW CIRCLE
    Screen('FillOval',win,CircLum,CenteredCirc);
    %the circle is drawn in a box of the width and height of the circle
    
    %DRAW FIXATION CROSS
    Screen('DrawLines',win,AllCoords,FixLineWidth_px,[0,0,0],[Xcent,Ycent]);
    
    Screen('Flip', win);

if GamePad.buttonLeftLowerTrigger==1
    ButtonPress=1;
end


end


% while GamePad.noChange == 1 %while keys are not pressed
%     Screen('FillOval',win,CircLum,CenteredCirc); %the circle is drawn in a box of the width and height of the circle
% 
%     Screen('FillRect',win,[0,0,0],[expParams.winXpx, expParams.winYpx]); %grey background
% %DrawFormattedText(win,'Experiment Preparation/Press any button to Continue',center);
% 
% Screen('Flip',win);
% end







%% Experiment loop


