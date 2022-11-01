function Acuity_Tumbling_E
%% Visual acuity experiment for AOMcontrol

global SYSPARAMS StimParams VideoParams;

% Not sure what this does, exactly
if exist('handles','var') == 0
    handles = guihandles;
end

startup;

% Get experiment config data stored in appdata for 'hAomControl'
hAomControl = getappdata(0,'hAomControl');

%------HARD-CODED PARAMETER STUFF FOLLOWS----------------------------------
use_params = input('Do you want to use previous params? y/n:  ','s');

if use_params == 'n'
    % if we do not want to use previous parameters - we can edit them here
    % Experiment parameters -- BASIC
    expParameters.subjectID = GetWithDefault('Subject ID','Test'); % Videos will save starting with this prefix
    expParameters.aosloPPD = 545; % pixels per degree, adjust as needed
    expParameters.aosloFPS = 30; % UCB frame rate, in Hz

    % Experiment parameters -- STIMULUS & VIDEO
    expParameters.testDurationMsec = GetWithDefault('Timing: enter duration in msc', 750); % Stimulus duration, in msec
    expParameters.testDurationFrames = round(expParameters.aosloFPS*expParameters.testDurationMsec/1000);
    expParameters.stimulusTrackingGain = GetWithDefault('Gain: 1 = tracking, 0 = natural',1); % Set to "1" for retinal tracking; otherwise set to "0" to deliver "world-fixed" stimuli
    expParameters.gainLockFlag = 1; % Set to "1" to enable "gain lock" mode where stimuli are initially delivered to a tracked location and then stay put in the raster (see below)
    expParameters.videoDurationMsec = 1000; % Video duration, in msec
    expParameters.videoDurationFrames = round(expParameters.aosloFPS*(expParameters.videoDurationMsec/1000)); % Convert to frames
    expParameters.record = 1; % Set to one if you want to record a video for each trial
    expParameters.staircase = GetWithDefault('Staircase: 1 = staircase, 0 = fixed trials', 0); % Set to one if you want to use a staircase, 0 for trials
    expParameters.offset = 0;
    
    % Experiment parameters -- STAIRCASE/QUEST
    expParameters.staircaseType = 'Quest';
    expParameters.nTrials =  GetWithDefault('Number of trials', 100); % Number of trials per staircase or exp
    expParameters.numStaircases = 1; % Interleave staircases? Set to >1
    expParameters.feedbackFlag = 0; % Set to one if you want to provide feedback to the subject
    expParameters.MARsizePixels =  GetWithDefault('MAR Pixels', 10); % Width in pixels of one bar of the letter E
    expParameters.logMARsizePixels = log10(expParameters.MARsizePixels); % In log units
    expParameters.MARguesssizePixels =  15; % Width in pixels of one bar of the letter E
    expParameters.logMARguessPixels = log10(expParameters.MARguesssizePixels); % In log units
    expParameters.tGuessSd = 3; % Width of Bayesian prior, in log units
    expParameters.pThreshold = .8; % If 4AFC, halfway between 100% and guess rate (25%) = .625
    % updated to .8 for jitter exp.
    expParameters.beta = 3.5; % Slope of psychometric function
    expParameters.delta = 0.01; % Lapse rate (proportion of suprathreshold trials where subject makes an error)
    expParameters.gamma = 0.25; % 4 alternative forced-choice = 25 percent guess rate
    save('ExpParams.mat', 'expParameters')
elseif use_params == 'y'
    load('ExpParams.mat')
end



%------END HARD-CODED PARAMETER SECTION------------------------------------
% Create QUEST structures, one for each staircase
if expParameters.staircase == 1
    for n = 1:expParameters.numStaircases
        q(n,1) = QuestCreate(expParameters.logMARguessPixels, expParameters.tGuessSd, ...
            expParameters.pThreshold, expParameters.beta, expParameters.delta, expParameters.gamma);
    end
end

