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
%GRATING SPATIAL FREQUENCY       
expParams.gratingSpatialFrequency = GetWithDefault('Enter grating spatial frequency (cycles/deg) ', 0.53);
%OSCILLATION AMPLITUDE - of grating
expParams.GratingOscillationAmplitude = GetWithDefault('Oscillation Amplitude (Period)', 0.5);%oscilating one period would not change the image
%OSCILLATION FREQUENCY
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

%% Set up Psychtoolbox window

%WINDOW PERAMETERS
%Identify the Number of screens
ScreenID = max(Screen('Screens')); %the largest number will be the screen that the stim is drawn to
%ScreenID = min(Screen('Screens')); %the largest number will be the screen that the stim is drawn to
  %for some reason using the max screen was not working
  
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


%% Additional Stimulus & Experiment Variables

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
AdjustIncrement_px = 35;%30;
%%%%%%%%%%%%

%% Circle Adjustment Proceedure
%this will allow the subject to use the game controller to adjust the
%position of the stimulus so that it is in the center of the projection

%POSITION ADJUSTMENT INITATION
PadResp = 0;
FirstLoop = 0;
% %GAME PAD CHECK LOOP
% ButtonPress = 0;
% KeyPresses = -1;
while PadResp == 0 %while keys are not pressed
    %DRAW GREY RECTANGLE
    Screen('FillRect',win,[128,128,128]); %grey background
    
    %DRAW TEXT
    %Screen('Preferences','DefaultFontSize',[12]); %does not work
    DrawFormattedText(win,'Stimulus Position Adjustment Procedure. Press any button to Continue','center','center',[],[],[],1);
    %1 - flips text across the horizontal axis so text looks right side up when projected to eye
    
    Screen('Flip',win);
    
    %GAME PAD CHECK
    if FirstLoop == 0
        GamePad = GamePadInput([]);%must be inside the while loop for stimulus to work
        FirstLoop = 1; %get out of first loop
    end
    if GamePad.buttonChange == 1 %any button pressed
        PadResp = 1; %out of while loop
        
%         LastPress = KeyPresses;
%         KeyPresses = KeyPresses+1;
    end
    
%     %GAME PAD CHECK
%     if KeyPress == ButtonPresses + 1 || ButtonPresses == 0
%     GamePad = GamePadInput([]);%must be inside the while loop for stimulus to work
%     
%     if GamePad.buttonChange == 1 %any button pressed
%         PadResp = 1; %out of while loop
%     end
end

%ADJUSTING CIRCLE POSITION 
%subject uses Y,B,X,A on the game pad to adjust the position of the circle

%The subject should be presented with the grating and a a grey circle. They
%should be able to move the position of the grating with the circle to
%position it in the ceter. Then that position should be saved. The circle
%will be moved by adjusting the center points to which the shapes are
%drawn. We want the grating to be lined up in the same way relative to the 
%circle no matter the position of the circle. To do this the 
%image is cropped so it appears the grating is moving with the circle.
%*****There should eventually be a way to load previous locations of the circle 

%basically you want to change the center to which everything is being drawn
CircAdjustLoop = 0;
FirstLoop=0;

