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

%% Sinc test & OpenGL & Calibration file

% SKIP SYNC TEST
Screen('Preference', 'SkipSyncTests', 1); 
%it does not seem to be actually skipping the sync test 

%OPENGL
AssertOpenGL;

%% Start by collecting experiment parameters from the command window

%SUBJ ID
data.subjectID = GetWithDefault('Subject ID ', '10001R');

%AT Home Version (created during COVID-19 Pandemic, different setup)
    %differences in setup include: ppd, gamma correction, text not
    %flipped,designation on saved files, fixation lines
data.HomeVersion = GetWithDefault('Home Version? 1=yes 0=no', 1);

%NUMB OF TRIALS YOU WANT RESPONSE TEXT
NumbTrialsDrawText = GetWithDefault('Number of Trials with Response Instructions', 5);

%NUMB OF STAIRCASES
%Code is currently only able to do 2 staircases pre condition
expParams.NumbOfStaircasesPerCond = GetWithDefault('Number of staircases per condition', 2);

%TRIALS
expParams.TrialsPerStaircase = GetWithDefault('Number of trials per stiarcase', 40); 

%PIXEL PER DEGREE
%when using hte projector the screen is actually 71.7 ppd but we had to multiply by 2 because that
%is how matlab is coding the ppd. 
if data.HomeVersion==1
    expParams.displayPixelsPerDegree = GetWithDefault('Enter display scaling (ppd) ', 148);
else
   expParams.displayPixelsPerDegree = GetWithDefault('Enter display scaling (ppd) ', 71.7);
   expParams.displayPixelsPerDegree = expParams.displayPixelsPerDegree.*2; %have to multiply by 2 because that is what the screen does for some reason. twice the pppd matches the ppd of the projector
end

%GRATING SPATIAL FREQUENCY       
expParams.gratingSpatialFrequency = GetWithDefault('Enter grating spatial frequency (cycles/deg) ', 0.53);

%OSCILLATION AMPLITUDE - of gratingTrial
expParams.GratingOscillationAmplitude = GetWithDefault('Oscillation Amplitude (Period)', 0.5);%oscilating one period would not change the image


%% Stimulus setup

[expParams,st] = ExperimentParams(expParams,data); %runs function with all of the experiment parameters

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

%% Calibration
%Save the gamatable for the current computer to implement after experiment
%[gammatable, dacbits, reallutsize] = Screen('ReadNormalizedGammaTable',win);

%LOAD CALIBRATION FILE %different depending on if it is at home version
if data.HomeVersion == 0
    load cal_03_05_20; %load the calibration file
    %LOAD GAMMA TABLE FROM CALIBRATION
    [oldgammatable] = Screen('LoadNormalizedGammaTable',win,cal.lookup_table); 
else 
    load cal_HomeVersion; %load the calibration file
    [oldgammatable] = Screen('LoadNormalizedGammaTable',win,cal_HomeVersion); 
end




%% Response Matrix setup
%create two matrices one to store luminance and one for responses for all staircases for
%all conditions.

%LUMINANCE & RESPONSE ARRAYS
%create labels for the first row of the response and luminance arrays
if expParams.NumbOfStaircasesPerCond == 1
    %Luminance array
    data.TestLuminance{1,1}= 'Grey';        data.TestLuminance{1,2} = 'Grating0Hz';      data.TestLuminance{1,3} = 'Grating4Hz';
    data.TestLuminance{1,4}= 'Grating10Hz';  data.TestLuminance{1,5} ='Grating15Hz';
    %luminance in log units
    data.TestLuminance_logU = data.TestLuminance;
    
    %Response Array
    data.Response = data.TestLuminance;
    
    %Index values
    indexGreyS1=1; indexGratS1=2; index4HzS1=3; index10HzS1=4; index15HzS1=5;

end
if expParams.NumbOfStaircasesPerCond == 2
    %Luminance Array
    data.TestLuminance{1,1}= 'Grey_S1';        data.TestLuminance{1,2} = 'Grey_S2';      data.TestLuminance{1,3} = 'Grating0Hz_S1';
    data.TestLuminance{1,4}= 'Grating0Hz_S2';  data.TestLuminance{1,5} ='Grating4Hz_S1'; data.TestLuminance{1,6} = 'Grating4Hz_S2';
    data.TestLuminance{1,7}= 'Grating10Hz_S1'; data.TestLuminance{1,8}='Grating10Hz_S2'; data.TestLuminance{1,9}='Grating15Hz_S1';
    data.TestLuminance{1,10}='Grating15Hz_S2';
    %luminance in log units
    data.TestLuminance_logU = data.TestLuminance;
    
    %Response Array
    data.Response = data.TestLuminance;
    
    %Index values
    indexGreyS1=1; indexGratS1=3; index4HzS1=5; index10HzS1=7; index15HzS1=9;
    indexGreyS2=2; indexGratS2=4; index4HzS2=6; index10HzS2=8; index15HzS2=10;
end

%Indexing into these arrays is deficult because it will change depending on
%if there is one or two staircases per condition



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
    Screen('TextSize',win,expParams.textSize); %increases text size for entire experiment
    DrawFormattedText(win,'Stimulus Position Adjustment Procedure. Press any button to Continue','center','center',[],[],expParams.HFlip,expParams.VFlip);
    %1 - flips text across the horizontal axis so text looks right side up when projected to eye
    
    Screen('DrawingFinished',win);
    Screen('Flip',win);
    
    %GAME PAD CHECK
    GamePad = GamePadInput([]); %checks game pad
    if GamePad.buttonChange == 1 %any button pressed
        if GamePad.buttonBack == 1 %escape experiment
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
    DrawFormattedText(win,'Use buttons Y,B,X, and A to center the circle',(XCircPos-(expParams.CircDiam_px./2)+20),(YCircPos-60),[],[],expParams.HFlip,expParams.VFlip);
    DrawFormattedText(win,'Once centered, press the right upper trigger',(XCircPos-(expParams.CircDiam_px./2)+20),(YCircPos+40),[],[],expParams.HFlip,expParams.VFlip);
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
        if GamePad.buttonB == 1 %B button press. Rightward movement
            %CIRCLE ADJUSTMENT
            XCircPos = XCircPos - expParams.AdjustIncrement_px;
            %GRATING ADJUSTMENT
            xStartCropPos = xStartCropPos + expParams.AdjustIncrement_px; %sets the horizontal cropping of the grating to a value that will
            %make it appear like the grating position is moving with the circle
            xEndCropPos = xEndCropPos + expParams.AdjustIncrement_px;
            GratingPos_Crop = Grating(yStartCropPos:expParams.winYpx, xStartCropPos: xEndCropPos);
            
        end
        if GamePad.buttonX == 1 %X button press. leftward movement
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
        if GamePad.buttonBack == 1
            FirstRun = 0; %get out of first experiment loop
            ExptLoop = 0; %skips experiment loop
            CircAdjustLoop = 0;
        end
    end %game pad check
end


%% Create Gratings for Main Experiment

%DETERMINE GRATING SERIES 1 & 2
%to create an oscillation between white and black bars, we will create two
%different grating images by cropping the grating at different points and
%flipping back and forth between these images

%GRATING 1
Grating_Crop1 = GratingPos_Crop; %the crop of the grating chosen in the adjustment proceedure
GratingSpot_Crop1 = GratingPos_Crop; %this will be the grating frame with the test spot

%GRATING 2
%Determines how much to crop bar series 2 to simulate an oscillation of the specified period
OscillationAmp = expParams.GratingOscillationAmplitude.*(2.*WidthOfOneBar_px); %determines one oscilation cycle in pixels. Basically where to start the x crop of the second grating
Grating_Crop2 = Grating(yStartCropPos:expParams.winYpx, (xStartCropPos+OscillationAmp):(xEndCropPos+OscillationAmp)); %crops the second bar series
GratingSpot_Crop2 = Grating_Crop2; %this will be the grating with the test spot


%% Draw Textures for Main Experiment
%To optimize the drawing process for the Grating flicker conditions, 
%the images will be made before the experiment is run.