% Directory where the stimuli will be written and accessed by ICANDI
% [rootDir, ~, ~] = fileparts(pwd);
rootDir = pwd;
expParameters.stimpath = [rootDir filesep 'tempStimulus' filesep];
if ~isdir(expParameters.stimpath)
    mkdir(expParameters.stimpath);
end



% Some boilerplate AOMcontrol stuff
if SYSPARAMS.realsystem == 1
    StimParams.stimpath = expParameters.stimpath; % Directory where the stimuli will be written and accessed by ICANDI
    VideoParams.vidprefix = expParameters.subjectID;
    set(handles.aom1_state, 'String', 'Configuring Experiment...');
    set(handles.aom1_state, 'String', 'On - Experiment ready; press start button to initiate');
    if expParameters.record == 1 % Recording videos for each trial; set to zero if you don't want to record trial videos
        VideoParams.videodur = expParameters.videoDurationMsec./1000; % Convert to seconds; ICANDI will record a video for each trial of this duration
    end
    
    psyfname = set_VideoParams_PsyfileName(); % Create a file name to which to save data 
    Parse_Load_Buffers(1); % Not sure about what this does when called in this way
    set(handles.image_radio1, 'Enable', 'off');
    set(handles.seq_radio1, 'Enable', 'off');
    set(handles.im_popup1, 'Enable', 'off');
    set(handles.display_button, 'String', 'Running Exp...');
    set(handles.display_button, 'Enable', 'off');
    set(handles.aom1_state, 'String', 'On - Experiment mode - Running experiment...');
end

% Establish file name, perhaps from psyfname, so that videos and
% experiment data file are saved together in the same folder
[rootFolder, fileName, ~] = fileparts(psyfname);
dataFile = [rootFolder filesep fileName '_acuityData.mat'];

% Stimulus location is selected by user click in ICANDI, but if you are
% doing an "untracked" (i.e. gain = 0) experiment, this is a way to ensure
% the stimulus location in the raster is repeatable across
% subjects/sessions. That may be desirable if you are worried about the
% sinusoidal distortions associated with the resonant scanner -- and
% resultant desinusoiding of the stimulus that we do in software. I'm not
% sure how this will behave if you are using retinally-contingent delivery
% (gain = 1), so you might want to avoid this approach in that case.
if expParameters.stimulusTrackingGain == 0 && expParameters.gainLockFlag == 0
    centerCommand = sprintf('LocUser#%d#%d#', 256, 256);
    netcomm('write',SYSPARAMS.netcommobj,int8(centerCommand));
end

% Gain lock section here; need to describe this mode more fully in the
% comments
if expParameters.gainLockFlag == 1
    gainLockCommand = sprintf('Gain0Tracking#%d#',expParameters.gainLockFlag);
    netcomm('write',SYSPARAMS.netcommobj, int8(gainLockCommand));
end

% Set up a vector to draw stimulus offsets from

if expParameters.staircase == 0
    offsetVector = zeros(expParameters.nTrials,1);
    offsetVector(1:(round(expParameters.nTrials/4))) = expParameters.offset; % set 1/4 of the trials = to + stimulus jitter
    offsetVector((floor(expParameters.nTrials/4)+1:(floor(expParameters.nTrials/2)))) = -expParameters.offset; % set 1/4 of the trials = to - stimulus jitter
    offsetVector = offsetVector(randperm(length(offsetVector)));
else
    offsetVector = zeros(expParameters.nTrials*expParameters.numStaircases,1);
end
%% Main experiment loop

frameIndex = 2; % The index of the stimulus bitmap

% Generate the frame sequence for each AOSLO channel; these get stored in
% the "Mov" structure A stimulus "sequence" is a 1XN vector where N is the
% number of frames in the trial video; a one-second trial will have N
% frames, where N is your system frame rate. The values in these vectors
% will control what happens on each video frame, stimulus-wise. Most stuff
% will happen in the IR channel (aom 0), so a lot of this is just setting
% up and passing along zero-laden vectors.