while CircAdjustLoop == 0 %adjusting the circle
    GamePad = GamePadInput([]);
    if FirstLoop == 0
      %  GamePad = GamePadInput([]);
        FirstLoop = 1;
    end
    
    %DRAW BAR SERIES 1 - series 1 just means that the white bar is first
    GratingPos_Txt = Screen('MakeTexture',win,GratingPos_Crop);%makes grating approapriate size
    Screen('DrawTexture',win,GratingPos_Txt); %draws the grating texture to the window
   
    %DRAW CIRCLE
    CircPos = CenterRectOnPointd([0, 0, CircDiam_px, CircDiam_px],Xpos,Ypos); %centers the circle on a point
    Screen('FillOval',win,CircLum,CircPos); %the circle is drawn in a box of the width and height of the circle
    
    %DRAW FIXATION CROSS
    Screen('DrawLines',win,AllCoords,FixLineWidth_px,[0,0,0],[Xpos,Ypos]);
    
    %INSTRUCTIONS
    DrawFormattedText(win,'Use buttons Y,B,X, and A to center the circle',(Xpos-(CircDiam_px./2)+20),(Ypos-40));
    DrawFormattedText(win,'Once centered, press the right upper trigger',(Xpos-(CircDiam_px./2)+20),(Ypos+40));
    %corrdinates used to center the text within the circle
    
    Screen('Flip', win);
    
    %BUTTON PRESS --> CIRC POSITION ADJUSTMENT
    %???How to make the button keep going when you hold the button down
    %GamePad = GamePadInput([]);%intitates button check. Must be inside the while loop for stimulus to work
    GamePad = GamePadInput([]);
    if GamePad.buttonChange == 1 %Game pad button press check
        if GamePad.buttonY == 1 %Y button pressed. Up movement of circ
            %CIRCLE POSITION
            Ypos = Ypos + AdjustIncrement_px; %note: it is flipped when on a window screen
            %GRATING POSITION - adjust the way the grating is cropped
            %you don't need to adjust this because the grating does not change vertically
        end
        GamePad = GamePadInput([]);
        if GamePad.buttonA == 1 %A button pressed. Down movement
            %CIRCLE POSITION
            Ypos = Ypos - AdjustIncrement_px;
            %GRATING POSITION - adjust the way the grating is cropped
            %you don't need to adjust this because the grating does not change vertically
        end
        if GamePad.buttonX == 1 %X button press. leftward movement
            %CIRCLE ADJUSTMENT
            Xpos = Xpos - AdjustIncrement_px;
            %GRATING ADJUSTMENT
            xStartCropPos = xStartCropPos + AdjustIncrement_px; %sets the horizontal cropping of the grating to a value that will
            %make it appear like the grating position is moving with the circle
            xEndCropPos = xEndCropPos + AdjustIncrement_px;
            GratingPos_Crop = Grating(yStartCropPos:expParams.winYpx, xStartCropPos: xEndCropPos);
            
        end
        if GamePad.buttonB == 1 %B button press. Rightward movement
            %CIRCLE ADJUSTMENT
            Xpos = Xpos + AdjustIncrement_px;
            %GRATING ADJUSTMENT
            xStartCropPos = xStartCropPos - AdjustIncrement_px;%sets the horizontal cropping of the grating to a value that will
            %make it appear like the grating position is moving with the circle
            xEndCropPos = xEndCropPos - AdjustIncrement_px;
            GratingPos_Crop = Grating(yStartCropPos:expParams.winYpx, xStartCropPos:xEndCropPos);
        end
    end
    
    
%     %ADJUSTMENT INSTRUCTIONS

% 
%     %DISPLAY TEXT - when completed
%     DrawFormattedText(win,'Press the right upper trigger once circle is centered','center','center');
    
    %END ADJUSTMENT LOOP
    GamePad = GamePadInput([]);%checks gamepad. must be inside the while loop for stimulus to work.
    if GamePad.buttonRightUpperTrigger == 1
        %END LOOP
        CircAdjustLoop = 1;
        
        %RECALC CENTERED CIRCLE
        CircPos = CenterRectOnPointd([0, 0, CircDiam_px, CircDiam_px],Xpos,Ypos); %centers the circle on a point

        %SAVE ADJUSTMENT
        dat.xStartGratingPos = xStartCropPos; %information for cropping grating
        dat.xEndGratingPos = xEndCropPos;%information for cropping the grating
        dat.CircXpos = Xpos; %x position of the circle
        dat.CircYpos = Ypos; %y position of the circle
    end
end
%% Given Position Adjustment Crop Grating & Determine oscillation

%DETERMINE GRATING SERIES 1 & 2
%to create an oscillation between white and black bars, we will create two
%different grating images by cropping the grating at different points and
%flipping back and forth between these images

%GRATING 1
Grating_Crop1 = GratingPos_Crop; %the crop of the grating chosen in the adjustment proceedure

%GRATING 2
%Determines how much to crop bar series 2 to simulate an oscillation of the specified period
OscillationAmp = expParams.GratingOscillationAmplitude.*(2.*WidthOfOneBar_px);
Grating_Crop2 = Grating(1:expParams.winYpx, OscillationAmp:(expParams.winXpx+OscillationAmp));


%% Work on drawing stimulus - Iona
   

    
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
    Screen('FillOval',win,CircLum,CircPos); %the circle is drawn in a box of the width and height of the circle
    
    %DRAW FIXATION CROSS
    Screen('DrawLines',win,AllCoords,FixLineWidth_px,[0,0,0],[Xpos,Ypos]);
    
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
    Screen('FillOval',win,CircLum,CircPos);
    %the circle is drawn in a box of the width and height of the circle
    
    %DRAW FIXATION CROSS
    Screen('DrawLines',win,AllCoords,FixLineWidth_px,[0,0,0],[Xpos,Ypos]);
    
    Screen('Flip', win);
    
    TimeNow = GetSecs; %gets current time
    
end %end of second while loop
end %end of for loop
    
% KbWait;
% 
 sca;





%% Experiment loop


