%Trying Quest

%Fill the screen with a rectangle use quest to change the intensity of the
%rectangle 

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
%GRATING SPATIAL FREQUENCY       
expParams.gratingSpatialFrequency = GetWithDefault('Enter grating spatial frequency (cycles/deg) ', 0.53);
%OSCILLATION AMPLITUDE - of grating
expParams.GratingOscillationAmplitude = GetWithDefault('Oscillation Amplitude (Period)', 0.5);%oscilating one period would not change the image
%OSCILLATION FREQUENCY
expParams.GratingOscillationFrequency_Hz = GetWithDefault('OscillationFrequency (Hz)', 4);
    %the oscillation frequency should  be randomized


%% Set up Psychtoolbox window

%WINDOW PERAMETERS
%Identify the Number of screens
ScreenID = max(Screen('Screens')); %the largest number will be the screen that the stim is drawn to
  
 %WHICH SCREEN TO DRAW ON
 [win]=Screen('OpenWindow',ScreenID); %window fills screen
 %[win]=Screen('OpenWindow',ScreenID,[],[0 0 1000 1000]); 
 
%WINDOW DIMENTION IN PX 
[expParams.winXpx, expParams.winYpx]=Screen('WindowSize',ScreenID);
%Record visual angle of the window
expParams.SurroundW_dg=expParams.winXpx./expParams.displayPixelsPerDegree;
expParams.SurroundH_dg=expParams.winYpx./expParams.displayPixelsPerDegree;

%PIXELS IN THE CENTER OF THE WINDOW
[Xwincent, Ywincent] = RectCenter([0 0 expParams.winXpx expParams.winYpx]);

%% Variables

%Circle Luminance
CircLum = [128,128,128];
CircLumVal = CircLum(1,1); %needed for luminance adjustment of test spot

%TRIAL SEQUENCE SPECIFICATIONS
expParams.TrialDuration_s = 1.1;
expParams.TestSpotDur_s = 0.1;
expParams.PreTestSpotDur_s = 0.5;

%STAIRCASE VARIABLES 
expParams.Staircase.ThresholdGuess = -2;
expParams.Staircase.ThresholdGuessSD = 3; %3 was recommended by PTB %SD assigned to the threshold guess
expParams.Staircase.pThreshold = 0.78; %probability of subj seeing the stim (threshold criterion)
expParams.Staircase.Beta = 3.5; %Parameter of Weibull psychometric function. Beta controls the steepness of the function
expParams.Staircase.Delta = 0.01; %Parameter of Weibull psychometric function. Delta is the fraction of trials the subj is guessing typically 0.01
expParams.Staircase.Gamma = 0.01; %Parameter of Weibull psychometric function. fraction of trials that will generate response 1 when intensity is negative infinity
expParams.Staircase.Grain = 0.01; %step size of the internal table, 0.01. ???
expParams.Staircase.Range = 5; %5 recommended by PTB. The difference bw the largest and smallet intensity that the intital table can store

%%  Quest

StairFunc = QuestCreate(expParams.Staircase.ThresholdGuess,expParams.Staircase.ThresholdGuessSD,expParams.Staircase.pThreshold, ...
              expParams.Staircase.Beta,expParams.Staircase.Delta,expParams.Staircase.Gamma,expParams.Staircase.Grain,...
              expParams.Staircase.Range);

%% Experiment Loop

RectLum = [128,128,128];
RecLum = [];

CondType = 1; 



if CondType == 1

for Counter = 1:20  

      QuestLum = QuestMean(StairFunc); %still in log units
      RectLumVal = ((10^(QuestMean(StairFunc))).*255)+CircLumVal; %outputs a intensity value in 0-1 range. Then convert to 0-255 range by multiplying by 255
        %the luminance of the circle is added to the rectangle lum which
        %theoreticlaly it would be presented on
      RectLum = repelem(RectLumVal,3); %repeat the number 3 times for RGB vlaue

    
    %STIMULUS PRESENTATION
    StartStim = GetSecs;
    TimeNow = StartStim;
    while TimeNow - StartStim < expParams.TrialDuration_s %within trial duration
        
        %DRAW GREY RECTANGLE
        Screen('FillRect',win,RectLum); %grey background
        
        Screen('Flip', win);
        
        %PRESENT TEST SPOT
        TimeNow = GetSecs;
        
    end %trial duration
    
    
    %RESPONSE LOOP - subj indicates if they saw the test spot
    RespLoop = 1;
    while RespLoop == 1
        
        %DRAW GREY RECTANGLE
        Screen('FillRect',win,[128,128,128]); %grey background
        
        %DRAW TEXT
        DrawFormattedText(win,'If you saw the test spot, press "Y". If you did not see the test spot press "A"','center','center',[255,255,255],[],[],1);
        %1 - flips text across the horizontal axis so text looks right side up when projected to eye
        
        Screen('Flip', win);
        
        %BUTTON PRESS CHECK
        GamePad = GamePadInput([]);
        if GamePad.buttonChange == 1 %Game pad button press check
            if GamePad.buttonY == 1 %subject saw the stimulus
                StairFunc = QuestUpdate(StairFunc,QuestLum,1); %updates the stair case
                %1 - subject saw the stimulus
                %SAVE LUMINANCE
                LumRec(1,Counter) = RectLumVal;
                QuestLumRec(1,Counter) = QuestLum;
                
                RespLoop = 0; %end loop
            end
            if GamePad.buttonA == 1 %subject did not see the stimulus
                StairFunc = QuestUpdate(StairFunc,QuestLum,0);
                 %0 - subj did not see the stimulus
                
                 
                RespLoop = 0; %end resp loop
            end
        end
    end %response loop
    
end
    %How do we know when the staircase has ended?
    
    % CondType = 0; %end condition loop
end %Grey Field Cond

sca;