%GRATING 4HZ, 10HZ, 15HZ CONDITIONS
%each condition with  use four images. Two with the test spot and two
%without. two types of gratings are used to create the flicker.
%Make images with
%     (1) grating1,souround circle, fixation lines 
%     (2) grating2, souround circle, fication lines
%     (3) grating1, souround circle, fixation lines, and test spot
%     (4) grating2, surround circle, fixation lines, and test spot

%the textures will be made in layers and then combined to make an image.

%CIRCLE LAYER
%Make a blank image  the size of the screen. then insert a circle of the
%correct size into the blank image.
circleLayer = zeros(size(Grating_Crop1)); %makes a matrix with zeros the size of the screen
circleSurround = double(Circle(expParams.CircRad_px)).*255; %radius of the circle
%Parameters used to index into the blank and put the circle in the correct position 
CircLeftEdge=round(XCircPos-expParams.CircRad_px);
CircRightEdge=round(XCircPos+expParams.CircRad_px);
CircTopEdge=round(YCircPos-expParams.CircRad_px); %center plus the radius of the circle
%Draw the circle into the blank image the size of the screen in the correct position
circleLayer(CircTopEdge:(CircTopEdge-1)+size(circleSurround,1), CircLeftEdge:(CircLeftEdge-1)+size(circleSurround,2))= circleSurround;


%FIXATION LINE LAYER
%each line has to be drawn individually and then we will index into the
%fixLayer (blank image the size of the screen) to properly place the
%fixation lines.
fixLayer = zeros(size(Grating_Crop1)); %blank image the size of the screen
%One verticle and horizontal fixation line drawn alone
fixLineH = ones(expParams.FixLineWidth_px,expParams.FixLineLength_px).*255; %horizontal line
fixLineV = ones(expParams.FixLineLength_px,expParams.FixLineWidth_px).*255; %verticle line
%Parameters used to index into the blank image to place the fixation lines
HorizontalFixLineTop = round(YCircPos+(expParams.FixLineWidth_px./2));%top of the horizontal fixation line. center of the circle plus half the width of the line
LeftFixLineX = round(CircRightEdge-expParams.FixLineLength_px); %x px value where the left horizontal fixation line begins
VerticalFixLineXStart = round(XCircPos-(expParams.FixLineWidth_px./2));%x value of left side of vertical fixation lines
VerticalFixLineTop = round((YCircPos+expParams.CircRad_px)-expParams.FixLineLength_px);%the y value of the top of the bottom vertical fixation line
%Position right horizontal line
fixLayer(HorizontalFixLineTop:((HorizontalFixLineTop-1)+expParams.FixLineWidth_px), CircLeftEdge:((CircLeftEdge-1)+expParams.FixLineLength_px))=fixLineH;
%Position left horizontal line
fixLayer(HorizontalFixLineTop:((HorizontalFixLineTop-1)+expParams.FixLineWidth_px), LeftFixLineX:((LeftFixLineX-1)+expParams.FixLineLength_px))=fixLineH;
%Position top Verticle Fixation Line
fixLayer(CircTopEdge:((CircTopEdge-1)+expParams.FixLineLength_px), VerticalFixLineXStart:((VerticalFixLineXStart-1)+expParams.FixLineWidth_px)) = fixLineV;
%Position bottom Vertical Fixation Line
fixLayer(VerticalFixLineTop:((VerticalFixLineTop-1)+expParams.FixLineLength_px), VerticalFixLineXStart:((VerticalFixLineXStart-1)+expParams.FixLineWidth_px)) = fixLineV;

%TEST SPOT LAYER
%This layer will not be added until it is within the experiment because 
%the luminance of the test spot will be updated each response
testspotLayer = zeros(size(Grating_Crop1)); %black image the size of the grating
testspot = double(Circle(expParams.TestSpotRad_px)).*255; %creates a white test spot
%placement of test spot parameters
TestSpotTop = round(YCircPos-expParams.TestSpotRad_px); %Y value for top of test spot
TestSpotLeftEdge = round(XCircPos-expParams.TestSpotRad_px); %x value for left edge of test spot
%put test spot into testspotLayer
testspotLayer(TestSpotTop:((TestSpotTop-1)+round(expParams.TestSpotRad_px.*2)), TestSpotLeftEdge:((TestSpotLeftEdge-1)+round(expParams.TestSpotDiam_px)))=testspot; 


%CREATE IMAGES
%without test spot
Grating_Crop1(circleLayer>0)=expParams.CircLum(1);
Grating_Crop1(fixLayer>0)=expParams.FixLineRGB(1);
Grating_Crop2(circleLayer>0)=expParams.CircLum(1);
Grating_Crop2(fixLayer>0)=expParams.FixLineRGB(1); 
%with test spot
GratingSpot_Crop1(circleLayer>0)=expParams.CircLum(1);%add the cirlce
GratingSpot_Crop1(fixLayer>0)=expParams.FixLineRGB(1); %fixation lines
GratingSpot_Crop2(circleLayer>0)=expParams.CircLum(1);%add the cirlce
GratingSpot_Crop2(fixLayer>0)=expParams.FixLineRGB(1); %fixation lines


%CREATE TEXTURES
%only create textures for the gratings *without* the test spots because the
%test spot gradings have to be made within the experiment.
%put texture into one matrix to use later.
tex(1) = Screen('MakeTexture',win,Grating_Crop1); %Grating Crop1
tex(2) = Screen('MakeTexture',win,Grating_Crop2); %Grating Crop 2


%% Get Frame Info for Flicker Calculations
%these variables will be used later when doing calculations for the flicker

% Get the frame rate
FrameRate = Screen('FrameRate', ScreenID);

% Get interframe interval
ifi = Screen('GetFlipInterval', win);

%NUMB OF FRAMES DURING FLICKER (500 ms)
%this will be used to determine how many frames we need to present when the
%gratings are flickering
numberOfFramesTexutre = round(FrameRate.*expParams.flickerDuration_Sec);



