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
data.subjectID = GetWithDefault('Subject ID ', '10001R');
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


%% Stimulus & Experiment Variables

%TRIALS
expParams.TrialsPerCond = 40; %the number of staircases we do per condition
%**Not sure what this numb should be (bellow)
expParams.RespInStaircase = 10; %the number of responses allowed per staircase
expParams.NumbOfCond = 5;
expParams.TotalTrials = expParams.NumbOfCond.*expParams.TrialsPerCond;


%Circle diameter in visual angle
expParams.CircDiam_dg=7;
expParams.TestSpotDiam_dg = 0.38;
%Circle Luminance
CircLum = [128,128,128];
CircLumVal = CircLum(1,1); %needed for luminance adjustment of test spot

%STIMULUS VARIABLES IN PX
CircDiam_px=expParams.displayPixelsPerDegree.*expParams.CircDiam_dg;
TestSpotDiam_px = expParams.displayPixelsPerDegree.*expParams.TestSpotDiam_dg;

%FIXATION LINE VARIABLES - 4 tick marks will be on the circle to direct the 
%participant's gaze to the center of the circle 
FixLineWidth_px = 2;
FixLineLeangth_px = 100;
FixLinePos1_px = CircDiam_px./2;
FixLinePos2_px = (CircDiam_px./2)-FixLineLeangth_px;
FixLineRGB = [0,0,0];
%determine coordinates of the fixation lines
xCoords = [-FixLinePos1_px,-FixLinePos2_px,0,0,FixLinePos1_px,FixLinePos2_px,0,0];
yCoords = [0,0,FixLinePos1_px,FixLinePos2_px,0,0,-FixLinePos1_px,-FixLinePos2_px];
AllCoords = [xCoords; yCoords];

%GREATING OSCILLATION
 OneOcillation_sec = (1./expParams.GratingOscillationFrequency_Hz ); %time interval between each oscillation
 
 %TRIAL SEQUENCE SPECIFICATIONS
expParams.TrialDuration_s = 1.1;
expParams.TestSpotDur_s = 0.1;
expParams.PreTestSpotDur_s = 0.5;


%%%%%%%%%%%%%% EVENTUALLY CHANGE THESE VARIABLES *****%%%%%%%%%%%%%5
%STAIRCASE VARIABLES 
expParams.Staircase.ThresholdGuess = -2;
expParams.Staircase.ThresholdGuessSD = 3; %3 was recommended by PTB %SD assigned to the threshold guess
expParams.Staircase.pThreshold = 0.78; %probability of subj seeing the stim (threshold criterion)
expParams.Staircase.Beta = 3.5; %Parameter of Weibull psychometric function. Beta controls the steepness of the function
expParams.Staircase.Delta = 0.01; %Parameter of Weibull psychometric function. Delta is the fraction of trials the subj is guessing typically 0.01
expParams.Staircase.Gamma = 0.01; %Parameter of Weibull psychometric function. fraction of trials that will generate response 1 when intensity is negative infinity
expParams.Staircase.Grain = 0.01; %step size of the internal table, 0.01. ???
expParams.Staircase.Range = 5; %5 recommended by PTB. The difference bw the largest and smallet intensity that the intital table can store

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%TIMING - record time experiment started
data.StartTime = datestr(clock,'mm_dd_yy_HHMM');
data.EndTime = datestr(clock,'mm_dd_yy_HHMM');


%% Preparation to Draw Grating

%Make a matrix to draw white and black vertical lines to make the surround grating
%Determine width of one bar (white or black) in pixels
WidthOfOneBar_px = round((0.5./expParams.gratingSpatialFrequency).*expParams.displayPixelsPerDegree); %determine visual angle of a stripe and then pixels
BarNumb = 1+round((expParams.winXpx.*2)./WidthOfOneBar_px); %2.5 the number of bars across the screen rounded up.
%these bars will be cropped based on the adjustments made to center the circle
%add one bar to provide wiggle room for cropping the bar series at the correct start location