% Place stimulus in the middle of the trial video
startFrame = floor(expParameters.videoDurationFrames/2)-floor(expParameters.testDurationFrames/2); % the frame at which it starts presenting stimulus
endFrame = startFrame+expParameters.testDurationFrames-1;

%AOM0 (IR) parameters
aom0seq = zeros(1,expParameters.videoDurationFrames);
aom0seq(startFrame:endFrame) = frameIndex;
% aom0seq(2) = frameIndex;
% "aom0locx" allows you to shift the location of the IR stimulus relative
% to the tracked location on the reference frame (or in the raster,
% depending on tracking gain). Units are in pixels.
aom0locx = zeros(size(aom0seq)); 
aom0locy = zeros(size(aom0seq)); % same as above, but for y-dimension
aom0pow = ones(size(aom0seq));

%AOM1 (RED, tyically) parameters
% aom1seq = zeros(size(aom0seq));
aom1seq = aom0seq;
aom1pow = ones(size(aom0seq));
aom1offx = zeros(size(aom0seq));
aom1offy = zeros(size(aom0seq));

%AOM2 (GREEN, typically) paramaters
aom2seq = zeros(size(aom0seq));
aom2pow = ones(size(aom0seq));
aom2offx = zeros(size(aom0seq));
aom2offy = zeros(size(aom0seq));

% Other stimulus sequence factors
gainseq = expParameters.stimulusTrackingGain*ones(size(aom1seq)); % Tracking gain; zero is world-fixed, one is retinally-stabilized

% Gain lock bug
% % if expParameters.gainLockFlag == 1 && expParameters.stimulusTrackingGain == 1 % Trying to set up some lines to test whether/how "gain lock" works
% %     gainseq(startFrame+1:end) = 0;
% % end

% gainseq = abs(gainseq-1); % Will, not sure

angleseq = zeros(size(aom1seq)); % Tracking "angle", typically stays at zero except for in specific experiments
stimbeep = zeros(size(aom1seq)); % ICANDI will ding on every frame where this is set to "1"
stimbeep(startFrame) = 1; % I usually have the system beep on the first frame of the presentation sequence

% Set up movie parameters, passed to ICANDI via "PlayMovie"
Mov.duration = expParameters.videoDurationFrames;
Mov.aom0seq = aom0seq;
Mov.aom0pow = aom0pow;
Mov.aom0locx = aom0locx; 
Mov.aom0locy = aom0locy;

Mov.aom1seq = aom1seq;
Mov.aom1pow = aom1pow;
Mov.aom1offx = aom1offx; % Shift of aom 1 (usually red) relative to IR; use this to correct x-TCA
Mov.aom1offy = aom1offy; % As above, for y-dimension

Mov.aom2seq = aom2seq;
Mov.aom2pow = aom2pow;
Mov.aom2offx = aom2offx; % Green TCA correction
Mov.aom2offy = aom2offy; % Green TCA correction

Mov.gainseq = gainseq;
Mov.angleseq = angleseq;
Mov.stimbeep = stimbeep;
Mov.frm = 1;
Mov.seq = '';

% Adjust these parameters to control which images/stimuli from the stimulus
% folder are loaded onto the FPGA board for potential playout
StimParams.fprefix = 'frame'; % ICANDI will try to load image files from the stimulus directory whose file names start with this (e.g. "frame2.bmp")
StimParams.sframe = 2; % Index of first loaded frame (i.e. "frame2") 
StimParams.eframe = 2; % Index of last loaded frame (i.e. "frame4")
StimParams.fext = 'bmp'; % File extension for stimuli. With the above, ICANDI will load "frame2.bmp", "frame3.bmp", and "frame4.bmp" onto the FPGA; no other files in the

% Generate the acuity test sequence
testSequence = [];
if expParameters.staircase == 0
   expParameters.numStaircases = 1;
end