%% Randomize Trial Order 
%The conditions should be interleaved
%Experimental Conditions: (1 or 6) Grey Field (2 or 7) Flickering grating at 0Hz,   
%(3 or 8) 4Hz, (4 or 9) 10Hz, (5 or 10) 15Hz [these numbers will be used to label these conditions. 
%we need more than one numb per condition to indicate which staircase the
%trial is being used for. We will need more numbers if we want to do more
%than 2 staircases.

%Create and array of random trials with the number in the array representing which
%condition will be run. It allows you to adujust the number of trials per condition

%repeats condition numbers by the number of trials for that condition. Then
%repeat that sequence the number of staircases there are.
TrialArray = repelem([repelem(1,expParams.TrialNumb_GreyField),repelem(2,expParams.TrialNumb_Grating0Hz),repelem(3,expParams.TrialNumb_Grating4Hz),...
             repelem(4,expParams.TrialNumb_Grating10Hz),repelem(5,expParams.TrialNumb_Grating15Hz)],expParams.NumbOfStaircasesPerCond);
         
data.TrialSequences.RandTrialSequence = TrialArray(randperm(length(TrialArray))); %shuffels numbers in the array

%STAIRCASE RANDOMIZATION
%if there is more than one staircase per condition, this is an array to
%randomly determine which staircase each trial belongs to. This way, all of
%the trials for all of the staircases are interleaved.
    for stairnumb = 1:expParams.NumbOfStaircasesPerCond
        %array with number of stiars
        StairArray(1,stairnumb) = stairnumb; %if 2 staircases per cond the array will be [1 2]
    end
    %repeat the StairArray the number of trials per condition. This is set up
    %so that you can have a different number trials per condition.
    RandStairSeq_GreyField = repelem(StairArray,expParams.TrialNumb_GreyField);
    data.TrialSequences.RandStairSeq_GreyField = RandStairSeq_GreyField(randperm(length(RandStairSeq_GreyField))); %randomized sequence
    RandStairSeq_Grating0Hz = repelem(StairArray,expParams.TrialNumb_Grating0Hz);
    data.TrialSequences.RandStairSeq_Grating0Hz = RandStairSeq_Grating0Hz(randperm(length(RandStairSeq_Grating0Hz))); %randomized sequence
    RandStairSeq_Grating4Hz = repelem(StairArray,expParams.TrialNumb_Grating4Hz);
    data.TrialSequences.RandStairSeq_Grating4Hz = RandStairSeq_Grating4Hz(randperm(length(RandStairSeq_Grating4Hz))); %randomized sequence
    RandStairSeq_Grating10Hz = repelem(StairArray,expParams.TrialNumb_Grating10Hz);
    data.TrialSequences.RandStairSeq_Grating10Hz = RandStairSeq_Grating10Hz(randperm(length(RandStairSeq_Grating10Hz))); %randomized sequence
    RandStairSeq_Grating15Hz = repelem(StairArray,expParams.TrialNumb_Grating15Hz);
    data.TrialSequences.RandStairSeq_Grating15Hz = RandStairSeq_Grating15Hz(randperm(length(RandStairSeq_Grating15Hz))); %randomized sequence



%STAIRCASE
%index into StairFun to create the parameters for a staircase for each condition
for stair = 1:expParams.NumbOfStaircasesPerCond %numb of conditions
    for cond = 1:expParams.NumbOfCond %numb of conditions
        data.StairFunc(cond,stair)= QuestCreate(expParams.Staircase.ThresholdGuess,expParams.Staircase.ThresholdGuessSD,expParams.Staircase.pThreshold, ...
                                    expParams.Staircase.Beta,expParams.Staircase.Delta,expParams.Staircase.Gamma,expParams.Staircase.Grain,...
                                    expParams.Staircase.Range);
    end
end
          
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
    DrawFormattedText(win,'Main Experiment. Press any button to Continue',(XCircPos-450),YCircPos,[],[],expParams.HFlip,expParams.VFlip);
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
        if GamePad.buttonBack == 1
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
GreyField_StairCounter1 = 0;
GreyField_StairCounter2 = 0;
Grating0Hz_StairCounter1 = 0;
Grating0Hz_StairCounter2 = 0;
Grating4Hz_StairCounter1 = 0;
Grating4Hz_StairCounter2 = 0;
Grating10Hz_StairCounter1 = 0;
Grating10Hz_StairCounter2 = 0;
Grating15Hz_StairCounter1 = 0;
Grating15Hz_StairCounter2 = 0;


%EXPERIMENT LOOP
FirstLoop = 0;
TrialCounter =0;
while ExptLoop == 1
    
    InitiateNextTrial = 0; %used to draw grey intitiate trial screen
    
    %DETERMINE NEXT CONDITION TYPE
    TrialCounter = TrialCounter + 1; %counts how many conditions we have done
    CondType = data.TrialSequences.RandTrialSequence(TrialCounter); %goes through the random condition array to choose the next condition type
    
    %RESPONSE TEXT - only present response text for the first 5 trials
    if TrialCounter > NumbTrialsDrawText 
        DrawRespText = 0;
    else
        DrawRespText = 1;
    end
   
    %FLICKER VARIABLES & CALCULATIONS
    if CondType == 3 || CondType == 4 || CondType == 5 %flicker conditions
        %FLICKER VARIABLES
        NumberOfFramesTexture = round(FrameRate.*expParams.flickerDuration_Sec); %number of frames in the flicker duration
        FlickerPeriod_Sec = 1/(2.*expParams.FlickerRt_Hz(CondType)); %time for one image change(half cycle/double the flicker)
            %if 4Hz, the image will change and then go back (one cycle) 4 times in 1 sec
        FlickerPeriodFrames = round(FlickerPeriod_Sec.*FrameRate); %number of frames in a half cycle of flicker (one change)
        NumbFlickerCycles = ceil(expParams.flickerDuration_Sec.*expParams.FlickerRt_Hz(CondType));
            %number of times the stimulus can flicker(one cycle) in the presentation duration.
        %SPOT VARIABLES
        SpotDurationFrames = round(expParams.TestSpotDur_Sec.*FrameRate); %Number of frames in the test spot duration
        StartSpot = floor((NumberOfFramesTexture./2) - (SpotDurationFrames./2));%Locate the frame at the test spot onset
        
        %VECTORS FOR FLICKER GENERATION
        %generate two sequences one which represents the flickering of the grating
        %and the other which represents the onset of the spot. Add the vectors
        %togeaher which produce vectors that will be later indexed into to identify
        %which texture to present
        %Flicker squence - series of 0s and 1s alternating
        Sequence = [ones(1,FlickerPeriodFrames) 2.*ones(1,FlickerPeriodFrames)];% sereies of 1s and 2s the length of the number of frames per period
        FlickerSequence = repmat(Sequence, [1 NumbFlickerCycles]); %repeat the sequence the number of times the stimulus can flicker in the flicker duration
        %Spot sequence - series of 0s and 2s
        SpotSequence = zeros(size(FlickerSequence)); %array the same length as the flicker sequence
        SpotSequence(StartSpot:StartSpot+SpotDurationFrames) = 2; %place 2s in the position of the spot onset and full duration
        
        %Add the spot and flicker sequence togeather to create a vector that
        %you can index into to identify the texture that needs to be presented
        VideoSequence = FlickerSequence + SpotSequence;
        
        %Crop video sequence if it is too long
        if length(VideoSequence) > NumberOfFramesTexture
            VideoSequence(NumberOfFramesTexture+1:end) = [];
        end
    end
    

    
    

    
    
    
    %%%%%%%%%%%%%%%%%% Grey Field Condition %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    if CondType == 1 && EscapeExp < 1
        
        GreyCond_Counter = GreyCond_Counter + 1;
        
        %WHICH STAIRCASE - only coded for two staircases
        %if there is more than one staircase, then we have do determine
        %which staircase will be assigned this trial
        WhichStair = data.TrialSequences.RandStairSeq_GreyField(GreyCond_Counter);
        %Trial counters for each staircase
        if WhichStair == 1
            GreyField_StairCounter1 = GreyField_StairCounter1 + 1;
        end
        if WhichStair == 2
            GreyField_StairCounter2 = GreyField_StairCounter2 + 1;
        end
        
        %DETERMINE TEST SPOT LUMINANCE
        SpotLum_logU = QuestMean(data.StairFunc(CondType , WhichStair)); %still in log units
            %row-conditions col-staircases
        SpotLumVal = ((10^(QuestMean(data.StairFunc(CondType , WhichStair)))).*255)+st.CircLumVal; %Quest outputs a intensity value in 0-1 range. The equation converts it to 0-255 range by multiplying by 255
        %the luminance of the suround circle is added to the spot lum which it will be presented on
        %Limit the luminance of the test spot
        if SpotLumVal > 255 %test spot cannot be greater than 255
            SpotLumVal = 255;
        end
        if SpotLumVal < st.CircLumVal %spot luminance cannot be lower the circle luminance
            SpotLumVal = st.CircLumVal;
        end
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
            
            %DRAW FIXATION LINES
            Screen('DrawLines',win,st.AllCoords,expParams.FixLineRespWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
            
            %DRAW TEXT
            if DrawRespText == 1 %only draw text for the first few trials
            DrawFormattedText(win,'If you saw the test spot, press "Y". If you did not see the test spot press "A"',(CircLeftEdge-expParams.XTxtCenter),(YCircPos-expParams.YTxtCenter),[],[],expParams.HFlip,expParams.VFlip);
            end
            
            Screen('Flip', win);
            
            %BUTTON PRESS CHECK
            GamePad = GamePadInput([]);
            if GamePad.buttonChange == 1 %Game pad button press check
                
                if GamePad.buttonY == 1 %subject saw the stimulus
                    
                    %UPDATE STAIRCASE
                    data.StairFunc(CondType,WhichStair) = QuestUpdate(data.StairFunc(CondType,WhichStair),SpotLum_logU,1); %updates the stair case
                        %index to col-condition type, row-which staircase 
                        %1 - subject saw the stimulus
                    
                    %RESPONSE BEEP - to indicate response has been recorded
                    Beeper(expParams.RespBeepFq,expParams.RespBeepVol,expParams.RespBeepDur_s);
                    
                    %SAVE LUMINANCE & RESPONSE
                    %record the luminance and response of different staircases
                     if WhichStair == 1
                        %LUMINANCE        
                        data.TestLuminance{(GreyField_StairCounter1+1),indexGreyS1} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(GreyField_StairCounter1+1),indexGreyS1} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(GreyField_StairCounter1+1),indexGreyS1} = 1; %1-subject saw the stimulus
                    end
                    if WhichStair == 2
                        %LUMINANCE
                        data.TestLuminance{(GreyField_StairCounter2+1),indexGreyS2} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(GreyField_StairCounter2+1),indexGreyS2} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(GreyField_StairCounter2+1),indexGreyS2} = 1; %1-subject saw the stimulus
                    end
                    RespLoop = 0; %end loop
                    InitiateNextTrial = 1;
                end
                if GamePad.buttonA == 1 %subject did not see the stimulus
                    
                    %UPDATE STAIRCASE
                    data.StairFunc(CondType,WhichStair) = QuestUpdate(data.StairFunc(CondType,WhichStair),SpotLum_logU,0); %updates the stair case
                    %0 - subject did not see the stimulus
                    
                    %RESPONSE BEEP - to indicate response has been recorded
                    Beeper(expParams.RespBeepFq,expParams.RespBeepVol,expParams.RespBeepDur_s);
                    
                    %SAVE LUMINANCE & RESPONSE
                    %record the luminance and response of the different staircases
                    if WhichStair == 1
                        %LUMINANCE        
                        data.TestLuminance{(GreyField_StairCounter1+1),indexGreyS1} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(GreyField_StairCounter1+1),indexGreyS1} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(GreyField_StairCounter1+1),indexGreyS1} = 0; %0-subject did not see the stimulus
                    end
                    if WhichStair == 2
                        %LUMINANCE
                        data.TestLuminance{(GreyField_StairCounter2+1),indexGreyS2} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(GreyField_StairCounter2+1),indexGreyS2} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(GreyField_StairCounter2+1),indexGreyS2} = 0; %0-subject did not see the stimulus
                    end
                    RespLoop = 0; %end resp loop
                    InitiateNextTrial = 1; %initates a grey screen and next trial
                end
                
                %ESCAPE EXPERIMENT
                if GamePad.buttonBack == 1
                    InitiateNextTrial = 0; %prevents presentation of grey screen
                    RespLoop = 0; %end loop
                    CondType = 0;
                    ExptLoop = 0;%end experiment loop
                    EscapeExp = 1;
                    break
                end
                
                %GREY SCREEN BEFORE NEXT TRIAL
                if InitiateNextTrial == 1 %grey screen before next trial
                    
                    %DRAW GREY RECTANGLE
                    Screen('FillRect',win,[128,128,128]); %grey background
                    
                    %DRAW FIXATION LINES
                    Screen('DrawLines',win,st.AllCoords,expParams.FixLineRespWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
                    
                    Screen('DrawingFinished',win);
                    Screen('Flip',win);
                    
                    %GAME PAD CHECK
                    GamePad = GamePadInput([]); %checks game pad
                    if GamePad.buttonChange == 1 && GamePad.buttonBack == 0 %any button pressed
                        InitiateNextTrial = 0; %end initiate trial loop
                    else %ESCAPE EXPERIMENT
                        InitiateNextTrial = 0; %prevents presentation of grey screen
                        RespLoop = 0; %end loop
                        CondType = 0;
                        ExptLoop = 0;%end experiment loop
                        EscapeExp = 1;
                    end
                end %grey screen
            end%button press check
        end %response loop
        
        %RECORD THE COMPLETED TRIAL - if subj ends mid experiment this will tell
        %us which conditions the subject has completed
        if EscapeExp == 0 %subject has not escaped the experiment
            data.TrialSequencesCompleted.TrialSequence(1,TrialCounter) = CondType; %records the condition sequence that has been completed
            data.TrialSequencesCompleted.StairSequence_Grey(1,GreyCond_Counter) = WhichStair; %records the order the staircase trials for this cond have been presented in
        end
        
        CondType = 0; %end condition loop
    end %Grey Field Cond
    
    
    

    
%%%%%%%%%%%%%%%%%%%%%%%%% GRATING NO FLICKER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if CondType == 2 && EscapeExp < 1
        
       %CONDITION COUNTER
       Grating0Hz_Counter = Grating0Hz_Counter + 1; %keeps track of how many times we have gone through this condition
        
        %WHICH STAIRCASE - only coded for two staircases
        %if there is more than one staircase, then we have do determine
        %which staircase will be assigned this trial
        WhichStair = data.TrialSequences.RandStairSeq_Grating0Hz(Grating0Hz_Counter);
        %Trial counters for each staircase
        if WhichStair == 1
            Grating0Hz_StairCounter1 = Grating0Hz_StairCounter1 + 1;
        end
        if WhichStair == 2
            Grating0Hz_StairCounter2 = Grating0Hz_StairCounter2 + 1;
        end
        
        %DETERMINE TEST SPOT LUMINANCE
        SpotLum_logU = QuestMean(data.StairFunc(CondType , WhichStair)); %still in log units
            %row-conditions col-staircases
        SpotLumVal = ((10^(QuestMean(data.StairFunc(CondType , WhichStair)))).*255)+st.CircLumVal; %outputs a intensity value in 0-1 range. Then convert to 0-255 range by multiplying by 255
        %the luminance of the suround circle is added to the spot lum which it will be presented on
        %Limit the luminance of the test spot
        if SpotLumVal > 255 %test spot cannot be greater than 255
            SpotLumVal = 255;
        end
        if SpotLumVal < st.CircLumVal %spot luminance cannot be lower the circle luminance
            SpotLumVal = st.CircLumVal;
        end
        SpotLum = repelem(SpotLumVal,3); %repeat the number 3 times for RGB vlaue
        
        
        StartStim = GetSecs;
        TimeNow = StartStim;
        FirstSpotLoop = 1;
        %STIMULUS PRESENTATION
        while TimeNow - StartStim < expParams.TrialDuration_s && EscapeExp == 0 %within trial duration
            
            %DRAW BAR SERIES 1
            Screen('DrawTexture',win,tex(1));
            
            %DRAW CIRCLE
            Screen('FillOval',win,expParams.CircLum,CircPos); %the circle is drawn in a box of the width and height of the circle
            
            %DRAW FIXATION LINES
            Screen('DrawLines',win,st.AllCoords,expParams.FixLineWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
            
            Screen('Flip', win);
            
            TimeNow = GetSecs;
            
            %PRESENT TEST SPOT
            while TimeNow > (StartStim + expParams.PreTestSpotDur_s) && TimeNow < (StartStim + expParams.PreTestSpotDur_s + expParams.TestSpotDur_s) && EscapeExp == 0
                
                %DRAW GRATING
                Screen('DrawTexture',win,tex(1));
                
                %DRAW CIRCLE
                Screen('FillOval',win,expParams.CircLum,CircPos); %the circle is drawn in a box of the width and height of the circle
                
                %DRAW FIXATION LINES
                Screen('DrawLines',win,st.AllCoords,expParams.FixLineWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
                
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
            
            %DRAW FIXATION LINES
            Screen('DrawLines',win,st.AllCoords,expParams.FixLineRespWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
           
            %DRAW TEXT
            if DrawRespText == 1 %only draw text for the first few trials
            DrawFormattedText(win,'If you saw the test spot, press "Y". If you did not see the test spot press "A"',(CircLeftEdge-expParams.XTxtCenter),(YCircPos-expParams.YTxtCenter),[],[],expParams.HFlip,expParams.VFlip);
            end
            
            Screen('Flip', win);
            
            %BUTTON PRESS CHECK
            GamePad = GamePadInput([]);
            if GamePad.buttonChange == 1 %Game pad button press check
                
                if GamePad.buttonY == 1 %subject saw the stimulus
                    
                    %UPDATE STAIRCASE
                    data.StairFunc(CondType,WhichStair) = QuestUpdate(data.StairFunc(CondType,WhichStair),SpotLum_logU,1); %updates the stair case
                        %index to col-condition type, row-which staircase 
                        %1 - subject saw the stimulus
                    
                    %RESPONSE BEEP - to indicate response has been recorded
                    Beeper(expParams.RespBeepFq,expParams.RespBeepVol,expParams.RespBeepDur_s);
                    
                    %SAVE LUMINANCE & RESPONSE
                    %record the luminance and response of different staircases
                     if WhichStair == 1
                        %LUMINANCE        
                        data.TestLuminance{(Grating0Hz_StairCounter1+1),indexGratS1} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(Grating0Hz_StairCounter1+1),indexGratS1} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(Grating0Hz_StairCounter1+1),indexGratS1} = 1; %1-subject saw the stimulus
                    end
                    if WhichStair == 2
                        %LUMINANCE
                        data.TestLuminance{(Grating0Hz_StairCounter2+1),indexGratS2} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(Grating0Hz_StairCounter2+1),indexGratS2} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(Grating0Hz_StairCounter2+1),indexGratS2} = 1; %1-subject saw the stimulus
                    end
                    RespLoop = 0; %end loop
                    InitiateNextTrial = 1;
                end
                if GamePad.buttonA == 1 %subject did not see the stimulus
                    
                    %UPDATE STAIRCASE
                    data.StairFunc(CondType,WhichStair) = QuestUpdate(data.StairFunc(CondType,WhichStair),SpotLum_logU,0); %updates the stair case
                    %0 - subject did not see the stimulus
                    
                    %RESPONSE BEEP - to indicate response has been recorded
                    Beeper(expParams.RespBeepFq,expParams.RespBeepVol,expParams.RespBeepDur_s);
                    
                    %SAVE LUMINANCE & RESPONSE
                    %record the luminance and response of the different staircases
                    if WhichStair == 1
                        %LUMINANCE        
                        data.TestLuminance{(Grating0Hz_StairCounter1+1),indexGratS1} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(Grating0Hz_StairCounter1+1),indexGratS1} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(Grating0Hz_StairCounter1+1),indexGratS1} = 0; %0-subject did not see the stimulus
                    end
                    if WhichStair == 2
                        %LUMINANCE
                        data.TestLuminance{(Grating0Hz_StairCounter2+1),indexGratS2} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(Grating0Hz_StairCounter2+1),indexGratS2} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(Grating0Hz_StairCounter2+1),indexGratS2} = 0; %0-subject did not see the stimulus
                    end
                    RespLoop = 0; %end resp loop
                    InitiateNextTrial = 1; %initates a grey screen and next trial
                end
                
                %ESCAPE EXPERIMENT
                if GamePad.buttonBack == 1
                    InitiateNextTrial = 0; %prevents presentation of grey screen
                    RespLoop = 0; %end loop
                    CondType = 0;
                    ExptLoop = 0;%end experiment loop
                    EscapeExp = 1;
                    break
                end
                
                %GREY SCREEN BEFORE NEXT TRIAL
                if InitiateNextTrial == 1 %grey screen before next trial
                    
                    %DRAW GREY RECTANGLE
                    Screen('FillRect',win,[128,128,128]); %grey background
                    
                    %DRAW FIXATION LINES
                    Screen('DrawLines',win,st.AllCoords,expParams.FixLineRespWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
                    
                    Screen('DrawingFinished',win);
                    Screen('Flip',win);
                    
                    %GAME PAD CHECK
                    GamePad = GamePadInput([]); %checks game pad
                    if GamePad.buttonChange == 1 %any button pressed
                        InitiateNextTrial = 0; %end initiate trial loop
                    else %ESCAPE EXPERIMENT
                        InitiateNextTrial = 0; %prevents presentation of grey screen
                        RespLoop = 0; %end loop
                        CondType = 0;
                        ExptLoop = 0;%end experiment loop
                        EscapeExp = 1;
                    end
                end %grey screen
            end%button press check
        end %response loop
        
        %RECORD THE COMPLETED TRIAL - if subj ends mid experiment this will tell
        %us which conditions the subject has completed
        if EscapeExp == 0 %subject has not escaped the experiment
            data.TrialSequencesCompleted.TrialSequence(1,TrialCounter) = CondType; %records the condition sequence that has been completed
            data.TrialSequencesCompleted.StairSequence_Grating0Hz(1,Grating0Hz_Counter) = WhichStair; %records the order the staircase trials for this cond have been presented in
        end
        
        CondType = 0; %end condition loop
    end %Greating 0 Hz condition



   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% GRATING FLICKER 4 HZ %%%%%%%%%%%%%%%%%%%%%%%%%
    
    if CondType == 3 && EscapeExp < 1 %Grating Flicker 4Hz
        
        %CONDITION COUNTER
        Grating4Hz_Counter = Grating4Hz_Counter + 1; %keeps track of how many times we have gone through this condition
        
        %WHICH STAIRCASE - only coded for two staircases
        %if there is more than one staircase, then we have do determine
        %which staircase will be assigned this trial
        WhichStair = data.TrialSequences.RandStairSeq_Grating4Hz(Grating4Hz_Counter);
        %Trial counters for each staircase
        if WhichStair == 1
            Grating4Hz_StairCounter1 = Grating4Hz_StairCounter1 + 1;
        end
        if WhichStair == 2
            Grating4Hz_StairCounter2 = Grating4Hz_StairCounter2 + 1;
        end
        
        %DETERMINE TEST SPOT LUMINANCE
        SpotLum_logU = QuestMean(data.StairFunc(CondType , WhichStair)); %still in log units
            %row-conditions col-staircases
        SpotLumVal = ((10^(QuestMean(data.StairFunc(CondType , WhichStair)))).*255)+st.CircLumVal; %outputs a intensity value in 0-1 range. Then convert to 0-255 range by multiplying by 255
        %the luminance of the suround circle is added to the spot lum which it will be presented on
        %Limit the luminance of the test spot
        if SpotLumVal > 255 %test spot cannot be greater than 255
            SpotLumVal = 255;
        end
        if SpotLumVal < st.CircLumVal %spot luminance cannot be lower the circle luminance
            SpotLumVal = st.CircLumVal;
        end
        SpotLum = repelem(SpotLumVal,3); %repeat the number 3 times for RGB vlaue
        
        %CREATE IMAGE TEXTURES - only for test spot greatings
        %textures have already been made for the frames with no test spot.
        %Create the test spot textures with the updated test spot
        %luminance
        GratingSpot_Crop1(testspotLayer>0) = SpotLumVal; %replaces position of spot in test spot layer with a test spot with determined luminance
        GratingSpot_Crop2(testspotLayer>0) = SpotLumVal; %second crop used for flicker
        %Create Texture
        tex(3) = Screen('MakeTexture',win,GratingSpot_Crop1);
        tex(4) = Screen('MakeTexture',win,GratingSpot_Crop2);
        
        %DRAW FLICKER WITH TEST SPOTS
        %four textures have already been created as well as a vector
        %"VideoSequence" whose numbers correspond to the sequence of frames 
        %that will be presented 
        for FrameNumber = 1:length(VideoSequence)
            Screen('DrawTexture', win, tex(VideoSequence(FrameNumber)))
            Screen('Flip',win);
        end
          
        %RESPONSE LOOP - subj indicates if they saw the test spot
        RespLoop = 1;
        while RespLoop == 1
            
            %DRAW GREY RECTANGLE
            Screen('FillRect',win,[128,128,128]); %grey background
            
            %DRAW FIXATION LINES
            Screen('DrawLines',win,st.AllCoords,expParams.FixLineRespWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
            
            %DRAW TEXT
            if DrawRespText == 1 %only draw text for the first few trials
            DrawFormattedText(win,'If you saw the test spot, press "Y". If you did not see the test spot press "A"',(CircLeftEdge-expParams.XTxtCenter),(YCircPos-expParams.YTxtCenter),[],[],expParams.HFlip,expParams.VFlip);
            end
            
            Screen('Flip', win);
            
            %BUTTON PRESS CHECK
            GamePad = GamePadInput([]);
            if GamePad.buttonChange == 1 %Game pad button press check
                
                if GamePad.buttonY == 1 %subject saw the stimulus
                    
                    %UPDATE STAIRCASE
                    data.StairFunc(CondType,WhichStair) = QuestUpdate(data.StairFunc(CondType,WhichStair),SpotLum_logU,1); %updates the stair case
                        %index to col-condition type, row-which staircase 
                        %1 - subject saw the stimulus
                    
                    %RESPONSE BEEP - to indicate response has been recorded
                    Beeper(expParams.RespBeepFq,expParams.RespBeepVol,expParams.RespBeepDur_s);
                    
                    %SAVE LUMINANCE & RESPONSE
                    %record the luminance and response of different staircases
                     if WhichStair == 1
                        %LUMINANCE        
                        data.TestLuminance{(Grating4Hz_StairCounter1+1),index4HzS1} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(Grating4Hz_StairCounter1+1),index4HzS1} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(Grating4Hz_StairCounter1+1),index4HzS1} = 1; %1-subject saw the stimulus
                    end
                    if WhichStair == 2
                        %LUMINANCE
                        data.TestLuminance{(Grating4Hz_StairCounter2+1),index4HzS2} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(Grating4Hz_StairCounter2+1),index4HzS2} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(Grating4Hz_StairCounter2+1),index4HzS2} = 1; %1-subject saw the stimulus
                    end
                    RespLoop = 0; %end loop
                    InitiateNextTrial = 1;
                end
                if GamePad.buttonA == 1 %subject did not see the stimulus
                    
                    %UPDATE STAIRCASE
                    data.StairFunc(CondType,WhichStair) = QuestUpdate(data.StairFunc(CondType,WhichStair),SpotLum_logU,0); %updates the stair case
                    %0 - subject did not see the stimulus
                    
                    %RESPONSE BEEP - to indicate response has been recorded
                    Beeper(expParams.RespBeepFq,expParams.RespBeepVol,expParams.RespBeepDur_s);
                    
                    %SAVE LUMINANCE & RESPONSE
                    %record the luminance and response of the different staircases
                    if WhichStair == 1
                        %LUMINANCE        
                        data.TestLuminance{(Grating4Hz_StairCounter1+1),index4HzS1} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(Grating4Hz_StairCounter1+1),index4HzS1} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(Grating4Hz_StairCounter1+1),index4HzS1} = 0; %0-subject did not see the stimulus
                    end
                    if WhichStair == 2
                        %LUMINANCE
                        data.TestLuminance{(Grating4Hz_StairCounter2+1),index4HzS2} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(Grating4Hz_StairCounter2+1),index4HzS2} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(Grating4Hz_StairCounter2+1),index4HzS2} = 0; %0-subject did not see the stimulus
                    end
                    RespLoop = 0; %end resp loop
                    InitiateNextTrial = 1; %initates a grey screen and next trial
                end
                
                %ESCAPE EXPERIMENT
                if GamePad.buttonBack == 1
                    InitiateNextTrial = 0; %prevents presentation of grey screen
                    RespLoop = 0; %end loop
                    CondType = 0;
                    ExptLoop = 0;%end experiment loop
                    EscapeExp = 1;
                    break
                end
                
                %GREY SCREEN BEFORE NEXT TRIAL
                if InitiateNextTrial == 1 %grey screen before next trial
                    
                    %DRAW GREY RECTANGLE
                    Screen('FillRect',win,[128,128,128]); %grey background
                    %DRAW FIXATION LINES
                    Screen('DrawLines',win,st.AllCoords,expParams.FixLineRespWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
                    
                    Screen('DrawingFinished',win);
                    Screen('Flip',win);
                    
                    %GAME PAD CHECK
                    GamePad = GamePadInput([]); %checks game pad
                    if GamePad.buttonChange == 1 %any button pressed
                        InitiateNextTrial = 0; %end initiate trial loop
                    else %ESCAPE EXPERIMENT
                        InitiateNextTrial = 0; %prevents presentation of grey screen
                        RespLoop = 0; %end loop
                        CondType = 0;
                        ExptLoop = 0;%end experiment loop
                        EscapeExp = 1;
                    end
                end %grey screen
            end%button press check
        end %response loop
        
        %RECORD THE COMPLETED TRIAL - if subj ends mid experiment this will tell
        %us which conditions the subject has completed
        if EscapeExp == 0 %subject has not escaped the experiment
            data.TrialSequencesCompleted.TrialSequence(1,TrialCounter) = CondType; %records the condition sequence that has been completed
            data.TrialSequencesCompleted.StairSequence_Grating4Hz(1,Grating4Hz_Counter) = WhichStair; %records the order the staircase trials for this cond have been presented in
        end
        
        CondType = 0; %end condition loop
    end %Greating 4 Hz condition      


    
    
    
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% GRATING FLICKER 10 HZ %%%%%%%%%%%%%%%%%%%%%%%%%
    
    if CondType == 4 && EscapeExp < 1 %Grating Flicker 10Hz
        
        %CONDITION COUNTER
        Grating10Hz_Counter = Grating10Hz_Counter + 1; %keeps track of how many times we have gone through this condition
        
        %WHICH STAIRCASE - only coded for two staircases
        %if there is more than one staircase, then we have do determine
        %which staircase will be assigned this trial
        WhichStair = data.TrialSequences.RandStairSeq_Grating10Hz(Grating10Hz_Counter);
        %Trial counters for each staircase
        if WhichStair == 1
            Grating10Hz_StairCounter1 = Grating10Hz_StairCounter1 + 1;
        end
        if WhichStair == 2
            Grating10Hz_StairCounter2 = Grating10Hz_StairCounter2 + 1;
        end
        
        %DETERMINE TEST SPOT LUMINANCE
        SpotLum_logU = QuestMean(data.StairFunc(CondType , WhichStair)); %still in log units
            %row-conditions col-staircases
        SpotLumVal = ((10^(QuestMean(data.StairFunc(CondType , WhichStair)))).*255)+st.CircLumVal; %outputs a intensity value in 0-1 range. Then convert to 0-255 range by multiplying by 255
        %the luminance of the suround circle is added to the spot lum which it will be presented on
        %Limit the luminance of the test spot
        if SpotLumVal > 255 %test spot cannot be greater than 255
            SpotLumVal = 255;
        end
        if SpotLumVal < st.CircLumVal %spot luminance cannot be lower the circle luminance
            SpotLumVal = st.CircLumVal;
        end
        SpotLum = repelem(SpotLumVal,3); %repeat the number 3 times for RGB vlaue
        
        %CREATE IMAGE TEXTURES - only for test spot greatings
        %textures have already been made for the frames with no test spot.
        %Create the test spot textures with the updated test spot
        %luminance
        GratingSpot_Crop1(testspotLayer>0) = SpotLumVal; %replaces position of spot in test spot layer with a test spot with determined luminance
        GratingSpot_Crop2(testspotLayer>0) = SpotLumVal; %second crop used for flicker
        %Create Texture
        tex(3) = Screen('MakeTexture',win,GratingSpot_Crop1);
        tex(4) = Screen('MakeTexture',win,GratingSpot_Crop2);
        
        %DRAW FLICKER WITH TEST SPOTS
        %four textures have already been created as well as a vector
        %"VideoSequence" whose numbers correspond to the sequence of frames 
        %that will be presented 
        for FrameNumber = 1:length(VideoSequence)
            Screen('DrawTexture', win, tex(VideoSequence(FrameNumber)))
            Screen('Flip',win);
        end
        
        
        %RESPONSE LOOP - subj indicates if they saw the test spot
        RespLoop = 1;
        while RespLoop == 1
            
            %DRAW GREY RECTANGLE
            Screen('FillRect',win,[128,128,128]); %grey background
            
            %DRAW TEXT
            if DrawRespText == 1 %only draw text for the first few trials
            DrawFormattedText(win,'If you saw the test spot, press "Y". If you did not see the test spot press "A"',(CircLeftEdge-expParams.XTxtCenter),(YCircPos-expParams.YTxtCenter),[],[],expParams.HFlip,expParams.VFlip);
            end
            
            %DRAW FIXATION LINES
            Screen('DrawLines',win,st.AllCoords,expParams.FixLineRespWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
            Screen('Flip', win);
            
            %BUTTON PRESS CHECK
            GamePad = GamePadInput([]);
            if GamePad.buttonChange == 1 %Game pad button press check
                
                if GamePad.buttonY == 1 %subject saw the stimulus
                    
                    %UPDATE STAIRCASE
                    data.StairFunc(CondType,WhichStair) = QuestUpdate(data.StairFunc(CondType,WhichStair),SpotLum_logU,1); %updates the stair case
                        %index to col-condition type, row-which staircase 
                        %1 - subject saw the stimulus
                    
                    %RESPONSE BEEP - to indicate response has been recorded
                    Beeper(expParams.RespBeepFq,expParams.RespBeepVol,expParams.RespBeepDur_s);
                    
                    %SAVE LUMINANCE & RESPONSE
                    %record the luminance and response of different staircases
                     if WhichStair == 1
                        %LUMINANCE        
                        data.TestLuminance{(Grating10Hz_StairCounter1+1),index10HzS1} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(Grating10Hz_StairCounter1+1),index10HzS1} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(Grating10Hz_StairCounter1+1),index10HzS1} = 1; %1-subject saw the stimulus
                    end
                    if WhichStair == 2
                        %LUMINANCE
                        data.TestLuminance{(Grating10Hz_StairCounter2+1),index10HzS2} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(Grating10Hz_StairCounter2+1),index10HzS2} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(Grating10Hz_StairCounter2+1),index10HzS2} = 1; %1-subject saw the stimulus
                    end
                    RespLoop = 0; %end loop
                    InitiateNextTrial = 1;
                end
                if GamePad.buttonA == 1 %subject did not see the stimulus
                    
                    %UPDATE STAIRCASE
                    data.StairFunc(CondType,WhichStair) = QuestUpdate(data.StairFunc(CondType,WhichStair),SpotLum_logU,0); %updates the stair case
                    %0 - subject did not see the stimulus
                    
                    %RESPONSE BEEP - to indicate response has been recorded
                    Beeper(expParams.RespBeepFq,expParams.RespBeepVol,expParams.RespBeepDur_s);
                    
                    %SAVE LUMINANCE & RESPONSE
                    %record the luminance and response of the different staircases
                    if WhichStair == 1
                        %LUMINANCE        
                        data.TestLuminance{(Grating10Hz_StairCounter1+1),index10HzS1} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(Grating10Hz_StairCounter1+1),index10HzS1} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(Grating10Hz_StairCounter1+1),index10HzS1} = 0; %0-subject did not see the stimulus
                    end
                    if WhichStair == 2
                        %LUMINANCE
                        data.TestLuminance{(Grating10Hz_StairCounter2+1),index10HzS2} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(Grating10Hz_StairCounter2+1),index10HzS2} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(Grating10Hz_StairCounter2+1),index10HzS2} = 0; %0-subject did not see the stimulus
                    end
                    RespLoop = 0; %end resp loop
                    InitiateNextTrial = 1; %initates a grey screen and next trial
                end
                
                %ESCAPE EXPERIMENT
                if GamePad.buttonBack == 1
                    InitiateNextTrial = 0; %prevents presentation of grey screen
                    RespLoop = 0; %end loop
                    CondType = 0;
                    ExptLoop = 0;%end experiment loop
                    EscapeExp = 1;
                    break
                end
                
                %GREY SCREEN BEFORE NEXT TRIAL
                if InitiateNextTrial == 1 %grey screen before next trial
                    
                    %DRAW GREY RECTANGLE
                    Screen('FillRect',win,[128,128,128]); %grey background
                    %DRAW FIXATION LINES
                    Screen('DrawLines',win,st.AllCoords,expParams.FixLineRespWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
                    
                    Screen('DrawingFinished',win);
                    Screen('Flip',win);
                    
                    %GAME PAD CHECK
                    GamePad = GamePadInput([]); %checks game pad
                    if GamePad.buttonChange == 1 %any button pressed
                        InitiateNextTrial = 0; %end initiate trial loop
                    else %ESCAPE EXPERIMENT
                        InitiateNextTrial = 0; %prevents presentation of grey screen
                        RespLoop = 0; %end loop
                        CondType = 0;
                        ExptLoop = 0;%end experiment loop
                        EscapeExp = 1;
                    end
                end %grey screen
            end%button press check
        end %response loop
        
        %RECORD THE COMPLETED TRIAL - if subj ends mid experiment this will tell
        %us which conditions the subject has completed
        if EscapeExp == 0 %subject has not escaped the experiment
            data.TrialSequencesCompleted.TrialSequence(1,TrialCounter) = CondType; %records the condition sequence that has been completed
            data.TrialSequencesCompleted.StairSequence_Grating10Hz(1,Grating10Hz_Counter) = WhichStair; %records the order the staircase trials for this cond have been presented in
        end
        
        CondType = 0; %end condition loop
    end %Greating 10 Hz condition



   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% GRATING FLICKER 15 HZ %%%%%%%%%%%%%%%%%%%%%%%%%
    
    if CondType == 5 && EscapeExp < 1 %Grating Flicker 15Hz
        
        %CONDITION COUNTER
        Grating15Hz_Counter = Grating15Hz_Counter + 1; %keeps track of how many times we have gone through this condition
        
        %WHICH STAIRCASE - only coded for two staircases
        %if there is more than one staircase, then we have do determine
        %which staircase will be assigned this trial
        WhichStair = data.TrialSequences.RandStairSeq_Grating15Hz(Grating15Hz_Counter);
        %Trial counters for each staircase
        if WhichStair == 1
            Grating15Hz_StairCounter1 = Grating15Hz_StairCounter1 + 1;
        end
        if WhichStair == 2
            Grating15Hz_StairCounter2 = Grating15Hz_StairCounter2 + 1;
        end
        
        %DETERMINE TEST SPOT LUMINANCE
        SpotLum_logU = QuestMean(data.StairFunc(CondType , WhichStair)); %still in log units
            %row-conditions col-staircases
        SpotLumVal = ((10^(QuestMean(data.StairFunc(CondType , WhichStair)))).*255)+st.CircLumVal; %outputs a intensity value in 0-1 range. Then convert to 0-255 range by multiplying by 255
        %the luminance of the suround circle is added to the spot lum which it will be presented on
        %Limit the luminance of the test spot
        if SpotLumVal > 255 %test spot cannot be greater than 255
            SpotLumVal = 255;
        end
        if SpotLumVal < st.CircLumVal %spot luminance cannot be lower the circle luminance
            SpotLumVal = st.CircLumVal;
        end
        SpotLum = repelem(SpotLumVal,3); %repeat the number 3 times for RGB vlaue
        
        %CREATE IMAGE TEXTURES - only for test spot greatings
        %textures have already been made for the frames with no test spot.
        %Create the test spot textures with the updated test spot
        %luminance
        GratingSpot_Crop1(testspotLayer>0) = SpotLumVal; %replaces position of spot in test spot layer with a test spot with determined luminance
        GratingSpot_Crop2(testspotLayer>0) = SpotLumVal; %second crop used for flicker
        %Create Texture
        tex(3) = Screen('MakeTexture',win,GratingSpot_Crop1);
        tex(4) = Screen('MakeTexture',win,GratingSpot_Crop2);
        
        %DRAW FLICKER WITH TEST SPOTS
        %four textures have already been created as well as a vector
        %"VideoSequence" whose numbers correspond to the sequence of frames 
        %that will be presented 
        for FrameNumber = 1:length(VideoSequence)
            Screen('DrawTexture', win, tex(VideoSequence(FrameNumber)))
            Screen('Flip',win);
        end
        
        
        %RESPONSE LOOP - subj indicates if they saw the test spot
        RespLoop = 1;
        while RespLoop == 1
            
            %DRAW GREY RECTANGLE
            Screen('FillRect',win,[128,128,128]); %grey background
            %DRAW FIXATION LINES
            Screen('DrawLines',win,st.AllCoords,expParams.FixLineRespWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
            
            %DRAW TEXT
            if DrawRespText == 1 %only draw text for the first few trials
            DrawFormattedText(win,'If you saw the test spot, press "Y". If you did not see the test spot press "A"',(CircLeftEdge-expParams.XTxtCenter),(YCircPos-expParams.YTxtCenter),[],[],expParams.HFlip,expParams.VFlip);
            end
            
            Screen('Flip', win);
            
            %BUTTON PRESS CHECK
            GamePad = GamePadInput([]);
            if GamePad.buttonChange == 1 %Game pad button press check
                
                if GamePad.buttonY == 1 %subject saw the stimulus
                    
                    %UPDATE STAIRCASE
                    data.StairFunc(CondType,WhichStair) = QuestUpdate(data.StairFunc(CondType,WhichStair),SpotLum_logU,1); %updates the stair case
                        %index to col-condition type, row-which staircase 
                        %1 - subject saw the stimulus
                    
                    %RESPONSE BEEP - to indicate response has been recorded
                    Beeper(expParams.RespBeepFq,expParams.RespBeepVol,expParams.RespBeepDur_s);
                    
                    %SAVE LUMINANCE & RESPONSE
                    %record the luminance and response of different staircases
                     if WhichStair == 1
                        %LUMINANCE        
                        data.TestLuminance{(Grating15Hz_StairCounter1+1),index15HzS1} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(Grating15Hz_StairCounter1+1),index15HzS1} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(Grating15Hz_StairCounter1+1),index15HzS1} = 1; %1-subject saw the stimulus
                    end
                    if WhichStair == 2
                        %LUMINANCE
                        data.TestLuminance{(Grating15Hz_StairCounter2+1),index15HzS2} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(Grating15Hz_StairCounter2+1),index15HzS2} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(Grating15Hz_StairCounter2+1),index15HzS2} = 1; %1-subject saw the stimulus
                    end
                    RespLoop = 0; %end loop
                    InitiateNextTrial = 1;
                end
                if GamePad.buttonA == 1 %subject did not see the stimulus
                    
                    %UPDATE STAIRCASE
                    data.StairFunc(CondType,WhichStair) = QuestUpdate(data.StairFunc(CondType,WhichStair),SpotLum_logU,0); %updates the stair case
                    %0 - subject did not see the stimulus
                    
                    %RESPONSE BEEP - to indicate response has been recorded
                    Beeper(expParams.RespBeepFq,expParams.RespBeepVol,expParams.RespBeepDur_s);
                    
                    %SAVE LUMINANCE & RESPONSE
                    %record the luminance and response of the different staircases
                    if WhichStair == 1
                        %LUMINANCE        
                        data.TestLuminance{(Grating15Hz_StairCounter1+1),index15HzS1} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(Grating15Hz_StairCounter1+1),index15HzS1} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(Grating15Hz_StairCounter1+1),index15HzS1} = 0; %0-subject did not see the stimulus
                    end
                    if WhichStair == 2
                        %LUMINANCE
                        data.TestLuminance{(Grating15Hz_StairCounter2+1),index15HzS2} = SpotLumVal;
                            %have to add one to the row bec there are labels are in row 1
                            %row-trials, col-conditions & stairs
                        %save the luminance in log units
                        data.TestLuminance_logU{(Grating15Hz_StairCounter2+1),index15HzS2} = SpotLum_logU;   
                        %RESPONSE
                        data.Response{(Grating15Hz_StairCounter2+1),index15HzS2} = 0; %0-subject did not see the stimulus
                    end
                    RespLoop = 0; %end resp loop
                    InitiateNextTrial = 1; %initates a grey screen and next trial
                end
                
                %ESCAPE EXPERIMENT
                if GamePad.buttonBack == 1
                    InitiateNextTrial = 0; %prevents presentation of grey screen
                    RespLoop = 0; %end loop
                    CondType = 0;
                    ExptLoop = 0;%end experiment loop
                    EscapeExp = 1;
                    break
                end
                
                %GREY SCREEN BEFORE NEXT TRIAL
                if InitiateNextTrial == 1 %grey screen before next trial
                    
                    %DRAW GREY RECTANGLE
                    Screen('FillRect',win,[128,128,128]); %grey background
                    %DRAW FIXATION LINES
                    Screen('DrawLines',win,st.AllCoords,expParams.FixLineRespWidth_px,expParams.FixLineRGB,[XCircPos,YCircPos]);
                    
                    Screen('DrawingFinished',win);
                    Screen('Flip',win);
                    
                    %GAME PAD CHECK
                    GamePad = GamePadInput([]); %checks game pad
                    if GamePad.buttonChange == 1 %any button pressed
                        InitiateNextTrial = 0; %end initiate trial loop
                    else %ESCAPE EXPERIMENT
                        InitiateNextTrial = 0; %prevents presentation of grey screen
                        RespLoop = 0; %end loop
                        CondType = 0;
                        ExptLoop = 0;%end experiment loop
                        EscapeExp = 1;
                    end
                end %grey screen
            end%button press check
        end %response loop
        
        %RECORD THE COMPLETED TRIAL - if subj ends mid experiment this will tell
        %us which conditions the subject has completed
        if EscapeExp == 0 %subject has not escaped the experiment
            data.TrialSequencesCompleted.TrialSequence(1,TrialCounter) = CondType; %records the condition sequence that has been completed
            data.TrialSequencesCompleted.StairSequence_Grating15Hz(1,Grating15Hz_Counter) = WhichStair; %records the order the staircase trials for this cond have been presented in
        end
        
        CondType = 0; %end condition loop
    end %Greating 15 Hz condition

    
    
    %ALL TRIALS COMPLETE - END EXPERIMENT
    if TrialCounter == expParams.TotalTrials
        StartStim = GetSecs;
        TimeNow = StartStim;
        PresentDur_s = 1;
        while (StartStim == TimeNow) || (PresentDur_s >= (TimeNow - StartStim))
            
            %DRAW GREY RECTANGLE
            Screen('FillRect',win,[128,128,128]); %grey background
            
            %DRAW TEXT
            DrawFormattedText(win,'Experiment Finished',(XCircPos-(expParams.CircDiam_px./2)+20),YCircPos,[],[],expParams.HFlip,expParams.VFlip);
            %1 - flips text across the horizontal axis so text looks right side up when projected to eye
            
            Screen('DrawingFinished',win);
            Screen('Flip',win);
            
            TimeNow = GetSecs;
        end
        
        ExptLoop = 0;
    end
    