%Repeat correct RGB (white&black) values the width and height of window
twobars = repelem([255,0],WidthOfOneBar_px); %repeats 255 and 0 the width of one bar each to create a white and black bar
Grating = repmat(twobars,expParams.winYpx,BarNumb);%repeat numbers to make the bars repeat the height of the window
    %this provides room for cropping the stimulus during the adjustment of the circle position

%%%%%%%%%%%%%%%%% - **you will eventually want to load in the approapriate
%crop of the grating to match the previously saved position of the circle

%CROPING BAR SERIES TO FIT SCREEN AND FOR GRATING OSCILLATION
xStartCropPos = expParams.winXpx; %changed once you load in values. you will want to load this value in. it determines where the cropping begins
    %right now the crop begins in the middle of the array which we made twice the width of the screen
xEndCropPos = xStartCropPos+expParams.winXpx; %you will also want to load this in
yStartCropPos = 1; %you do not need to change the y position because the grating will look the same if moved up and down so you do not need to create that movemnet
GratingPos_Crop = Grating(yStartCropPos:expParams.winYpx,xStartCropPos:xEndCropPos); %crop Grating to fit the window width & height

%you will want to load values for the lasty pos and lastx pos

%%%%%%%%%%%%%%%%%%%%%%%%555

%%%%%%%%%%% - you will eventually not want to start out with the circle
% centered, you will want to load the previous circle location
Xpos = Xwincent; %making the x center of the window the center to which everything will be drawn
Ypos = Ywincent; %making the y center of the window the center to which everything will be drawn

%CIRC ADJUSTMENT VARIABLES
expParams.AdjustIncrement_px = 35;%30;
%%%%%%%%%%%%

%% Circle Adjustment Proceedure
%this will allow the subject to use the game controller to adjust the
%position of the stimulus so that it is in the center of the projection

%POSITION ADJUSTMENT INITATION
PadResp = 0;
while PadResp == 0 
    %DRAW GREY RECTANGLE
    Screen('FillRect',win,[128,128,128]); %grey background
    
    %DRAW TEXT
    %Screen('Preferences','DefaultFontSize',[12]); %does not work
    DrawFormattedText(win,'Stimulus Position Adjustment Procedure. Press any button to Continue','center','center',[],[],[],1);
    %1 - flips text across the horizontal axis so text looks right side up when projected to eye
    
    Screen('DrawingFinished',win);
    Screen('Flip',win);
    
    %GAME PAD CHECK
    GamePad = GamePadInput([]); %checks game pad
    if GamePad.buttonChange == 1 %any button pressed
        if GamePad.buttonLeftLowerTrigger == 1 %escape experiment
            CircAdjustLoop = 0; %variable to skip next loop
            FirstRun = 0; %variable to skip next loop
            ExptLoop = 0; %will not begin the experiment loop
            break %excit while loop

        else
            PadResp = 1; %out of while loop
            CircAdjustLoop = 1; %variable to begin next loop
        end
    end %button check
end


%ADJUSTING CIRCLE POSITION 
%subject uses Y,B,X,A on the game pad to adjust the position of the circle. The circle
%is be moved by adjusting the center points to which the shapes are
%drawn. We want the grating to be lined up in the same way relative to the 
%circle no matter the position of the circle. To do this the 
%image is cropped differently each time the circle moves so it appears the 
%grating is moving with the circle.
%*****There should eventually be a way to load previous locations of the circle 


