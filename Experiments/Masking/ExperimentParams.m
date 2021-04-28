function [expParams,st] = ExperimentParams(expParams,data)
%This has all of the experiment parameters for the masking experiment
%Note: expParam structure will get saved. the st structure will not get
%saved


%TRIALS & CONDITIONS
expParams.NumbOfCond = 5;
%trials per condition - if you wanted a different number of trials per condition
expParams.TrialNumb_GreyField = expParams.TrialsPerStaircase;
expParams.TrialNumb_Grating0Hz = expParams.TrialsPerStaircase;
expParams.TrialNumb_Grating4Hz = expParams.TrialsPerStaircase;
expParams.TrialNumb_Grating10Hz = expParams.TrialsPerStaircase;
expParams.TrialNumb_Grating15Hz = expParams.TrialsPerStaircase;
%total trials
expParams.TotalTrials = (expParams.TrialNumb_GreyField + expParams.TrialNumb_Grating0Hz + expParams.TrialNumb_Grating4Hz + ...
                        expParams.TrialNumb_Grating10Hz + expParams.TrialNumb_Grating15Hz).*expParams.NumbOfStaircasesPerCond;



%SURROUND CIRCLE
%Circle diameter in visual angle
expParams.CircDiam_dg=7;
%Circle diameter in pixels
expParams.CircDiam_px=expParams.displayPixelsPerDegree.*expParams.CircDiam_dg;
expParams.CircRad_px = round(expParams.CircDiam_px./2);
%Circle Luminance

expParams.CircLum = [128,128,128];
st.CircLumVal = expParams.CircLum(1,1); %needed for luminance adjustment of test spot
%CIRC ADJUSTMENT VARIABLES
expParams.AdjustIncrement_px = 10;%30;


%TEST SPOT
expParams.TestSpotDiam_dg = 0.38; %visual angle of test spot
expParams.TestSpotDiam_px = expParams.displayPixelsPerDegree.*expParams.TestSpotDiam_dg; %diameter in pxiels
expParams.TestSpotRad_px = round(expParams.TestSpotDiam_px./2); %radius of test spot
expParams.TestSpotDur_Sec = 0.1; %100ms

%FIXATION LINE - 4 tick marks will be around the circl eto direct the
%participant's gaze to the center of the circle
expParams.FixLineWidth_dg = 0.06;
expParams.FixLineLength_dg = 1.4;
expParams.FixLineWidth_px = round(expParams.displayPixelsPerDegree.*expParams.FixLineWidth_dg);
expParams.FixLineLength_px = round(expParams.displayPixelsPerDegree.*expParams.FixLineLength_dg); 
%fixation lines when waiting for a response
FixLineRespWidth_dg = 0.02;
expParams.FixLineRespWidth_px = round(FixLineRespWidth_dg.*expParams.displayPixelsPerDegree);
st.FixLinePos1_px = expParams.CircRad_px;
st.FixLinePos2_px = expParams.CircRad_px-expParams.FixLineLength_px;
expParams.FixLineRGB = [0,0,0];
%determine coordinates of the fixation lines
st.xCoords = [-st.FixLinePos1_px,-st.FixLinePos2_px,0,0,st.FixLinePos1_px,st.FixLinePos2_px,0,0];
st.yCoords = [0,0,st.FixLinePos1_px,st.FixLinePos2_px,0,0,-st.FixLinePos1_px,-st.FixLinePos2_px];
st.AllCoords = [st.xCoords; st.yCoords];


%GREATING OSCILLATION/FLICKER
expParams.flickerDuration_Sec = 1.1; %duration the grating flickers
expParams.OneOscillation_sec_4Hz = 4; %the lines swich from black to white 4 times in 1 sec (black white black white)
expParams.OneOscillation_sec_10Hz = 10;
expParams.OneOscillation_sec_15Hz = 15;
expParams.FlickerRt_Hz = [0, 0, expParams.OneOscillation_sec_4Hz, expParams.OneOscillation_sec_10Hz, expParams.OneOscillation_sec_15Hz]; %later index into this array%the first two conditions do not need a flicker rate


%BEEPER - there is a beep after response is recorded
expParams.RespBeepFq = 300; %210
expParams.RespBeepVol = 3;
expParams.RespBeepDur_s = 0.1;
 
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


%TEXT VARIABLES
if data.HomeVersion == 1 
    expParams.HFlip = 0; %do not flip text on the home version
    expParams.VFlip = 0;
else
    expParams.HFlip = 1; %flip over horizontal axis
    expParams.VFlip = 0;
    
end
expParams.textSize = 50;
expParams.XTxtCenter = 400; %used to center the text
expParams.YTxtCenter = expParams.CircRad_px + 20;


end

