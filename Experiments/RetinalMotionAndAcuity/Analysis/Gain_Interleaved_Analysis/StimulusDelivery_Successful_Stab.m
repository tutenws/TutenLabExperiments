%%%%%
% AB Script for categorizing if the tumbling E stimulus was delivered successfully 
% in the AO system. Outputs are countSuccess (0 = not successful delivery)
% updatedCorrect (updated correct vector)
% and corrThreshold (values it used as a cutoff from E finding correlation
%%%%%

close all
clear all
clc;


xy_cutoff = 2; % Multiple of how many standard deviations an x or y loc can be from mean - 2 = x or y values can be 2 standard deviations from the mean
corr_thresh = 4; % Diviser, how far between the 2 groups of good/not good - larger = include more trials

%startPath = '/Volumes/LaCie/RetinalMotionAndAcuity/Data/Raw Data/Timing Data';
startPath = '/Volumes/LaCie/Retinal_MotionandAcuity_Backup_June_30/FVM_Motion_Acuity/Data/Raw Data/Timing Data';
% startPath = '/Users/alisabraun/Desktop/Test';

%if ~ispc; menu('Select directory with stabilized acuity experiment','OK'); end % workaround for mac
stabilizedDir = uigetdir(startPath, 'Select directory with stabilized acuity experiment');

filePath = stabilizedDir; % Change this to correspond to folder of interest containing stimulus_gain=1 data

eFiles = dir([filePath filesep '*ELocs.mat']); % Find the E locs files
dataFile = dir([filePath filesep '*acuityData.mat']); % Find the data file

if length(dataFile) == 1
    load(fullfile(dataFile.folder, dataFile.name))
    linkFile = extractBefore(dataFile.name,'_acuityData.mat');
elseif length(dataFile) > 1
    load(fullfile(dataFile(end).folder, dataFile(end).name));
    linkFile = extractBefore(dataFile(end).name,'_acuityData.mat');
else
    error('Data file not found!');
end

% cycle through ELocs files in the folder
for fileNum = 1:length(eFiles)
%     if fileNum == 72
%         wait = 1
%     end
    
    load(fullfile(eFiles(fileNum).folder, eFiles(fileNum).name)); % load file
    
    % get trial number from .mat file name; probably the same as the order
    % in which "eFiles" is cycled through by the for loop but I'd rather not assume that
    fileNameSplit = strsplit(eFiles(fileNum).name, '_');
    trialNum = str2double(fileNameSplit{2});
    
    % "kmeans" separates any set of data into "k" clusters; here we use
    % this routine on the "max_val" from the ELocs structure, which will be
    % high when an E was found by the E-finding routine and lower when not.
    % The function returns an index indicating which cluster each data
    % point belongs to, along with the mean value of each cluster. This is
    % a way to programmatically decide which frames/trials should be
    % included in the delivery analysis
    
    k = 2; % Two clusters: i.e. with and without the E
    [clusterIndicies,clusterMeans] = kmeans(ELocs.stabilized.max_val,k);
    
    % Which index corresponds to the higher cluster of max_val (these are
    % presumably the frames with a good match for the "E" since max_val is
    % higher when the E is present)
    maxInd = find(clusterMeans==max(clusterMeans));
    
    % make sure that the larger mean values are always assigned 2
    if clusterIndicies(maxInd) == 2 % if it doesn't = 2, switch it
       clusterIndicies(clusterIndicies==1)=3;
       clusterIndicies(clusterIndicies==2)=1;
       clusterIndicies(clusterIndicies==3)=2;
    end
    
    %% Need to checkeach frame duration to get to 90% accuracy
    arraySuccess = 0;
    
    startFrame = ceil(expParameters.videoDurationFrames/2)-floor(expParameters.testDurationFrames/2) + 1; % the frame at which it starts presenting stimulus
    endFrame = startFrame+expParameters.testDurationFrames-1;
    

    %correcting for some variation in the way frames are shown
    if expParameters.testDurationFrames == 2 % 2 frames shown at different timepoints
        startFrame = startFrame + 1;
        endFrame = endFrame + 1;
    elseif mod(expParameters.testDurationFrames,2) == 1
        startFrame = startFrame + 1;
        endFrame = endFrame + 1;
    end
    
    deliveryCorrect(fileNum).updatedCorrect = NaN;
    corrSuccess = 0;
    deliveryCorrect(fileNum).countSuccess = NaN;
    
    % at each index of the values where clusterIndices == 2, check if its above threshold
    deliveryCorrect(fileNum).corrThreshold = min(clusterMeans) + (max(clusterMeans)-min(clusterMeans))/corr_thresh; % uses a fraction the difference between the two  means
    
    % In some cases, the AO computer failed to save all of the info from 
    % the trial. If that's the case, just remove that trial's data
    if length(ELocs.stabilized.max_val) < 29
        disp(['System failed to save AO video number ' num2str(fileNum)])
        deliveryCorrect(fileNum).countSuccess = NaN;
        deliveryCorrect(fileNum).xloc = NaN;
        deliveryCorrect(fileNum).yloc = NaN;
    else
        targetELocs = ELocs.stabilized.max_val(startFrame:endFrame);
        
        for corr = 1:length(targetELocs)
            if  targetELocs(corr) >= deliveryCorrect(fileNum).corrThreshold; % check if the values that were found were all abover a correlation value
                corrSuccess = corrSuccess + 1;
            end
        end
        if corrSuccess >= expParameters.testDurationFrames*.9; % check if there were enough frames for the .9% threshold
            deliveryCorrect(fileNum).countSuccess = 1;
        end
        
        % also filter these by if the X&Y coordinates in elocs are close or not,
        % but only for durations longer than 3 frames
        
        if deliveryCorrect(fileNum).countSuccess == 1 && expParameters.testDurationFrames > 3;
            x.target = ELocs.stabilized.xLoc(startFrame:endFrame);
            y.target = ELocs.stabilized.yLoc(startFrame:endFrame);
            x.median = median(x.target);
            y.median = median(y.target);
            
            % larger value means larger range of values we are willing to include
            x.cutoff = xy_cutoff*(std(x.target));
            y.cutoff = xy_cutoff*(std(y.target));
            
            x.min = x.median - (x.cutoff);
            x.max = x.median + (x.cutoff);
            y.min = y.median - (y.cutoff);
            y.max = y.median + (y.cutoff);
            for h = 1:length(x.target)
                % check x & y values and see if they fall between 1 standard
                % deviation, if not throw out the trial
                if x.target(h) >= x.min && x.target(h) < x.max && y.target(h) > y.min && y.target(h) < y.max;
                    deliveryCorrect(fileNum).countSuccess = 1;
                    deliveryCorrect(fileNum).xloc = x.target;
                    deliveryCorrect(fileNum).yloc = y.target;
                    %otherwise, do not include this trial (written so that I can
                    %comment out just this section)
                else
                    deliveryCorrect(fileNum).countSuccess = NaN;
                end
            end
        end
        
    %correcting for when the AO system rarely shows the stimulus a frame later
    %than we expect
    if mean(ELocs.stabilized.max_val(startFrame:endFrame)) < mean(ELocs.stabilized.max_val(startFrame+1:endFrame+1))
        deliveryCorrect(fileNum).countSuccess = NaN;
    end
        
        % get the x & y locs
        deliveryCorrect(fileNum).xloc = NaN;
        deliveryCorrect(fileNum).yloc = NaN;
        if deliveryCorrect(fileNum).countSuccess == 1
            deliveryCorrect(fileNum).xloc = ELocs.stabilized.xLoc(startFrame:endFrame);
            deliveryCorrect(fileNum).yloc = ELocs.stabilized.yLoc(startFrame:endFrame);
        end
        
        % update the variables we're outputting using the above exclusion factors
        if deliveryCorrect(fileNum).countSuccess == 1 && correctVector(fileNum) == 1;
            deliveryCorrect(fileNum).updatedCorrect = 1;
        elseif deliveryCorrect(fileNum).countSuccess == 1 && correctVector(fileNum) == 0;
            deliveryCorrect(fileNum).updatedCorrect = 0;
        end
    end 

%% also load in the unstab info so that we can plot the eye motion
if ~isnan(deliveryCorrect(fileNum).countSuccess)
    startFrame = startFrame-1; % one frame difference between stab & raw vides
    endFrame = endFrame-1;
    deliveryCorrect(fileNum).unstxloc = ELocs.unstabilized.xLoc(startFrame:endFrame);
    deliveryCorrect(fileNum).unstyloc = ELocs.unstabilized.yLoc(startFrame:endFrame);
        
else
    deliveryCorrect(fileNum).unstxloc = NaN;
    deliveryCorrect(fileNum).unstyloc = NaN;
end

    %correcting for when the AO system rarely shows the stimulus a frame later
    %than we expect, but for the unstabilized frames
    if mean(ELocs.unstabilized.max_val(startFrame:endFrame)) < mean(ELocs.unstabilized.max_val(startFrame+1:endFrame+1))
        deliveryCorrect(fileNum).countSuccess = NaN;
        deliveryCorrect(fileNum).unstxloc = NaN;
        deliveryCorrect(fileNum).unstyloc = NaN;
        deliveryCorrect(fileNum).xloc = NaN;
        deliveryCorrect(fileNum).yloc = NaN;
        deliveryCorrect(fileNum).updatedCorrect = NaN;
    end
    
% 
% %%% also exclude based on same criteria for the unstabilized trials
xun.target = ELocs.unstabilized.xLoc(startFrame:endFrame);
yun.target = ELocs.unstabilized.yLoc(startFrame:endFrame);
% xun.median = median(xun.target);
% yun.median = median(yun.target);
% 
% if deliveryCorrect(fileNum).countSuccess == 1 && expParameters.testDurationFrames >= 3;
%     % larger value means larger range of values we are willing to include
%     xun.cutoff = xy_cutoff*(std(xun.target));
%     yun.cutoff = xy_cutoff*(std(yun.target));
%     
%     xun.min = xun.median - (xun.cutoff);
%     xun.max = xun.median + (xun.cutoff);
%     yun.min = yun.median - (yun.cutoff);
%     yun.max = yun.median + (yun.cutoff);
%     for h = 1:length(xun.target)
%         % check x & y values and see if they fall between 1 standard
%         % deviation, if not throw out the trial
%         if xun.target(h) >= xun.min && xun.target(h) < xun.max && yun.target(h) > yun.min && yun.target(h) < yun.max;
%             deliveryCorrect(fileNum).countSuccess = 1;
%             deliveryCorrect(fileNum).unstxloc = xun.target;
%             deliveryCorrect(fileNum).unstyloc = yun.target;
%             %otherwise, do not include this trial (written so that I can
%             %comment out just this section)
%         else
%             deliveryCorrect(fileNum).countSuccess = NaN;
%             deliveryCorrect(fileNum).unstxloc = NaN;
%             deliveryCorrect(fileNum).unstyloc = NaN;
%             deliveryCorrect(fileNum).xloc = NaN;
%             deliveryCorrect(fileNum).yloc = NaN;
%             deliveryCorrect(fileNum).updatedCorrect = NaN;
%             
%         end
%     end
    %if the duration is 2 frams (60 ms), also have a cutoff
if expParameters.testDurationFrames == 2
    % if the eye has moved more than 10 pixels X or Y
    if (abs(xun.target(1) - xun.target(2)) > 50) || (abs(yun.target(1) - yun.target(2)) > 50)
        deliveryCorrect(fileNum).countSuccess = NaN;
        deliveryCorrect(fileNum).unstxloc = NaN;
        deliveryCorrect(fileNum).unstyloc = NaN;
        deliveryCorrect(fileNum).xloc = NaN;
        deliveryCorrect(fileNum).yloc = NaN;
        deliveryCorrect(fileNum).updatedCorrect = NaN;
    end
end
%     
% end


    
    
end

if fileNum < 100
    deliveryCorrect(100).unstxloc = NaN;
    deliveryCorrect(100).unstyloc = NaN;
    deliveryCorrect(100).updatedCorrect = NaN;
    deliveryCorrect(100).countSuccess = NaN;
    deliveryCorrect(100).xloc = NaN;
    deliveryCorrect(100).yloc = NaN;
end

analysisDir = ['/Volumes/LaCie/Retinal_MotionandAcuity_Backup_June_30/FVM_Motion_Acuity/Analysis/Matlab Analysis/' expParameters.subjectID];

% save([stabilizedDir filesep num2str(expParameters.testDurationMsec) 'ms_' expParameters.subjectID '_DeliverySuccess.mat'], 'deliveryCorrect');
%save([analysisDir filesep num2str(expParameters.testDurationMsec) 'ms_' expParameters.subjectID '_DeliverySuccess.mat'], 'deliveryCorrect');
save([stabilizedDir filesep linkFile '_DeliverySuccess.mat'], 'deliveryCorrect');
save([analysisDir filesep linkFile '_DeliverySuccess.mat'], 'deliveryCorrect');
save ([analysisDir filesep linkFile '_acuityData.mat'], 'expParameters', 'correctVector', 'expParameters', 'offsetVector', 'responseVector', 'testSequence');