while CircAdjustLoop == 1  %adjusting the circle.
    
    %DRAW GRATING
    GratingPos_Txt = Screen('MakeTexture',win,GratingPos_Crop);%makes grating approapriate size
    Screen('DrawTexture',win,GratingPos_Txt); %draws the grating texture to the window
   
    %DRAW CIRCLE
    CircPos = CenterRectOnPointd([0, 0, CircDiam_px, CircDiam_px],Xpos,Ypos); %centers the circle on a point
    Screen('FillOval',win,CircLum,CircPos); %the circle is drawn in a box of the width and height of the circle
    
    %DRAW FIXATION LINES
    Screen('DrawLines',win,AllCoords,FixLineWidth_px,FixLineRGB,[Xpos,Ypos]);
    
    %INSTRUCTIONS
    DrawFormattedText(win,'Use buttons Y,B,X, and A to center the circle',(Xpos-(CircDiam_px./2)+20),(Ypos-60),[],[],[],1);
    DrawFormattedText(win,'Once centered, press the right upper trigger',(Xpos-(CircDiam_px./2)+20),(Ypos+40),[],[],[],1);
    %corrdinates used to center the text within the circle
    %1 - flips the text upside down
    
    Screen('DrawingFinished',win); %all items drawn to screen. optimizes drawing.
    Screen('Flip', win);
    
    %BUTTON CHECK & CIRC POSITION ADJUSTMENT
    GamePad = GamePadInput([]); %checks game pad
    if GamePad.buttonChange == 1 %Game pad button press check
        if GamePad.buttonY == 1 %Y button pressed. Up movement of circ
            %CIRCLE POSITION
            Ypos = Ypos + expParams.AdjustIncrement_px; %note: it is flipped when on a window screen
            %GRATING POSITION - you don't need to adjust this because the grating does not change vertically
        end
        if GamePad.buttonA == 1 %A button pressed. Down movement
            %CIRCLE POSITION
            Ypos = Ypos - expParams.AdjustIncrement_px;
            %GRATING POSITION - you don't need to adjust this because the grating does not change vertically
        end
        if GamePad.buttonX == 1 %X button press. leftward movement
            %CIRCLE ADJUSTMENT
            Xpos = Xpos - expParams.AdjustIncrement_px;
            %GRATING ADJUSTMENT
            xStartCropPos = xStartCropPos + expParams.AdjustIncrement_px; %sets the horizontal cropping of the grating to a value that will
            %make it appear like the grating position is moving with the circle
            xEndCropPos = xEndCropPos + expParams.AdjustIncrement_px;
            GratingPos_Crop = Grating(yStartCropPos:expParams.winYpx, xStartCropPos: xEndCropPos);
            
        end
        if GamePad.buttonB == 1 %B button press. Rightward movement
            %CIRCLE ADJUSTMENT
            Xpos = Xpos + expParams.AdjustIncrement_px;
            %GRATING ADJUSTMENT
            xStartCropPos = xStartCropPos - expParams.AdjustIncrement_px;%sets the horizontal cropping of the grating to a value that will
            %make it appear like the grating position is moving with the circle
            xEndCropPos = xEndCropPos - expParams.AdjustIncrement_px;
            GratingPos_Crop = Grating(yStartCropPos:expParams.winYpx, xStartCropPos:xEndCropPos);
        end
 
        %POSITION SELECTED
        if GamePad.buttonRightUpperTrigger == 1
            %END LOOP
            CircAdjustLoop = 0;
            
            %RECALCULATE CENTERED CIRCLE
            CircPos = CenterRectOnPointd([0, 0, CircDiam_px, CircDiam_px],Xpos,Ypos); %centers the circle on a point
            %have to recaclulate these to get the most recent circle position
            
            %RECALCULATE CENTER OF TEST SPOT
            TestSpotPos = CenterRectOnPointd([0, 0, TestSpotDiam_px, TestSpotDiam_px],Xpos,Ypos); %centers the test spot with the circle
            
            %SAVE ADJUSTMENT
            expParams.xStartGratingPos = xStartCropPos; %information for cropping grating
            expParams.xEndGratingPos = xEndCropPos;%information for cropping the grating
            
            expParams.CircXpos = Xpos; %x position of the circle
            expParams.CircYpos = Ypos; %y position of the circle
            
            %NEXT LOOP VARIABLE
            FirstRun = 1; %used to being next loop
        end
        
        %ESCAPE EXPERIEMENT
        if GamePad.buttonLeftLowerTrigger == 1
            FirstRun = 0; %get out of first experiment loop
            ExptLoop = 0; %skips experiment loop
            CircAdjustLoop = 0;
        end
    end %game pad check