end %Experiment Loop

%Restore the gamma table for the computer after the experiment is complete
Screen('LoadNormalizedGammaTable',win,oldgammatable);


sca;

%% Save Data & Calculations


if TrialCounter == expParams.TotalTrials
    %SAVE DATA & PARAMS
    TotTrial = num2str(expParams.TotalTrials);
    savdir = strcat(pwd,'\Data\'); %data folder in the current directory.so you will need a data folder to save the files
    data.EndTime = datestr(clock,'mm_dd_yy_HHMM');
    if data.HomeVersion == 1 %denote home version in the name of the file
        save_file = strcat(data.subjectID,'_',TotTrial,'TotalTrials_','HomeVersion_',data.StartTime,'.mat');
    else
        save_file = strcat(data.subjectID,'_',TotTrial,'TotalTrials_',data.StartTime,'.mat');
    end
    filename = [savdir save_file];
    save(filename,'data','expParams');
    
    %SAVE CIRCLE POSITION
    CircSavdir = pwd;
    CircSave_file = 'LastCircPos_px.mat';
    Circfilename = [CircSavdir CircSave_file];
    save(Circfilename,'LastCircPos_px');
    
else %if experiment has been ended prematurely
    %SAVE DATA & PARAMETERS
    TotTrial = num2str(expParams.TotalTrials);
    savdir = strcat(pwd,'\Data\');
    %savdir = 'D:\Tuten_Lab\Expt_Masking\Code\TutenLabExperiments\Data\';
    data.EndTime = datestr(clock,'mm_dd_yy_HHMM');
    if data.HomeVersion == 1 %denote home version in the name of the file
        save_file = strcat(data.subjectID,'_','notcomplete','_',TotTrial,'TotalTrials_','HomeVersion_',data.StartTime,'.mat');
    else
        save_file = strcat(data.subjectID,'_','notcomplete','_',TotTrial,'TotalTrials_',data.StartTime,'.mat');
    end
    filename = [savdir save_file];
    save(filename,'data','expParams','LastCircPos_px');
    
    %SAVE CIRCLE POSITION - saved in struct that will be loaded for next
    %experiment run
    CircSavdir = pwd;
    CircSave_file = 'LastCircPos_px.mat';
    Circfilename = [CircSavdir CircSave_file];
    save(Circfilename,'LastCircPos_px');
end






