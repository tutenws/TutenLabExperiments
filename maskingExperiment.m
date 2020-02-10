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

%% Sinc test

% SKIP SYNC TEST
Screen('Preference', 'SkipSyncTests', 1); 
%it does not seem to be actually skipping the sync test 


%% Start by collecting experiment parameters from the command window

%SUBJ ID
data.subjectID = GetWithDefault('Subject ID ', '10001R');

%NUMB OF STAIRCASES
expParams.NumbOfStaircasesPerCond = GetWithDefault('Number of staircases per condition', 2);

%TRIALS
expParams.TrialsPerStaircase = GetWithDefault('Number of trials per stiarcase', 40); 

%PIXEL PER DEGREE
expParams.displayPixelsPerDegree = GetWithDefault('Enter display scaling (ppd) ', 75);

%GRATING SPATIAL FREQUENCY       
expParams.gratingSpatialFrequency = GetWithDefault('Enter grating spatial frequency (cycles/deg) ', 0.53);

%OSCILLATION AMPLITUDE - of gratingTrial
expParams.GratingOscillationAmplitude = GetWithDefault('Oscillation Amplitude (Period)', 0.5);%oscilating one period would not change the image


%% Stimulus setup

[expParams,st] = ExperimentParams(expParams); %runs function with all of the experiment parameters

%LOAD PREVIOUS CIRC POSITION
load('LastCircPos_px.mat'); %a structure with the x and y variables in pixes of the center of the circle
XCircPos = LastCircPos_px.x; %x val in pix of center of circle
YCircPos = LastCircPos_px.y; %y val in pix of center of circle


%TIMING - record time experiment started
data.StartTime = datestr(clock,'mm_dd_yy_HHMM');


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
expParams.WinWidth_dg=expParams.winXpx./expParams.displayPixelsPerDegree;
expParams.WinHeight_dg=expParams.winYpx./expParams.displayPixelsPerDegree;

%PIXELS IN THE CENTER OF THE WINDOW
[Xwincent, Ywincent] = RectCenter([0 0 expParams.winXpx expParams.winYpx]);



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

%CROPING BAR SERIES TO FIT SCREEN AND FOR GRATING OSCILLATION
xStartCropPos = (expParams.winXpx)./2; %begin crop at half a screen width in. Will make the position of the position of the grating relative to the circle constant
xEndCropPos = xStartCropPos+expParams.winXpx; %ends the crop at width of screen from start crop
yStartCropPos = 1; %you do not need to change the y position because the grating will look the same if moved up and down so you do not need to create that movemnet
GratingPos_Crop = Grating(yStartCropPos:expParams.winYpx,xStartCropPos:xEndCropPos); %crop Grating to fit the window width & height


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
    DrawFormattedText(win,'Stimulus Position Adjustment Procedure. Press any button to Continue','center','center',[],[],[],0);
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