end




%% Prepare for Main Experiment - Grating Oscillation Set-up

%DETERMINE GRATING SERIES 1 & 2
%to create an oscillation between white and black bars, we will create two
%different grating images by cropping the grating at different points and
%flipping back and forth between these images

%GRATING 1
Grating_Crop1 = GratingPos_Crop; %the crop of the grating chosen in the adjustment proceedure

%GRATING 2
%Determines how much to crop bar series 2 to simulate an oscillation of the specified period
OscillationAmp = expParams.GratingOscillationAmplitude.*(2.*WidthOfOneBar_px); %determines one oscilation cycle in pixels. Basically where to start the x crop of the second grating
Grating_Crop2 = Grating(yStartCropPos:expParams.winYpx, (xStartCropPos+OscillationAmp):(xEndCropPos+OscillationAmp)); %crops the second bar series

%% Prepare for Main Experiment - Condition Order & Staircase
%The conditions should be interleaved
%Experimental Conditions: (1) Grey Field (2) Flickering grating at 0Hz,   
%(3) 4Hz, (4) 10Hz, (5) 15Hz [these numbers will be used to label these conditions. 

TrialArray = repelem([1,2,3,4,5],expParams.TrialsPerCond); %repeats numbers the number of trials per conditions
data.RandTrialSequence = TrialArray(randperm(length(TrialArray))); %shuffels numbers in the array


%STAIRCASE
StairFunc_OG = QuestCreate(expParams.Staircase.ThresholdGuess,expParams.Staircase.ThresholdGuessSD,expParams.Staircase.pThreshold, ...
              expParams.Staircase.Beta,expParams.Staircase.Delta,expParams.Staircase.Gamma,expParams.Staircase.Grain,...
              expParams.Staircase.Range);
StairFunc = StairFunc_OG; %allows the each staircase to start new without having to make the staircase over again.
          
%% Experimental loop

%Experimental Conditions: (1) Grey Field (2) Flickering grating at 0Hz,   
%(3) 4Hz, (4) 10Hz, (5) 15Hz [these numbers will be used to label these
%conditions. Each conditoin will have 40 trials (40 staircases)

%Experiment Progression: Grey background ask participant to initiate
%proceedure. 500ms of grating condition 100ms of test spot presentation
%followed by 500ms of grating condition again. Another grey screen asking
%if participant saw the test spot "Yes" or "No". After response another
%grey screen that asked participant to initiate next presentation. The
%luminance of the test spot will be adjusted in each run using Quest to find 
%the threshold for that condition.

%BEGIN EXPERIMENT SCREEN
while FirstRun == 1 %first run of experiment
   
    %DRAW GREY RECTANGLE
    Screen('FillRect',win,[128,128,128]); %grey background
    
    %DRAW TEXT
    DrawFormattedText(win,'Main Experiment. Press any button to Continue',(Xpos-(CircDiam_px./2)+20),Ypos,[],[],[],1);
    %1 - flips text across the horizontal axis so text looks right side up when projected to eye
    %Xpos and Ypos are the center position for the circle. the text is being drawn in the middle of the circle
    
    Screen('DrawingFinished',win);
    Screen('Flip',win);
    
    %GAME PAD CHECK
    GamePad = GamePadInput([]); %checks game pad
    if GamePad.buttonChange == 1 %Game pad button press check
        FirstRun = 0; %out of while loop
        ExptLoop = 1; %will begin next loop
        EscapeExp = 0; %means that you will not escape the experiment
        
        %ESCAPE EXPERIMENT
        if GamePad.buttonLeftLowerTrigger == 1
            ExptLoop = 0; %will not begin the experiment loop
            break %excit while loop
        end
    end %game pad check
end

%CONDITION COUNTERS 
GreyCond_Counter = 0;
Grating0Hz_Counter = 0;
Grating4Hz_Counter = 0;
Grating10Hz_Counter = 0;
Grating15Hz_Counter = 0;

%EXPERIMENT LOOP
FirstLoop = 0;
TrialCounter =0;
while ExptLoop == 1
    
    
    %%%%%%%%%%%% ** ADD BACK IN LATER %%%%%%%%%%%%5
    %     %DETERMINE NEXT CONDITION TYPE
    TrialCounter = TrialCounter + 1; %counts how many conditions we have done
    %     CondType = data.RandTrialSequence(TrialCounter); %goes through the random condition array to choose the next condition type
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %RESET STIARCASE
    StairFunc = StairFunc_OG; %allows the each staircase to start new without having to make the staircase over again.
    
    %OTHER VARIABLES
    InitiateNextTrial = 0; %used to draw grey intitiate trial screen
    
    %%%%***REMOVE LEATER%%
    %CondType = 2;
    data.RandTrialOrder = [2 1 1 2];
    CondType = data.RandTrialSequence(TrialCounter);
    expParams.RespInStaircase = 1;
    expParams.TotalTrials = length(data.RandTrialSequence);
    %%%%%%%%%%
    
    
    
    %%%%%%%%%%%%%%%%%% Grey Field Condition %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    if CondType == 1
        
        GreyCond_Counter = GreyCond_Counter + 1;
        
        %STAIRCASE LOOP
        for CurrentStep = 1:expParams.RespInStaircase+1
            
            %DETERMINE TEST SPOT LUMINANCE
            SpotLum_logU = QuestMean(StairFunc); %still in log units
            SpotLumVal = ((10^(QuestMean(StairFunc))).*255)+CircLumVal; %outputs a intensity value in 0-1 range. Then convert to 0-255 range by multiplying by 255
            %the luminance of the suround circle is added to the spot lum which it will be presented on
            SpotLum = repelem(SpotLumVal,3); %repeat the number 3 times for RGB vlaue
            
            
            StartStim = GetSecs;
            TimeNow = StartStim;
            %STIMULUS PRESENTATION
            while TimeNow - StartStim < expParams.TrialDuration_s && EscapeExp == 0 %within trial duration
                
                %DRAW GREY RECTANGLE
                Screen('FillRect',win,[128,128,128]); %grey background
                
                %DRAW FIXATION LINES
                Screen('DrawLines',win,AllCoords,FixLineWidth_px,FixLineRGB,[Xpos,Ypos]);
                
                Screen('Flip', win);
                
                TimeNow = GetSecs;
                
                %PRESENT TEST SPOT
                %while TimeNow < (StartStim + expParams.PreTestSpotDur_s + expParams.TestSpotDur_s) &&  TimeNow > (StartStim + expParams.PreTestSpotDur_s)
                while TimeNow > (StartStim + expParams.PreTestSpotDur_s) && TimeNow < (StartStim + expParams.PreTestSpotDur_s + expParams.TestSpotDur_s) && EscapeExp == 0
                    
                    %DRAW GREY RECTANGLE
                    Screen('FillRect',win,[128,128,128]); %grey background
                    
                    %DRAW FIXATION LINES
                    Screen('DrawLines',win,AllCoords,FixLineWidth_px,FixLineRGB,[Xpos,Ypos]);
                    
                    %DRAW TEST SPOT
                    Screen('FillOval',win,SpotLum,TestSpotPos); %the circle is drawn in a box of the width and height of the circle
                    
                    Screen('Flip', win);
                    
                    TimeNow = GetSecs;
                    
                end %test spot presentation
            end %trial duration
            
            
            %RESPONSE LOOP - subj indicates if they saw the test spot
            RespLoop = 1;
            while RespLoop == 1
                
                %DRAW GREY RECTANGLE
                Screen('FillRect',win,[128,128,128]); %grey background
                
                %DRAW TEXT
                DrawFormattedText(win,'If you saw the test spot, press "Y". If you did not see the test spot press "A"',(Xpos-(CircDiam_px./2)+20),Ypos,[],[],[],1);
                %1 - flips text across the horizontal axis so text looks right side up when projected to eye
                
                Screen('Flip', win);
                
                %BUTTON PRESS CHECK
                GamePad = GamePadInput([]);
                if GamePad.buttonChange == 1 %Game pad button press check
                    if GamePad.buttonY == 1 %subject saw the stimulus
                        
                        %UPDATE STAIRCASE
                        StairFunc = QuestUpdate(StairFunc,SpotLum_logU,1); %updates the stair case
                        %1 - subject saw the stimulus
                        
                        %SAVE LUMINANCE
                        data.TestLuminance_GreyField(CurrentStep,GreyCond_Counter) = SpotLumVal;
                        data.TestLuminance_logU_GreyField(CurrentStep,GreyCond_Counter) = SpotLum_logU;
                        RespLoop = 0; %end loop
                        InitiateNextTrial = 1;
                    end
                    if GamePad.buttonA == 1 %subject did not see the stimulus
                        
                        %UPDATE STAIRCASE
                        StairFunc = QuestUpdate(StairFunc,SpotLum_logU,0); %updates the stair case
                        %1 - subject saw the stimulus
                        
                        %SAVE LUMINANCE
                        data.TestLuminance_GreyField(CurrentStep,GreyCond_Counter) = SpotLumVal;
                        data.TestLuminance_logU_GreyField(CurrentStep,GreyCond_Counter) = SpotLum_logU;
                        RespLoop = 0; %end resp loop
                        InitiateNextTrial = 1; %initates a grey screen and next trial
                    end
                    
                    %ESCAPE EXPERIMENT
                    if GamePad.buttonLeftLowerTrigger == 1
                        InitiateNextTrial = 0; %prevents presentation of grey screen
                        RespLoop = 0; %end loop
                        CurrentStep = expParams.RespInStaircase+1; %break step loop
                        CondType = 0;
                        ExptLoop = 0;%end experiment loop
                        EscapeExp = 1;
                    end
                    
                    %GREY SCREEN BEFORE NEXT TRIAL
                    if InitiateNextTrial == 1 %grey screen before next trial
                        
                        %DRAW GREY RECTANGLE
                        Screen('FillRect',win,[128,128,128]); %grey background
                        
                        %DRAW TEXT
                        DrawFormattedText(win,'Press any button to continue to the next run',(Xpos-(CircDiam_px./2)+20),Ypos,[],[],[],1);
                        %1 - flips text across the horizontal axis so text looks right side up when projected to eye
                        
                        Screen('DrawingFinished',win);
                        Screen('Flip',win);
                        
                        %GAME PAD CHECK
                        GamePad = GamePadInput([]); %checks game pad
                        if GamePad.buttonChange == 1 %any button pressed
                            InitiateNextTrial = 0; %end initiate trial loop
                        end
                    end %grey screen
                end%button press check
            end %response loop
            
        end %staircase loop
        
        %RECORD THE COMPLETED TRIAL - if subj ends mid experiment this will tell
        %us which conditions the subject has completed
        if EscapeExp == 0 %subject has not escaped the experiment
            data.TrialSequenceCompleted(1,TrialCounter) = CondType; %records the condition sequence that has been completed
        end
        %**How do we know when the staircase has ended?
        
        CondType = 0; %end condition loop
    end %Grey Field Cond
    
    %%%%%%%%%%%%%%%%%%%%%%%%% GRATING NO FLICKER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    if CondType == 2
        
        %CONDITION COUNTER
        Grating0Hz_Counter = Grating0Hz_Counter + 1; %keeps track of how many times we have gone through this condition
        
        %STAIRCASE LOOP
        for CurrentStep = 1:expParams.RespInStaircase+1
            
            %DETERMINE TEST SPOT LUMINANCE
            SpotLum_logU = QuestMean(StairFunc); %still in log units
            SpotLumVal = ((10^(QuestMean(StairFunc))).*255)+CircLumVal; %outputs a intensity value in 0-1 range. Then convert to 0-255 range by multiplying by 255
            %the luminance of the suround circle is added to the spot lum which it will be presented on
            SpotLum = repelem(SpotLumVal,3); %repeat the number 3 times for RGB vlaue
            
            StartStim = GetSecs;
            TimeNow = StartStim;
            %STIMULUS PRESENTATION
            while TimeNow - StartStim < expParams.TrialDuration_s && EscapeExp == 0 %within trial duration
                
                %DRAW BAR SERIES 1
                Grating_Txt1 = Screen('MakeTexture',win,Grating_Crop1);
                Screen('DrawTexture',win,Grating_Txt1);
                
                %DRAW CIRCLE
                Screen('FillOval',win,CircLum,CircPos); %the circle is drawn in a box of the width and height of the circle
                
                %DRAW FIXATION LINES
                Screen('DrawLines',win,AllCoords,FixLineWidth_px,FixLineRGB,[Xpos,Ypos]);
                
                Screen('Flip', win);
                
                TimeNow = GetSecs;
                
                %PRESENT TEST SPOT
                while TimeNow > (StartStim + expParams.PreTestSpotDur_s) && TimeNow < (StartStim + expParams.PreTestSpotDur_s + expParams.TestSpotDur_s) && EscapeExp == 0
                    
                    %DRAW GRATING
                    Screen('DrawTexture',win,Grating_Txt1);
                    
                    %DRAW CIRCLE
                    Screen('FillOval',win,CircLum,CircPos); %the circle is drawn in a box of the width and height of the circle
                    
                    %DRAW FIXATION LINES
                    Screen('DrawLines',win,AllCoords,FixLineWidth_px,FixLineRGB,[Xpos,Ypos]);
                    
                    %DRAW TEST SPOT
                    Screen('FillOval',win,SpotLum,TestSpotPos); %the circle is drawn in a box of the width and height of the circle
                    
                    Screen('Flip', win);
                    
                    TimeNow = GetSecs;
                    
                end %test spot presentation
            end %trial duration
            
            
            %RESPONSE LOOP - subj indicates if they saw the test spot
            RespLoop = 1;
            while RespLoop == 1
                
                %DRAW GREY RECTANGLE
                Screen('FillRect',win,[128,128,128]); %grey background
                
                %DRAW TEXT
                DrawFormattedText(win,'If you saw the test spot, press "Y". If you did not see the test spot press "A"',(Xpos-(CircDiam_px./2)+20),Ypos,[],[],[],1);
                %1 - flips text across the horizontal axis so text looks right side up when projected to eye
                
                Screen('Flip', win);
                
                %BUTTON PRESS CHECK
                GamePad = GamePadInput([]);
                if GamePad.buttonChange == 1 %Game pad button press check
                    if GamePad.buttonY == 1 %subject saw the stimulus
                        
                        %UPDATE STAIRCASE
                        StairFunc = QuestUpdate(StairFunc,SpotLum_logU,1); %updates the stair case
                        %1 - subject saw the stimulus
                        
                        %SAVE LUMINANCE
                        data.TestLuminance_Grating0Hz(CurrentStep,Grating0Hz_Counter) = SpotLumVal;
                        data.TestLuminance_logU_Grating0Hz(CurrentStep,Grating0Hz_Counter) = SpotLum_logU;
                        RespLoop = 0; %end loop
                        InitiateNextTrial = 1;
                    end
                    if GamePad.buttonA == 1 %subject did not see the stimulus
                        
                        %UPDATE STAIRCASE
                        StairFunc = QuestUpdate(StairFunc,SpotLum_logU,0); %updates the stair case
                        %1 - subject saw the stimulus
                        
                        %SAVE LUMINANCE
                        data.TestLuminance_Grating0Hz(CurrentStep,Grating0Hz_Counter) = SpotLumVal; %each column will be a different staircase
                        data.TestLuminance_logU_Grating0Hz(CurrentStep,Grating0Hz_Counter) = SpotLum_logU;
                        RespLoop = 0; %end resp loop
                        InitiateNextTrial = 1; %initates a grey screen and next trial
                    end
                    
                    %ESCAPE EXPERIMENT
                    if GamePad.buttonLeftLowerTrigger == 1
                        InitiateNextTrial = 0; %prevents presentation of grey screen
                        RespLoop = 0; %end loop
                        CurrentStep = expParams.RespInStaircase+1; %break step loop
                        CondType = 0;
                        ExptLoop = 0;%end experiment loop
                        EscapeExp = 1;
                    end
                    
                    %GREY SCREEN BEFORE NEXT TRIAL
                    if InitiateNextTrial == 1 %grey screen before next trial
                        %DRAW GREY RECTANGLE
                        Screen('FillRect',win,[128,128,128]); %grey background
                        
                        %DRAW TEXT
                        DrawFormattedText(win,'Press any button to continue to the next run',(Xpos-(CircDiam_px./2)+20),Ypos,[],[],[],1);
                        %1 - flips text across the horizontal axis so text looks right side up when projected to eye
                        
                        Screen('DrawingFinished',win);
                        Screen('Flip',win);
                        
                        %GAME PAD CHECK
                        GamePad = GamePadInput([]); %checks game pad
                        if GamePad.buttonChange == 1 %any button pressed
                            InitiateNextTrial = 0; %end initiate trial loop
                        end
                    end %grey screen
                end%button press check
            end %response loop
            
        end %staircase loop
        
        %RECORD THE COMPLETED TRIAL - if subj ends mid experiment this will tell
        %us which conditions the subject has completed
        if EscapeExp == 0 %subject has not escaped the experiment
            data.TrialSequenceCompleted(1,TrialCounter) = CondType; %records the condition sequence that has been completed
        end
        
        CondType = 0; %end condition loop
    end %Grating No Flicker
    
    
    % %%%%%%%%%%%%%%% THESE ARE THE NEXT CONDITIONS %%%%%%%%%%%%5
    %
    % if CondType == 3 %Grating Flicker 4Hz
    % end
    % if CondType == 4 %Grating Flicker 10Hz
    % end
    % if CondType == 5 %Grating Flicker 15Hz
    % end
    
    
    
    
    %ENDING EXPERIMENT - completed all the trials
    if TrialCounter == expParams.TotalTrials
        ExptLoop = 0;
        
        %DRAW GREY RECTANGLE
        Screen('FillRect',win,[128,128,128]); %grey background
        
        %DRAW TEXT
        DrawFormattedText(win,'Experiment Completed',(Xpos-(CircDiam_px./2)+20),Ypos,[],[],[],1);
        %1 - flips text across the horizontal axis so text looks right side up when projected to eye
        
        Screen('DrawingFinished',win);
        Screen('Flip',win);
    end
    
end %Experiment Loop

 sca;



 %% Save Data & Calculations
 
 TotTrial = num2str(expParams.TotalTrials);
 savdir = 'D:\Tuten_Lab\Expt_Masking\Code\TutenLabExperiments\Data\';
 data.EndTime = datestr(clock,'mm_dd_yy_HHMM');
 save_file = strcat(data.subjectID,'_',TotTrial,'TotalTrials_',data.StartTime,'.mat');
 filename = [savdir save_file];
 save(filename,'data','expParams');
 
 
 
 
 %if experiment has been ended prematurely
 if TrialCounter < expParams.TotalTrials
     TotTrial = num2str(expParams.TotalTrialNum);
     
     savdir = 'D:\Tuten_Lab\Expt_Masking\Code\TutenLabExperiments\Data\';
     data.EndTime = datestr(clock,'mm_dd_yy_HHMM');
     save_file = strcat(data.subjectID,'_','notcomplete','_',TotTrial,'TotalTrials_',data.StartTime,'.mat');
     filename = [savdir save_file];
     save(filename,'data','expParams');
 end









