function [expParams,st] = ExperimentParams(expParams)
%This has all of the experiment parameters for the masking experiment
%Note: expParam structure will get saved. the st structure will not get
%saved

%TRIALS & CONDITIONS
expParams.NumbOfCond = 5;
expParams.TotalTrials = expParams.NumbOfCond.*expParams.TrialsPerStaircase;

%SURROUND CIRCLE
%Circle diameter in visual angle
expParams.CircDiam_dg=7;

%Circle diameter in pixels
expParams.CircDiam_px=expParams.displayPixelsPerDegree.*expParams.CircDiam_dg;
%Circle Luminance
expParams.CircLum = [128,128,128];
st.CircLumVal = expParams.CircLum(1,1); %needed for luminance adjustment of test spot


%TEST SPOT
expParams.TestSpotDiam_dg = 0.38; %visual angle of test spot
expParams.TestSpotDiam_px = expParams.displayPixelsPerDegree.*expParams.TestSpotDiam_dg; %diameter in pxiels

%FIXATION LINE - 4 tick marks will be around the circl eto direct the
%participant's gaze to the center of the circle
expParams.FixLineWidth_px = 2;
expParams.FixLineLength_px = 100;
st.FixLinePos1_px = expParams.CircDiam_px./2;
st.FixLinePos2_px = (expParams.CircDiam_px./2)-expParams.FixLineLength_px;
expParams.FixLineRGB = [0,0,0];
%determine coordinates of the fixation lines
st.xCoords = [-st.FixLinePos1_px,-st.FixLinePos2_px,0,0,st.FixLinePos1_px,st.FixLinePos2_px,0,0];
st.yCoords = [0,0,st.FixLinePos1_px,st.FixLinePos2_px,0,0,-st.FixLinePos1_px,-st.FixLinePos2_px];
st.AllCoords = [st.xCoords; st.yCoords];


%GREATING OSCILLATION
expParams.OneOscillation_sec_4Hz = 1./4; %the lines swich from black to white 4 times in 1 sec (black white black white)
expParams.OneOscillation_sec_10Hz = 1./10;
expParams.OneOscillation_sec_15Hz = 1./15;
 
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




end