for staircaseNum = 1:expParameters.numStaircases
    testSequence = [testSequence; repmat(staircaseNum, [expParameters.nTrials 1])]; %#ok<AGROW>
end


% Shuffle the test sequence
testSequence(:,end+1) = randn(length(testSequence),1); % Add random vector
testSequence = sortrows(testSequence, size(testSequence,2)); % Sort by random vector to shuffle
testSequence(:,end) = []; % Trim last column of sorted random numbers;

orientationSequence = 90.*randi([0 3], length(testSequence),1);
testSequence(:,end+1) = orientationSequence;

% Save responses and correct/incorrect here (Pre-allocate)
responseVector = nan(length(testSequence),1);
correctVector = responseVector;

% Make the E template;
basicE = ones(5,5);
basicE(:,1) = 0;
basicE(1:2:5,:) = 0;

% Initialize the experiment loop
presentStimulus = 1;
trialNum = 1;
runExperiment = 1;
lastResponse = []; % start with this empty
getResponse = 0; % set to zero to force the first recognized button press to be the one that triggers the stimulus presentation
WaitSecs(1);
Speak('Begin experiment.');


while runExperiment == 1 % Experiment loop
    
    % Get the game pad input
    [gamePad, ~] = GamePadInput([]);
    
    %compare the last response 
    if gamePad.buttonLeftUpperTrigger || gamePad.buttonLeftLowerTrigger % Start trial

        if ~isempty(lastResponse) %this only applies the first loop through?
            if ~strcmp(lastResponse, 'redo') && presentStimulus == 1 % if the response is NOT redo then log the most recent button press, then play stimulus sequence
                % Check if correct
                if orientationResp == testSequence(trialNum,end)
                    correct = 1;
                else
                    correct = 0;
                end
                
                % Give feedback, if desired
                if expParameters.feedbackFlag
                    if correct == 1
                        Speak('Yes');
                    elseif correct == 0
                        Speak('No');
                    end
                end

                correctVector(trialNum,1) = correct;
                responseVector(trialNum,1) = orientationResp;
                
                % Update the Quest structure if it is a staircase trial
                if expParameters.staircase == 1
                    q(testSequence(trialNum,1)) = QuestUpdate(q(testSequence(trialNum,1)), ...
                        log10(MARsizePixels), correct); %added call to expParameters.MARsizePixels
                end

                % Save the experiment data
                if expParameters.staircase == 1
                    save(dataFile, 'q', 'expParameters', 'testSequence', 'correctVector', 'responseVector', 'offsetVector');
                else
                    save(dataFile, 'expParameters', 'testSequence', 'correctVector', 'responseVector', 'offsetVector');
                end

                     trialNum = trialNum+1;

                if trialNum > length(testSequence) % Exit loop
%                     % Terminate experiment
                    %runExperiment = 0;
                    Beeper(400, 0.5, 0.15); WaitSecs(0.15); Beeper(400, 0.5, 0.15);  WaitSecs(0.15); Beeper(400, 0.5, 0.15);
                    Speak('Experiment complete');
                    TerminateExp;
                    break
%                         if trialNum > expParameters.nTrials
%                             % Exit the experiment
%                         end
                end

            end
        end

            % Show the stimulus
            
        if presentStimulus == 1
            if expParameters.staircase == 1
                expParameters.logMARsizePixels = (QuestQuantile(q(testSequence(trialNum,1)))); %trying to get staircase to work
            end
            MARsizePixels = round(10.^expParameters.logMARsizePixels); % Size of each bar in the E, in pixels
        if MARsizePixels < 1 % Min pixel value
            MARsizePixels = 1;
        elseif MARsizePixels > 25 % Max pixel value for MAR; actual E size will be 5x this
            MARsizePixels = 25;
        end
        
        % Offset the stimulus
        
        y_offset = 256 + offsetVector(trialNum);