while CircAdjustLoop == 1  %adjusting the circle.
    
    %DRAW GRATING
    GratingPos_Txt = Screen('MakeTexture',win,GratingPos_Crop);%makes grating approapriate size
    Screen('DrawTexture',win,GratingPos_Txt); %draws the grating texture to the window
   
    %DRAW CIRCLE
    CircPos = CenterRectOnPointd([0, 0, expParams.CircDiam_px, expParams.CircDiam_px],XCircPos,YCircPos); %centers the circle on a point
    Screen('FillOval',win,expParams.CircLum,CircPos); %the circle is drawn in a box of the width and height of the circle
    
    %DRAW FIXATION LINES
    Screen('DrawLines',win,st.AllCoords,expParams.FixLineWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
    
    %INSTRUCTIONS
    DrawFormattedText(win,'Use buttons Y,B,X, and A to center the circle',(XCircPos-(expParams.CircDiam_px./2)+20),(YCircPos-60),[],[],[],0);
    DrawFormattedText(win,'Once centered, press the right upper trigger',(XCircPos-(expParams.CircDiam_px./2)+20),(YCircPos+40),[],[],[],0);
    %corrdinates used to center the text within the circle
    
    Screen('DrawingFinished',win); %all items drawn to screen. optimizes drawing.
    Screen('Flip', win);
    
    %BUTTON CHECK & CIRC POSITION ADJUSTMENT
    GamePad = GamePadInput([]); %checks game pad
    if GamePad.buttonChange == 1 %Game pad button press check
        if GamePad.buttonY == 1 %Y button pressed. Up movement of circ
            %CIRCLE POSITION
            YCircPos = YCircPos - expParams.AdjustIncrement_px; %note: it is flipped when on a window screen
            %GRATING POSITION - you don't need to adjust this because the grating does not change vertically
        end
        if GamePad.buttonA == 1 %A button pressed. Down movement
            %CIRCLE POSITION
            YCircPos = YCircPos + expParams.AdjustIncrement_px;
            %GRATING POSITION - you don't need to adjust this because the grating does not change vertically
        end
        if GamePad.buttonX == 1 %X button press. leftward movement
            %CIRCLE ADJUSTMENT
            XCircPos = XCircPos - expParams.AdjustIncrement_px;
            %GRATING ADJUSTMENT
            xStartCropPos = xStartCropPos + expParams.AdjustIncrement_px; %sets the horizontal cropping of the grating to a value that will
            %make it appear like the grating position is moving with the circle
            xEndCropPos = xEndCropPos + expParams.AdjustIncrement_px;
            GratingPos_Crop = Grating(yStartCropPos:expParams.winYpx, xStartCropPos: xEndCropPos);
            
        end
        if GamePad.buttonB == 1 %B button press. Rightward movement
            %CIRCLE ADJUSTMENT
            XCircPos = XCircPos + expParams.AdjustIncrement_px;
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
            CircPos = CenterRectOnPointd([0, 0, expParams.CircDiam_px, expParams.CircDiam_px],XCircPos,YCircPos); %centers the circle on a point
            %have to recaclulate these to get the most recent circle position
            
            %RECALCULATE CENTER OF TEST SPOT
            TestSpotPos = CenterRectOnPointd([0, 0, expParams.TestSpotDiam_px, expParams.TestSpotDiam_px],XCircPos,YCircPos); %centers the test spot with the circle
            
            %SAVE ADJUSTMENT
            expParams.CircXpos = XCircPos; %x position of the circle saved in a struct for this participant
            expParams.CircYpos = YCircPos; %y position of the circle
            LastCircPos_px.x = XCircPos; %saved in structure for next time you run expt
            LastCircPos_px.y = YCircPos; %saved in structure for next time you run expt
            
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
%make texture to be drawn later
Grating_Txt1 = Screen('MakeTexture',win,Grating_Crop1);

%GRATING 2
%Determines how much to crop bar series 2 to simulate an oscillation of the specified period
OscillationAmp = expParams.GratingOscillationAmplitude.*(2.*WidthOfOneBar_px); %determines one oscilation cycle in pixels. Basically where to start the x crop of the second grating
Grating_Crop2 = Grating(yStartCropPos:expParams.winYpx, (xStartCropPos+OscillationAmp):(xEndCropPos+OscillationAmp)); %crops the second bar series
%create a texture
Grating_Txt2 = Screen('MakeTexture',win,Grating_Crop2); %this will be drawn later

%% Prepare for Main Experiment - Condition Order & Staircase
%The conditions should be interleaved
%Experimental Conditions: (1) Grey Field (2) Flickering grating at 0Hz,   
%(3) 4Hz, (4) 10Hz, (5) 15Hz [these numbers will be used to label these conditions. 

TrialArray = repelem([1,2,3,4,5],expParams.TrialsPerStaircase); %repeats numbers the number of trials per conditions
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
    DrawFormattedText(win,'Main Experiment. Press any button to Continue',(XCircPos-(expParams.CircDiam_px./2)+20),YCircPos,[],[],[],0);
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
    data.RandTrialSequence = [1];
    CondType = data.RandTrialSequence(TrialCounter);
    expParams.RespInStaircase = 2;
    expParams.TotalTrials = length(data.RandTrialSequence);
    %%%%%%%%%%
    
    
    
    %%%%%%%%%%%%%%%%%% Grey Field Condition %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    if CondType == 1
        
        GreyCond_Counter = GreyCond_Counter + 1;
        
        %STAIRCASE LOOP
        for CurrentStep = 1:expParams.RespInStaircase
            
            %DETERMINE TEST SPOT LUMINANCE
            SpotLum_logU = QuestMean(StairFunc); %still in log units
            SpotLumVal = ((10^(QuestMean(StairFunc))).*255)+st.CircLumVal; %outputs a intensity value in 0-1 range. Then convert to 0-255 range by multiplying by 255
            %the luminance of the suround circle is added to the spot lum which it will be presented on
            SpotLum = repelem(SpotLumVal,3); %repeat the number 3 times for RGB vlaue
            
            
            StartStim = GetSecs;
            TimeNow = StartStim;
            FirstSpotLoop = 1;
            %STIMULUS PRESENTATION
            while TimeNow - StartStim < expParams.TrialDuration_s && EscapeExp == 0 %within trial duration
                
                %DRAW GREY RECTANGLE
                Screen('FillRect',win,[128,128,128]); %grey background
                
                %DRAW FIXATION LINES
                Screen('DrawLines',win,st.AllCoords,expParams.FixLineWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
                
                Screen('Flip', win);
                
                TimeNow = GetSecs;
               
                %PRESENT TEST SPOT
                %while TimeNow < (StartStim + expParams.PreTestSpotDur_s + expParams.TestSpotDur_s) &&  TimeNow > (StartStim + expParams.PreTestSpotDur_s)
                while TimeNow > (StartStim + expParams.PreTestSpotDur_s) && TimeNow < (StartStim + expParams.PreTestSpotDur_s + expParams.TestSpotDur_s) && EscapeExp == 0
                    
                    %DRAW GREY RECTANGLE
                    Screen('FillRect',win,[128,128,128]); %grey background
                    
                    %DRAW FIXATION LINES
                    Screen('DrawLines',win,st.AllCoords,expParams.FixLineWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
                    
                    %BEEPER - indicate test spot is about to be presented
                    if FirstSpotLoop == 1
                        Beeper(expParams.TestBeepFq,expParams.TestBeepVol,expParams.TestBeepDur_s);
                        FirstSpotLoop = 0;
                    end
                    
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
                DrawFormattedText(win,'If you saw the test spot, press "Y". If you did not see the test spot press "A"',(XCircPos-(expParams.CircDiam_px./2)+20),YCircPos,[],[],[],0);
                %1 - flips text across the horizontal axis so text looks right side up when projected to eye
                
                Screen('Flip', win);
                
                %BUTTON PRESS CHECK
                GamePad = GamePadInput([]);
                if GamePad.buttonChange == 1 %Game pad button press check
                    if GamePad.buttonY == 1 %subject saw the stimulus
                        
                        %UPDATE STAIRCASE
                        StairFunc = QuestUpdate(StairFunc,SpotLum_logU,1); %updates the stair case
                        %1 - subject saw the stimulus
                        
                        %RESPONSE BEEP - to indicate response has been recorded
                        Beeper(expParams.RespBeepFq,expParams.RespBeepVol,expParams.RespBeepDur_s);
                        
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
                        
                        %RESPONSE BEEP - to indicate response has been recorded
                        Beeper(expParams.RespBeepFq,expParams.RespBeepVol,expParams.RespBeepDur_s);
                        
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
    end %Grey Field Cond
    
    %%%%%%%%%%%%%%%%%%%%%%%%% GRATING NO FLICKER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    if CondType == 2
        
        %CONDITION COUNTER
        Grating0Hz_Counter = Grating0Hz_Counter + 1; %keeps track of how many times we have gone through this condition
        
        %STAIRCASE LOOP
        for CurrentStep = 1:expParams.RespInStaircase
            
            %DETERMINE TEST SPOT LUMINANCE
            SpotLum_logU = QuestMean(StairFunc); %still in log units
            SpotLumVal = ((10^(QuestMean(StairFunc))).*255)+st.CircLumVal; %outputs a intensity value in 0-1 range. Then convert to 0-255 range by multiplying by 255
            %the luminance of the suround circle is added to the spot lum which it will be presented on
            SpotLum = repelem(SpotLumVal,3); %repeat the number 3 times for RGB vlaue
            
            FirstSpotLoop = 1;
            StartStim = GetSecs;
            TimeNow = StartStim;
            %STIMULUS PRESENTATION
            while TimeNow - StartStim < expParams.TrialDuration_s && EscapeExp == 0 %within trial duration
                
                %DRAW BAR SERIES 1
                Screen('DrawTexture',win,Grating_Txt1);
                
                %DRAW CIRCLE
                Screen('FillOval',win,expParams.CircLum,CircPos); %the circle is drawn in a box of the width and height of the circle
                
                %DRAW FIXATION LINES
                Screen('DrawLines',win,st.AllCoords,expParams.FixLineWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
                
                Screen('Flip', win);
                
                TimeNow = GetSecs;
                
                %PRESENT TEST SPOT
                while TimeNow > (StartStim + expParams.PreTestSpotDur_s) && TimeNow < (StartStim + expParams.PreTestSpotDur_s + expParams.TestSpotDur_s) && EscapeExp == 0
                    
                    %DRAW GRATING
                    Screen('DrawTexture',win,Grating_Txt1);
                    
                    %DRAW CIRCLE
                    Screen('FillOval',win,expParams.CircLum,CircPos); %the circle is drawn in a box of the width and height of the circle
                    
                    %DRAW FIXATION LINES
                    Screen('DrawLines',win,st.AllCoords,expParams.FixLineWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
                    
                    %BEEPER - indicate test spot is about to be presented
                    if FirstSpotLoop == 1
                        Beeper(expParams.TestBeepFq,expParams.TestBeepVol,expParams.TestBeepDur_s);
                        FirstSpotLoop = 0;
                    end
                    
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
                DrawFormattedText(win,'If you saw the test spot, press "Y". If you did not see the test spot press "A"',(XCircPos-(expParams.CircDiam_px./2)+20),YCircPos,[],[],[],0);
                %1 - flips text across the horizontal axis so text looks right side up when projected to eye
                
                Screen('Flip', win);
                
                %BUTTON PRESS CHECK
                GamePad = GamePadInput([]);
                if GamePad.buttonChange == 1 %Game pad button press check
                    if GamePad.buttonY == 1 %subject saw the stimulus
                        
                        %UPDATE STAIRCASE
                        StairFunc = QuestUpdate(StairFunc,SpotLum_logU,1); %updates the stair case
                        %1 - subject saw the stimulus
                        
                        %RESPONSE BEEP - to indicate response has been recorded
                        Beeper(expParams.RespBeepFq,expParams.RespBeepVol,expParams.RespBeepDur_s);
                        
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
                        
                        %RESPONSE BEEP - to indicate response has been recorded
                        Beeper(expParams.RespBeepFq,expParams.RespBeepVol,expParams.RespBeepDur_s);
                        
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
    
    
    
%%%%%%%%%%%%%%%%%%%%%% GRATING FLICKER 4 HZ %%%%%%%%%%%%%%%%%%%%%%%%%
   
    if CondType == 3 %Grating Flicker 4Hz
        
        %CONDITION COUNTER
        Grating4Hz_Counter = Grating4Hz_Counter + 1; %keeps track of how many times we have gone through this condition
        
        %STAIRCASE LOOP
        for CurrentStep = 1:expParams.RespInStaircase
            
            %OCILLATION CHECK
            OscillationNumb = 0; %keep track of how many ocillations in one presentation
            
            %DETERMINE TEST SPOT LUMINANCE
            SpotLum_logU = QuestMean(StairFunc); %still in log units
            SpotLumVal = ((10^(QuestMean(StairFunc))).*255)+st.CircLumVal; %outputs a intensity value in 0-1 range. Then convert to 0-255 range by multiplying by 255
            %the luminance of the suround circle is added to the spot lum which it will be presented on
            SpotLum = repelem(SpotLumVal,3); %repeat the number 3 times for RGB vlaue
            
            FirstSpotLoop = 0;
            StartStim = GetSecs;
            TimeNow = StartStim;
            %STIMULUS PRESENTATION
            while TimeNow - StartStim < expParams.TrialDuration_s && EscapeExp == 0 %within trial duration
                
                %DRAW BAR SERIES 1
                Screen('DrawTexture',win,Grating_Txt1);
                
                %DRAW CIRCLE
                Screen('FillOval',win,expParams.CircLum,CircPos); %the circle is drawn in a box of the width and height of the circle
                
                %DRAW FIXATION LINES
                Screen('DrawLines',win,st.AllCoords,expParams.FixLineWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
                
                Screen('Flip', win);
                
                TimeNow = GetSecs;
                
                
                %PRESENT TEST SPOT
                while TimeNow > (StartStim + expParams.PreTestSpotDur_s) && TimeNow < (StartStim + expParams.PreTestSpotDur_s + expParams.TestSpotDur_s) && EscapeExp == 0
                    
                    %The image will oscillate between the bar 1 and bar 2
                    %series to create a flicker effect at the given
                    %frequency
                    
                    %BAR 1 SERIES
                    LastChange = TimeNow; %last time grating was changed. Used for oscillating while loop
                    while (LastChange == TimeNow) || (expParams.OneOscillation_sec_4Hz >= (TimeNow - LastChange))
                        
                        %DRAW GRATING
                        Screen('DrawTexture',win,Grating_Txt1); %already created the texture
                        
                        %DRAW CIRCLE
                        Screen('FillOval',win,expParams.CircLum,CircPos); %the circle is drawn in a box of the width and height of the circle
                        
                        %DRAW FIXATION LINES
                        Screen('DrawLines',win,st.AllCoords,expParams.FixLineWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
                        
                        %BEEPER - indicate test spot is about to be presented
                        if FirstSpotLoop == 1
                            Beeper(expParams.TestBeepFq,expParams.TestBeepVol,expParams.TestBeepDur_s);
                            FirstSpotLoop = 0;
                        end
                        
                        %DRAW TEST SPOT
                        Screen('FillOval',win,SpotLum,TestSpotPos); %the circle is drawn in a box of the width and height of the circle
                        
                        Screen('Flip', win);
                        
                        OscillationNumb = OscillationNumb + 1; %keeps track of the number of oscillations
                        
                        TimeNow = GetSecs;
                    end
                    
                    %BAR 2 SERIES 
                    LastChange = TimeNow; %last time grating was changed. Used for oscillating while loop
                    while (LastChange == TimeNow) || (expParams.OneOscillation_sec_4Hz >= (TimeNow - LastChange))
                        %DRAW GRATING
                        Screen('DrawTexture',win,Grating_Txt2);
                        
                        %DRAW CIRCLE
                        Screen('FillOval',win,expParams.CircLum,CircPos); %the circle is drawn in a box of the width and height of the circle
                        
                        %DRAW FIXATION LINES
                        Screen('DrawLines',win,st.AllCoords,expParams.FixLineWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
                        
                        %DRAW TEST SPOT
                        Screen('FillOval',win,SpotLum,TestSpotPos); %the circle is drawn in a box of the width and height of the circle
                        
                        Screen('Flip', win);
                        
                        OscillationNumb = OscillationNumb + 1; %keeps track of the number of oscillations
                        
                        TimeNow = GetSecs;
                    end
                    
                end %test spot presentation
            end %trial duration
            
            
            %RESPONSE LOOP - subj indicates if they saw the test spot
            RespLoop = 1;
            while RespLoop == 1
                
                %DRAW GREY RECTANGLE
                Screen('FillRect',win,[128,128,128]); %grey background
                
                %DRAW TEXT
                DrawFormattedText(win,'If you saw the test spot, press "Y". If you did not see the test spot press "A"',(XCircPos-(expParams.CircDiam_px./2)+20),YCircPos,[],[],[],0);
                %1 - flips text across the horizontal axis so text looks right side up when projected to eye
                
                Screen('Flip', win);
                
                %BUTTON PRESS CHECK
                GamePad = GamePadInput([]);
                if GamePad.buttonChange == 1 %Game pad button press check
                    if GamePad.buttonY == 1 %subject saw the stimulus
                        
                        %UPDATE STAIRCASE
                        StairFunc = QuestUpdate(StairFunc,SpotLum_logU,1); %updates the stair case
                        %1 - subject saw the stimulus
                        
                        %OSCILLATION CHECK
                        data.OscillationNumb_array(CurrentStep,Grating4Hz_Counter) = OscillationNumb; %row-oscillations for that stem, col-each staircase
                        
                        %RESPONSE BEEP - to indicate response has been recorded
                        Beeper(expParams.RespBeepFq,expParams.RespBeepVol,expParams.RespBeepDur_s);
                        
                        %SAVE LUMINANCE
                        data.TestLuminance_Grating4Hz(CurrentStep,Grating4Hz_Counter) = SpotLumVal;
                        data.TestLuminance_logU_Grating4Hz(CurrentStep,Grating4Hz_Counter) = SpotLum_logU;
                        RespLoop = 0; %end loop
                        InitiateNextTrial = 1;
                    end
                    if GamePad.buttonA == 1 %subject did not see the stimulus
                        
                        %UPDATE STAIRCASE
                        StairFunc = QuestUpdate(StairFunc,SpotLum_logU,0); %updates the stair case
                        %1 - subject saw the stimulus
                        
                        %OSCILLATION CHECK
                        data.OscillationNumb_array(CurrentStep,Grating4Hz_Counter) = OscillationNumb; %row-oscillations for that stem, col-each staircase
                        
                        %RESPONSE BEEP - to indicate response has been recorded
                        Beeper(expParams.RespBeepFq,expParams.RespBeepVol,expParams.RespBeepDur_s);
                        
                        %SAVE LUMINANCE
                        data.TestLuminance_Grating4Hz(CurrentStep,Grating4Hz_Counter) = SpotLumVal; %each column will be a different staircase
                        data.TestLuminance_logU_Grating4Hz(CurrentStep,Grating4Hz_Counter) = SpotLum_logU;
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
        
    end %end Grating 4Hz
    
  
    
    % %%%%%%%%%%%%%%% THESE ARE THE NEXT CONDITIONS %%%%%%%%%%%%5

    % if CondType == 4 %Grating Flicker 10Hz
    % end
    % if CondType == 5 %Grating Flicker 15Hz
    % end
    
    
    
    
    %ALL TRIALS COMPLETE - END EXPERIMENT
    if TrialCounter == expParams.TotalTrials
        StartStim = GetSecs;
        TimeNow = StartStim;
        PresentDur_s = 1;
        while (StartStim == TimeNow) || (PresentDur_s >= (TimeNow - StartStim))
        
        %DRAW GREY RECTANGLE
        Screen('FillRect',win,[128,128,128]); %grey background
        
        %DRAW TEXT
        DrawFormattedText(win,'Experiment Finished',(XCircPos-(expParams.CircDiam_px./2)+20),YCircPos,[],[],[],0);
        %1 - flips text across the horizontal axis so text looks right side up when projected to eye
        
        Screen('DrawingFinished',win);
        Screen('Flip',win);
        
        TimeNow = GetSecs;
        end
        
        ExptLoop = 0;
    end
    
end %Experiment Loop

sca;


 %% Save Data & Calculations
 
 %SAVE DATA & PARAMS
 TotTrial = num2str(expParams.TotalTrials);
 savdir = 'D:\Tuten_Lab\Expt_Masking\Code\TutenLabExperiments\Data\';
 data.EndTime = datestr(clock,'mm_dd_yy_HHMM');
 save_file = strcat(data.subjectID,'_',TotTrial,'TotalTrials_',data.StartTime,'.mat');
 filename = [savdir save_file];
 save(filename,'data','expParams');
 
 %SAVE CIRCLE POSITION
 CircSavdir = 'D:\Tuten_Lab\Expt_Masking\Code\TutenLabExperiments\';
 CircSave_file = 'LastCircPos_px.mat';
 Circfilename = [CircSavdir CircSave_file];
 save(Circfilename,'LastCircPos_px');
 
 
 
 %if experiment has been ended prematurely
 if TrialCounter < expParams.TotalTrials
     %SAVE DATA & PARAMETERS
     TotTrial = num2str(expParams.TotalTrials);
     savdir = 'D:\Tuten_Lab\Expt_Masking\Code\TutenLabExperiments\Data\';
     data.EndTime = datestr(clock,'mm_dd_yy_HHMM');
     save_file = strcat(data.subjectID,'_','notcomplete','_',TotTrial,'TotalTrials_',data.StartTime,'.mat');
     filename = [savdir save_file];
     save(filename,'data','expParams','LastCircPos_px');
     
     %SAVE CIRCLE POSITION - saved in struct that will be loaded for next
     %experiment run
     CircSavdir = 'D:\Tuten_Lab\Expt_Masking\Code\TutenLabExperiments\';
     CircSave_file = 'LastCircPos_px.mat';
     Circfilename = [CircSavdir CircSave_file];
     save(Circfilename,'LastCircPos_px');
     
 end









