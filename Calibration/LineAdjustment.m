%Line Adjustment
%3/3/2020 This will be used to estimate the size of the screen with the
%projector set up. The sides of the screen are being cut off so this will
%provide a good estimate.

%Need a line that we can adjust the size of. We want it to save or spit out
%the length of the line in pixes. 

%Be able to adjust the center point and with the game pad have both lines
%move outward at the same time.
%adjust the center of the circle using the right,left and up and down keyes.
%adjust the length of lines using left pad up and down.

%% Housekeeping

close all;
clear all;
clc;

%% Sinc test & OpenGL

% SKIP SYNC TEST
Screen('Preference', 'SkipSyncTests', 1); 
%it does not seem to be actually skipping the sync test 

%OPENGL
AssertOpenGL;

%% Window

%WINDOW PERAMETERS
%Identify the Number of screens
ScreenID = max(Screen('Screens')); %the largest number will be the screen that the stim is drawn to
  
 %WHICH SCREEN TO DRAW ON
 [win]=Screen('OpenWindow',ScreenID,[128,128,128]); %window fills screen
 %[win]=Screen('OpenWindow',ScreenID,[],[0 0 1000 1000]); 
 
%WINDOW DIMENTION IN PX 
[winXpx, winYpx]=Screen('WindowSize',ScreenID);

%PIXELS IN THE CENTER OF THE WINDOW
[Xwincent, Ywincent] = RectCenter([0 0 winXpx winYpx]);

%% Stimulus Variables

%LOAD PREVIOUS CENTER VALUES
load('LastLineCent.mat'); %a structure with the x and y variables in pixes of the center of the circle
Xcent = LastLineCent.Xcent; %center variables for the line
Ycent = LastLineCent.Ycent;


%Line variables
LineWidth_px = 20;
LineLength_px = 600; %make this an even number
HalfLineLength = LineLength_px./2;
% LeftSideLength_px = 200;
% RightSideLength_px = 200;
LineColor = [0 0 0];
Adjustment = 30;
IncrementToAdjustAdjustment = 4;

xCoords = [-HalfLineLength HalfLineLength 0 0];
yCoords = [0 0 -LineWidth_px LineWidth_px];
AllCoords = [xCoords; yCoords];

%% Draw the line 
ResponseLoop =1;

while ResponseLoop == 1

Screen('FillRect',win,[128,128,128]); %grey background
Screen('DrawLines',win,AllCoords,LineWidth_px,LineColor,[Xcent,Ycent]);


Screen('Flip', win);

%Check response
GamePad = GamePadInput([]);
if GamePad.buttonChange == 1 %Game pad button press check
    if GamePad.buttonB == 1 %move the center of the lines to the right
        Xcent = Xcent - Adjustment;
    end
    if GamePad.buttonX == 1 %move center of the lines to the left
        Xcent = Xcent + Adjustment;
    end
    if GamePad.buttonY == 1 %move center of the lines up
        Ycent = Ycent - Adjustment;
    end
    if GamePad.buttonA == 1 %move center of the lines down
        Ycent = Ycent + Adjustment;
    end
    %ADJUST LINE LENGTH
    if GamePad.directionChoice == 0 %left pad up increase line length
        LineLength_px = LineLength_px + Adjustment;
    end
    if GamePad.directionChoice == 180 %left pad down, retract line in both directions
        LineLength_px = LineLength_px - Adjustment;
    end
    %CHANGE ADJUSTMENT INCREMENT
    if GamePad.buttonLeftUpperTrigger == 1 %increase adjustment increment
        Adjustment = Adjustment + IncrementToAdjustAdjustment;
    end
    if (GamePad.buttonLeftLowerTrigger == 1) && (Adjustment > IncrementToAdjustAdjustment) %decrease adjustment increment
        Adjustment = Adjustment - IncrementToAdjustAdjustment;
    end
    %SELECT LINE SIZE
    if GamePad.buttonRightUpperTrigger == 1 %to select a length
        ResponseLoop = 0; %end response loop
        WindowSize.LineLength_px = LineLength_px;
        EndTime = datestr(clock,'mm_dd_yy_HHMM');
    end
    
    %REDRAW LINE
    HalfLineLength = LineLength_px./2;
    xCoords = [-HalfLineLength HalfLineLength 0 0];
    yCoords = [0 0 -LineWidth_px LineWidth_px];
    AllCoords = [xCoords; yCoords];
end

end %end of response loop

if ResponseLoop == 0
    %Save the location of the center of the line
    LastLineCent.Xcent = Xcent;
    LastLineCent.Ycent = Ycent;
    LineSavdir = 'D:\Tuten_Lab\Expt_Masking\Code\TutenLabExperiments\CalibrationStim\';
    LineSave_file = 'LastLineCent.mat';
    Linefilename = [LineSavdir LineSave_file];
    save(Linefilename,'LastLineCent');
    
    %Save responses
    Savdir = 'D:\Tuten_Lab\Expt_Masking\Code\TutenLabExperiments\CalibrationStim\WindowSize\';
    Save_file = strcat('WindowSize_px','_',EndTime,'.mat');
    filename = [Savdir Save_file];
    save(filename, 'WindowSize');
        
end

sca;

