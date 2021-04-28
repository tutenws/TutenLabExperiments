%Checker board 2


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
 [win]=Screen('OpenWindow',ScreenID); %window fills screen
 %[win]=Screen('OpenWindow',ScreenID,[],[0 0 1000 1000]); 
 
%WINDOW DIMENTION IN PX 
[winXpx, winYpx]=Screen('WindowSize',ScreenID);

%PIXELS IN THE CENTER OF THE WINDOW
[Xwincent, Ywincent] = RectCenter([0 0 winXpx winYpx]);

%% Stimulus Variables

CheckerWidth_px = 100;

%% Draw Checkerboard

%number of checkers/squares you will need to fill the screen
XNumbOfCheck = round(winXpx./CheckerWidth_px); %number of checkers we need to fill width of screen
YNumbOfCheck = round(winYpx./CheckerWidth_px); %numb of checks we need to fill height of screen

%create a vector with 0s and 255s representing the number of checkers we
%need in each row
CheckAlteration = repmat([0 255],1,XNumbOfCheck); %create an array of 0s and 255 
%repeat each number in the array the width of each checker
CheckerRow1_OnePix = repelem(CheckAlteration,CheckerWidth_px); %one row of pixes that is black and white depending on the checker
CheckerRow_1 = repmat(CheckerRow1_OnePix,CheckerWidth_px,1); %repeat the checker pixels in the Y dimention to create one row of checkers
CheckerRow_1 = CheckerRow_1(:,1:winXpx); %crop the checkers to be the correct x length
%make a checker row with the oposite luminance
CheckerRow2_OnePix = CheckerRow1_OnePix(1,CheckerWidth_px:length(CheckerRow1_OnePix)); %crop the first square out
CheckerRow_2 = repmat(CheckerRow2_OnePix,CheckerWidth_px,1); %repeat the checker pixels in the Y dimention to create one row of checkers
CheckerRow_2 = CheckerRow_2(:,2:winXpx+1); %crop the checkers to be the correct x length
 
%Now we need to place the Checker row 1 and 2 in alternating positions in
%the display
TwoRowsCheckers = cat(1,CheckerRow_1,CheckerRow_2);
Repeat = round(YNumbOfCheck./2); %how many rows of the Tworow can go into the screen
ScreenCheckers = repmat(TwoRowsCheckers,Repeat,1);

%Make the checker texture
CheckerTexture = Screen('MakeTexture',win,ScreenCheckers);

%Make checkers display until keyboard button is pressed
Screen('DrawTexture',win,CheckerTexture);
Screen('Flip',win);

KbWait;

sca;



