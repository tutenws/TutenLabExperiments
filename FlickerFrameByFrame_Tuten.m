%Will 20/19/20 

sca;
close all;
% First, play out a smooth ramp from black to red, one frame at a time
redVals = linspace(1,255,255); % Play these red levels
numberOfFrames = length(redVals); % Computer number of frames

% Get the screen number
screenNumber = max(Screen('Screens'));

% Get the frame rate
frameRate = Screen('FrameRate', screenNumber);

% Open a black window
[win, windowRect] = Screen('OpenWindow', screenNumber, [0 128 128], [0 0 500 700]);

% Get interframe interval
ifi = Screen('GetFlipInterval', win);

% Pre-allocate time stamp vectors associated with Screen('Flip'); these are
% used in the diagnostic plots below
v = zeros(numberOfFrames,1);
s = v;
f = v;
m = v;

% Cycle through frames and display;
tic;
for frameNumber = 1:numberOfFrames
    Screen('FillRect', win, [redVals(frameNumber) 0 0], windowRect);
    [v(frameNumber),s(frameNumber),f(frameNumber),m(frameNumber)] = Screen('Flip', win);
    WaitSecs(0.75*ifi);
end

% Print timing measurements to screen
timeElapsed = toc;
timeExpected = (numberOfFrames*ifi);
fprintf('Time elapsed: %.2f sec\n', timeElapsed);
fprintf('Time expected: %.2f sec\n', timeExpected);

Screen('CloseAll');

%% Now let's try something similar using pre-made textures, flickering between black and full-on red at a specified frequency and adding a gray spot into the middle
AssertOpenGL;
% Open a black window offscreen
[win, windowRect] = Screen('OpenWindow', screenNumber, [0 0 0], [0 0 500 700]);

flickerDurationSec = 1.1; % How long the demo plays
numberOfFramesTexture = round(frameRate.*flickerDurationSec);
flickerRateHz = 4; % Flicker frequency, in Hz;
flickerPeriodSec = 1/(2*flickerRateHz);
flickerPeriodFrames = round(flickerPeriodSec.*frameRate);
numFlickerCycles = ceil(flickerDurationSec/flickerRateHz^-1);


spotDurationSec = 0.1; % How long the spot is on
spotDurationFrames = round(spotDurationSec.*frameRate);
spotRGB = [128 128 128]; % Spot color
spotSize = 200;

startFrame = floor(numberOfFramesTexture/2 - spotDurationFrames/2);

% Let's make 4 textures: 1 = black only, 2 = red only, 3 = black + spot, 4
% = red + spot

% Make a template for our test spot
[xCenter, yCenter] = RectCenter(windowRect); % Find center of open window
spotImage = Circle(spotSize/2); % Make a circle
blankIm = zeros(windowRect(4), windowRect(3)); % Make a blank canvas
testIm = blankIm;
[xi, yi] = CenterMatOnPoint(spotImage, xCenter, yCenter);
testIm(yi, xi) = spotImage; % Center the circle in the canvas
blackImage = repmat(blankIm, [1 1 3]);
redImage = blackImage;
redImage(:,:,1) = 255;

blackImageSpot = cat(3, testIm.*spotRGB(1), testIm.*spotRGB(2), testIm.*spotRGB(3));
testImRed = testIm.*spotRGB(1);
testImRed(testIm==0) = 255; % Set black areas to max red
redImageSpot  = cat(3, testImRed, testIm.*spotRGB(2), testIm.*spotRGB(3));

tex(1) = Screen('MakeTexture', win, blackImage);
tex(2) = Screen('MakeTexture', win, redImage);
tex(3) = Screen('MakeTexture', win, blackImageSpot);
tex(4) = Screen('MakeTexture', win, redImageSpot);

% Video sequence
Beeper; 
KbWait;
% Open a black window offscreen
% [win, windowRect] = Screen('OpenWindow', screenNumber, [0 0 0], [0 0 500 700]);

% First make alternating periods of ones and twos
seedSequence = [ones(1,flickerPeriodFrames) 2.*ones(1,flickerPeriodFrames)];
flickerSequence = repmat(seedSequence, [1 numFlickerCycles]);

spotSequence = zeros(size(flickerSequence));
spotSequence(startFrame:startFrame+spotDurationFrames-1) = 2;

videoSequence = flickerSequence+spotSequence;

if length(videoSequence) > numberOfFramesTexture
    videoSequence(numberOfFramesTexture+1:end) = [];
end

v2 = zeros(numberOfFramesTexture,1);
s2 = v2;
f2 = v2;
m2 = v2;


for frameNumber = 1:length(videoSequence)
    Screen('DrawTexture', win, tex(videoSequence(frameNumber)));
    [v2(frameNumber),s2(frameNumber),f2(frameNumber),m2(frameNumber)] = Screen('Flip', win);
    WaitSecs(0.75*ifi);
end

sca;


% Diagnostic plots
figure, plot(1:numberOfFrames-1, 1000.*diff(s), '-', 'LineWidth', 2);
hold on, plot(1:numberOfFramesTexture-1, 1000.*diff(s2), '-', 'LineWidth', 2);
xlabel('Frame Number', 'FontSize', 14);
ylabel('Inter-stimulus interval (ms)', 'FontSize', 14);
plot([1 numberOfFrames-1], 1000.*[ifi ifi], 'k:', 'LineWidth', 3);
ylim([0 2000.*ifi]);
legend('Conventional approach', 'Scripted textures', 'Expected ifi');