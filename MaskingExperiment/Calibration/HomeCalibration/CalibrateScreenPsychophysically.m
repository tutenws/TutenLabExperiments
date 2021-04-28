%% Psychophysical monitor calibration
close all;
clear all;
sca;

%% Open a Psychtoolbox window
screenNumber = max(Screen('Screens'));
windowSize = 880;

%[win, windowRect] = Screen('OpenWindow', screenNumber, 0, [0 0 windowSize windowSize]);
[win, windowRect] = Screen('OpenWindow', screenNumber, 0, [900 320 1780 1200]);%centers the screen

stepSize = 1;

% Line coordinates
numLines = length(1:2:windowSize);
xy = zeros(2,numLines*2);
xy(1,1:2:end) = ceil(windowSize/2);
xy(1,2:2:end) = windowSize;
xy(2,1:2:end) = 1:2:windowSize;
xy(2,2:2:end) = 1:2:windowSize;

xy_alt = [xy(1,:); xy(2,:)+1]; % Alternating lines (sometimes we want to specify the intensity here as well; for instance, to fill in intermediate values

% Show initial window
testVal = 255;


% Keyboard adjustment loop here
KbName('UnifyKeyNames');

numRepeatsPerLevel = 2; % Number of settings to make at each match level
showTextFlag = 1; % Set to 0 if you don't want to show the 0-255 values on each panel

% Set up match level sequence
numMatchLevels = 8;
halfValueTargets = 2.^-(linspace(0,numMatchLevels-1,numMatchLevels)); % Normalized "half values"
intermediateValueTargets = halfValueTargets(1:end-1)+diff(halfValueTargets)./2; % Pairwise average (i.e. midpoints) of halfValueTargets
fractionalValues = [halfValueTargets intermediateValueTargets];

testFlag = [zeros(size(halfValueTargets)) ones(size(intermediateValueTargets))]; % Zero value means you're in the recursive descent; one value means you'll use the initial settings to match at intermediate points
% testFlag = testFlag(i);
testIndex = [nan(2,length(halfValueTargets)) [1:length(intermediateValueTargets); 2:length(intermediateValueTargets)+1]];
% testIndex = testIndex(:,i);
outputMatrix = nan(length(fractionalValues),2, numRepeatsPerLevel);
outputMatrix(1,1,:) = 1;
outputMatrix(1,2,:) = 255;

for n = 1:numRepeatsPerLevel
    
    measNum = 2; % start at 2
    keepGoing = 1;
    updateFrame = 1;
    testVal = 255;
    lineVals = [testVal 0];
    halfVal = round(mean(lineVals)); % Starting level
    Screen('FillRect', win, halfVal, [0 0 ceil(windowSize/2) windowSize]);
    Screen('DrawLines', win, xy, 1, testVal);
    Screen('DrawText', win, sprintf('%d', halfVal), 25, 25, [0 255 0]);
    Screen('DrawText', win, sprintf('[%d   %d]', lineVals), ceil(windowSize/2)+25, 25, [0 255 0]);
    Screen('Flip', win);
    while keepGoing == 1
        [~,keyCode, ~] = KbWait;
        KbReleaseWait;
        keyName = KbName(keyCode);
        if strcmp(keyName, 'Return')
            fprintf('Measurement number %d; fractional value %0.2f\n', measNum, fractionalValues(measNum));
            % Log value
            outputMatrix(measNum,2,n) = halfVal;
            outputMatrix(measNum,1,n) = fractionalValues(measNum);
            % Check if last trial
            if measNum+1 > length(fractionalValues)
                keepGoing = 0;
                updateFrame = 0;
            else
                if testFlag(measNum+1) == 0
                    testVal = halfVal; % stay in recursive descent
                    halfVal = round(testVal/2);
                else
                    halfVal = round(mean(outputMatrix(testIndex(:,measNum+1),2)));
                end
                updateFrame = 1;
                measNum = measNum+1;
            end
        elseif strcmp(keyName, 'ESCAPE')
            % Abort
            keepGoing = 0;
            sca;
            numRepeatsPerLevel = numRepeatsPerLevel + 1;
        elseif strcmp(keyName, 'UpArrow')
            halfVal = halfVal + stepSize;
        elseif strcmp(keyName, 'DownArrow')
            halfVal = halfVal - stepSize;
        elseif strcmp(keyName, 'RightArrow') % Bigger steps
            halfVal = halfVal + 10;
        elseif strcmp(keyName, 'LeftArrow') % Bigger steps
            halfVal = halfVal - 10;
        end
        
        % Update frame
        if halfVal < 0
            halfVal = 0;
        elseif halfVal > 255
            halfVal = 255;
        end
        
        if updateFrame
            Screen('FillRect', win, halfVal, [0 0 ceil(windowSize/2) windowSize]);
            if testFlag(measNum) == 0
                Screen('DrawLines', win, xy, 1, testVal);
                Screen('DrawLines', win, xy_alt, 1, 0);
                lineVals = [testVal 0];
            else
                Screen('DrawLines', win, xy, 1, outputMatrix(testIndex(1,measNum),2,n));
                Screen('DrawLines', win, xy_alt, 1, outputMatrix(testIndex(2,measNum),2,n));
                lineVals = [outputMatrix(testIndex(1,measNum),2,n) outputMatrix(testIndex(2,measNum),2,n)];
            end
            if showTextFlag
                Screen('DrawText', win, sprintf('%d', halfVal), 25, 25, [0 255 0]);
                Screen('DrawText', win, sprintf('[%d   %d]', lineVals), ceil(windowSize/2)+25, 25, [0 255 0]);
            end
            Screen('Flip', win);
        end
    end
end

% Fit a power function
xData = mean(outputMatrix(:,2,:),3)./255; % Normalized 0-255 match setting values
yData = mean(outputMatrix(:,1,:),3); % These are the "fractional values"

f = fit(xData, yData, 'power1');
xEval = linspace(0, 1, 256);
yEvalPowerLaw = feval(f, xEval(2:end));

% Also to a 1-D interpolation, for comparison
xEval8Bit = linspace(0,255,256);
yDataInterp = interp1(xData.*255, yData, xEval8Bit);

% Plot the fit and the data
figure, plot(xEval(2:end).*255, yEvalPowerLaw, 'r-', 'LineWidth', 2);
hold on;
plot(xEval8Bit, yDataInterp, 'k:', 'LineWidth', 2);
plot(mean(outputMatrix(:,2,:),3), fractionalValues, 'ks', 'MarkerSize', 10, 'MarkerFaceColor', 'k')
text(10, 0.9, sprintf('Gamma = %.2f\n', f.b), 'FontSize', 12)
xlim([0 255])
ylim([0 1]);
axis square
xlabel('Input (0-255)', 'FontSize', 14);
ylabel('Normalized output', 'FontSize', 14);
legend('Gamma fit', '1-D interp', 'Location', 'SouthEast');

% Plot the gamma correction curves inverse gamma
gammaPowerLaw = (xEval8Bit./255).^(1/f.b);
gammaInterp = interp1(yData.*255, xData, xEval8Bit);
figure, plot(xEval8Bit, gammaPowerLaw, 'r-', 'LineWidth', 2);
hold on
plot(xEval8Bit, gammaInterp, 'k:', 'LineWidth', 2);
xlim([0 255])
ylim([0 1]);
axis square
xlabel('Target Output (0-255)', 'FontSize', 14);
ylabel('Normalized gun level', 'FontSize', 14);
title('Gamma corrections')
legend('Gamma fit', '1-D interp', 'Location', 'SouthEast');

% Do some checking...
%Show an intensity gradient; uniform fill of level on left half,
%alternating lines at level +/- "checkLevelsDelta" on the right; right half
%has the same gamma-corrected means as the left (uniform) half, so should
%perceive minimal (or no) border between the left and right hemifields
numCheckLevels = 11;
checkLevels = linspace(10,90,numCheckLevels);
checkLevels8Bit = round((checkLevels./100).*255);
checkLevelsDelta = 10; % Right side of the field will have alternating lines of "checkLevel" +/- this value
boxHeight = round(windowSize./numCheckLevels);

startRow = 1;
stopRow = startRow+boxHeight-1;
for n = 1:numCheckLevels
    Screen('FillRect', win, round(255.*gammaPowerLaw(checkLevels8Bit(n)+1)), [0 startRow-1 ceil(windowSize/2) stopRow]);
    Screen('DrawLines', win, xy(:,startRow:stopRow), 1, round(255.*gammaPowerLaw(checkLevels8Bit(n)+1+checkLevelsDelta)));
    Screen('DrawLines', win, xy_alt(:,startRow:stopRow), 1, round(255.*gammaPowerLaw(checkLevels8Bit(n)+1-checkLevelsDelta)));
    startRow = startRow+boxHeight;
    stopRow = stopRow+boxHeight;
end
Screen('DrawText', win, 'Intensity gradient...', 25, 25, [0 255 0]);
Screen('DrawText', win, 'Press any key to proceed', 25, windowSize-60, [0 255 0]);
Screen('Flip', win);

while ~KbCheck
end

% Now show uniform field on the left half at 50% level, and alternating line sections on the right with increasing contrast between lines
midPoint = 128;
contrastLevels = logspace(0,2,numCheckLevels);
contrastDeltas = round(contrastLevels.*midPoint./100);
startRow = 1;
stopRow = startRow+boxHeight-1;
for n = 1:numCheckLevels
    targetValue = 128+contrastDeltas(n)+1;
    if targetValue>256
        targetValue = 256;
    end
    highVal = round(255.*gammaPowerLaw(targetValue));
    lowVal = round(255.*gammaPowerLaw(128-contrastDeltas(n)+1));
    if lowVal<0
        lowVal = 0;
    end
    Screen('DrawLines', win, xy(:,startRow:stopRow), 1, highVal);
    Screen('DrawLines', win, xy_alt(:,startRow:stopRow), 1, lowVal);
    Screen('DrawText', win, sprintf('[%d  %d]', lowVal, highVal), 125+windowSize./2, startRow+25, [0 255 0]);  
    startRow = startRow+boxHeight;
    stopRow = stopRow+boxHeight;
end
Screen('FillRect', win, 255.*gammaPowerLaw(1+128), [0 0 ceil(windowSize/2) windowSize]);
Screen('DrawText', win, '50% check...', 25, 25, [0 255 0]);
Screen('DrawText', win, 'Press any key to proceed', 25, windowSize-60, [0 255 0]);
Screen('Flip', win);


% Close the PTB window
while ~KbCheck
    
end

save([cd '\gammaTable.mat'], 'gammaPowerLaw', 'gammaInterp');
sca;