%        check for if the Y jitter goes off the screen, if it does
%        make it a 0 jitter trial
        if (y_offset - MARsizePixels < 5) || (y_offset + MARsizePixels > 518)
            y_offset = 256;
            speak('Stimulus off screen')
        end
        
        %update offset
        offsetCommand = sprintf('LocUser#%d#%d#', 256, y_offset);
        netcomm('write',SYSPARAMS.netcommobj,int8(offsetCommand));
        WaitSecs(1);
        
        % Make the E
        if trialNum > expParameters.nTrials % Edge case: the trial counter is set greater than nTrials 
            trialNum = expParameters.nTrials;
        end
        
        testE = imrotate(imresize(basicE, MARsizePixels, 'nearest' ),testSequence(trialNum,2)); 
        testE = padarray(testE, [1 1], 1, 'both');
        
        % Save the E as a .bmp
        imwrite(testE, [expParameters.stimpath 'frame' num2str(frameIndex) '.bmp']);
        % Call Play Movie
        Parse_Load_Buffers(0);
        Mov.msg = ['Letter size (pixels): ' num2str(MARsizePixels) ...
            '; Trial ' num2str(trialNum) ' of ' num2str(length(testSequence))]; 
        setappdata(hAomControl, 'Mov',Mov);
        VideoParams.vidname = [expParameters.subjectID '_' sprintf('%03d',trialNum)];
        PlayMovie;
            
        % set getResponse to 1 (it will remain at 1 after the first
        % trial)
        getResponse = 1;

        % set presentStimulus to 0 to prevent the next trial from being
        % triggered before one of the response buttons (see below) is
        % pressed
        presentStimulus = 0;
        end
        
    elseif gamePad.buttonB % E pointing right in ICANDI
        if getResponse == 1
            lastResponse = 'right';
            % Once the subject has pressed something other than the
            % trigger, set this back to 1 so the next trial can be
            % initiated
            orientationResp = 0;
            Beeper(300, 1, 0.15)
            presentStimulus = 1;
        end
        
    elseif gamePad.buttonX % E pointing left in ICANDI
        if getResponse == 1
            lastResponse = 'left';
            orientationResp = 180; % Should look to the right if ICANDI is in fundus view
            Beeper(300, 1, 0.15)
            presentStimulus = 1;
        end
        
    elseif gamePad.buttonY % E pointing up
        if getResponse == 1
            lastResponse = 'up';
            orientationResp = 270;
            Beeper(300, 1, 0.15)
            presentStimulus = 1;
        end
        
    elseif gamePad.buttonA
        if getResponse == 1
            lastResponse = 'down';
            gamePad.buttonA % E pointing down
            orientationResp = 90;
            Beeper(300, 1, 0.15)
            presentStimulus = 1;
        end
        
        
    elseif gamePad.buttonRightUpperTrigger || gamePad.buttonRightLowerTrigger %gamePad.buttonStart %redo button
        if getResponse == 1
            lastResponse = 'redo';
            Speak('Re do');
            presentStimulus = 1;
        end
        
    elseif gamePad.buttonBack %terminate button
        if getResponse == 1
            lastResponse = 'terminate';
            Speak('experiment terminated');
            runExperiment = 0;
        end
    end
end


function startup

dummy=ones(10,10);
if isdir([pwd, filesep 'tempStimulus']) == 0
    mkdir(pwd,'tempStimulus');
    cd([pwd, filesep 'tempStimulus']);
    
    imwrite(dummy,'frame2.bmp');
    fid = fopen('frame2.buf','w');
    fwrite(fid,size(dummy,2),'uint16');
    fwrite(fid,size(dummy,1),'uint16');
    fwrite(fid, dummy, 'double');
    fclose(fid);
else
    cd([pwd, filesep 'tempStimulus']);
    delete ('*.*');
    imwrite(dummy,'frame2.bmp');
    fid = fopen('frame2.buf','w');
    fwrite(fid,size(dummy,2),'uint16');
    fwrite(fid,size(dummy,1),'uint16');
    fwrite(fid, dummy, 'double');
    fclose(fid);
end
cd ..;
