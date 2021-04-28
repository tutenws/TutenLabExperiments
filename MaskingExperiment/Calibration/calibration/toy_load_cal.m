load cal_03_05_20; %load the calibration file

[w,~] = Screen('OpenWindow',max(Screen('Screens'))); %open a window in PTB

LoadIdentityClut(w); %wipe any previous gamma table

Screen('FillRect',w,[0.9 .9 .9].*255);
Screen('Flip',w);
KbWait;
WaitSecs(1);

Screen('LoadNormalizedGammaTable',w,cal.lookup_table); %load the gamma table

Screen('FillRect',w,[0.9 .9 .9].*255);
Screen('Flip',w);
KbWait;

sca;