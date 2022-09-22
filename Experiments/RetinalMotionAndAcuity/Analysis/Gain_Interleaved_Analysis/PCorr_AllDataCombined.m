%% AB
% correct ratios between stab/unstab conditions w/ bootstrapped CIs
% using ALL interleaved and regular data

clear all; close all;
subjectIds = {'10001R'}; %'10001R', '20114L', '20210R', '20217L', '10003L', '20229L'
subjectIdsInter =  {'10001R'}; %'10001R', '10003L', '20229L'
% dataFolder = '/Volumes/LaCie/Retinal_MotionandAcuity_Backup_June_30/FVM_Motion_Acuity/Analysis/Matlab Analysis';
% dataFolderInter = '/Volumes/LaCie/Retinal_MotionandAcuity_Backup_June_30/Rochester/Interleaved Gain/Code/Matlab_Analysis';
dataFolder = '/Users/alisabraun/Desktop/Combined/Matlab_Analysis';
dataFolderInter = '/Users/alisabraun/Desktop/Combined/Matlab_Analysis_Inter';
conditionNames = {'30ms', '60ms', '100ms', '375ms', '563 ms', '750 ms'}; % '30ms', '60ms', '100ms', '375ms', '563 ms', '750 ms'
dur = [30 60 100 375 563 750]; %30 60 100 375 563 750
numBootstraps = 1000; 
alpha = 0.05;

testSequencenew = [];
table_stim_duration = [];
table_subjId = [];
table_trialNum = [];
table_matfileName = [];
table_unstxlocs = [];
table_unstylocs = [];
table_stxlocs = [];
table_stylocs = [];
table_goodDelivery = [];
table_stimulus_travel_dist = [];
table_trackingGain = [];
table_correctVector = [];
table_stimOrientation = [];
table_responseVector = [];

subjectIdsAll = union(subjectIds, subjectIdsInter); %combine all subjects

% get % correct from stab/unstab
for s = 1:length(subjectIdsAll)
    ResponseFilenamesAll = [];
    ResponseFilenames = [];
    ResponseFilenamesInter = [];
    % use different directories for normal and interleaved data
    if ismember(subjectIdsAll(s),subjectIds)
        subjectId = char(subjectIdsAll(s));
        [ResponseFilenames] = FindDataFiles([char(dataFolder) filesep char(subjectId) filesep],'acuityData');
    end
    % add interleaved datafiles to ResponseFilenames
    if ismember(subjectIdsAll(s),subjectIdsInter)
        subjectIdInter = char(subjectIdsAll(s));
        [ResponseFilenamesInter] = FindDataFiles([char(dataFolderInter) filesep char(subjectIdInter) filesep],'acuityData');
    end
    %combine the 2 ResponseFilenames
    ResponseFilenamesAll = [ResponseFilenames ResponseFilenamesInter];

    clear durations trackingGain

    for c = 1:length(ResponseFilenamesAll)
        % sometimes this loads in files that don't exist that all start with
        % ._ , so first we want to remove those file names
        % this might add a placeholder NaN to some variables i.e. durations
        % or tracking Gain

        if char(ResponseFilenamesAll{c}(1)) ~= '.'
            % load if its a part of the normal dataset
            if ismember(ResponseFilenamesAll{c},ResponseFilenames)
                load([dataFolder, filesep, char(subjectIdsAll(s)), filesep, char(ResponseFilenamesAll{c})])
            end

            % load if its in the interleaved dataset
            if ismember(ResponseFilenamesAll{c},ResponseFilenamesInter)
                load([dataFolderInter, filesep, char(subjectIdsAll(s)), filesep, char(ResponseFilenamesAll{c})])
            end

            durations(c) = expParameters.testDurationMsec;
            trackingGain(c) = expParameters.stimulusTrackingGain;
            correctVectorBig(c,:) = correctVector;
            testSequenceBig(c,:) = testSequence(:,2);
            responseVectorBig(c,:) = responseVector;
            %load in the analysis data for which trials to exclude normal
            if ismember(ResponseFilenamesAll{c},ResponseFilenames)
                load([dataFolder, filesep, char(subjectIdsAll(s)), filesep, char(ResponseFilenamesAll{c}(1:end-14)), 'DeliverySuccess'])
            end
            %load in the analysis data for which trials to exclude inter
            if ismember(ResponseFilenamesAll{c},ResponseFilenamesInter)
                if trackingGain(c) == 1
                    load([dataFolderInter, filesep, char(subjectIdsAll(s)), filesep, char(ResponseFilenamesAll{c}(1:end-19)), 'DeliverySuccessGain1'])
                else
                    load([dataFolderInter, filesep, char(subjectIdsAll(s)), filesep, char(ResponseFilenamesAll{c}(1:end-19)), 'DeliverySuccessGain0'])
                end
            end
            
            delivery_successBig(c,:) = [deliveryCorrect.countSuccess];

            %pull the x y coordinates from delivery success from the
            %delivery files

            for i = 1:length(delivery_successBig(c,:))
                % remove trial that are NaN in countSuccess
                if ~isnan(deliveryCorrect(i).countSuccess)
                    xlocBig(c,i) = join(string(deliveryCorrect(i).unstxloc)); %using unst xloc
                    ylocBig(c,i) = join(string(deliveryCorrect(i).unstyloc)); %using unst yloc
                    if ismissing(xlocBig(c,i))
                        xlocBig(c,i) = string(missing);
                        ylocBig(c,i) = string(missing);
                    end
                    stxlocBig(c,i) = join(string(deliveryCorrect(i).xloc)); %using unst xloc
                    stylocBig(c,i) = join(string(deliveryCorrect(i).yloc)); %using unst yloc
                    % take out larger travel vectors
                    if durations(c) > 30
                        for i = 1:length(xlocBig(c,:))
                            if ~ismissing(xlocBig(c,i))
                                temp_x = str2num(char(split(xlocBig(c, i))))';
                                temp_y = str2num(char(split(ylocBig(c, i))))';

                                travel_dist(i) = sum(sqrt(diff(temp_x).^2 + diff(temp_y).^2));

                                % throw out trials with too large of movements (issue tracking E) > 100
                                % pixels of movement in AO system

                                if travel_dist(i) > durations(c)/5
                                    travel_dist(i) = nan;
%                                     xlocBig(c, i) = nan;
%                                     ylocBig(c, i) = nan;
                                end
                            end

                        end
                    end


                else
                    xlocBig(c,i) = string(missing);
                    ylocBig(c,i) = string(missing);
                end 
            end
                               % save a table with all of the variables
        file_length = length(delivery_successBig(c,:));

        table_stim_duration = vertcat(table_stim_duration, repmat(durations(c), file_length, 1)); %make a vector listing the durations
        table_subjId = vertcat(table_subjId, repmat(str2num(subjectId(1:5)), file_length, 1)); % make a big list of the subject IDs for each trial
        table_trialNum = vertcat(table_trialNum, (1:file_length)');
        table_matfileName = vertcat(table_matfileName, repmat(ResponseFilenamesAll(c), file_length,1));
        table_unstxlocs = vertcat(table_unstxlocs, xlocBig(c,:)');
        table_unstylocs = vertcat(table_unstylocs, ylocBig(c,:)');
        table_stxlocs = vertcat(table_stxlocs, stxlocBig(c,:)');
        table_stylocs = vertcat(table_stylocs, stylocBig(c,:)');
        table_goodDelivery = vertcat(table_goodDelivery, delivery_successBig(c,:)');
        table_stimulus_travel_dist = vertcat(table_stimulus_travel_dist,travel_dist');
        table_trackingGain = vertcat(table_trackingGain, repmat(trackingGain(c), file_length,1));
        table_correctVector = vertcat(table_correctVector, correctVector);
        table_stimOrientation = vertcat(table_stimOrientation, testSequence(:,2));
        table_responseVector = vertcat(table_responseVector, responseVector);

        % take out travel distances that are too long from x&ylocbig
        for i = 1:length(travel_dist)
            if ismissing(travel_dist(i))
                xlocBig(c, i) = nan;
                ylocBig(c, i) = nan;
            end
        end

        else
            durations(c) = NaN;
            trackingGain(c) = NaN;
            correctVectorBig(c,:) =  NaN([1 100]);
            delivery_successBig(c,:) =  NaN([1 100]);
        end
    end

    conditions = [transpose(durations), transpose(trackingGain)];
    uniqueConditions = unique([transpose(durations), transpose(trackingGain)],'rows');
    h1 = figure; set(h1,'Position',[322         394        1252         584])


    for d = 1:length(dur)
        % only choose the duration/gain we need
        gain1idx = conditions(:,1) == dur(d) & conditions(:,2) == 1;
        gain0idx = conditions(:,1) == dur(d) & conditions(:,2) == 0;
        correctVectorGain1 = correctVectorBig(logical(gain1idx),:);
        delivery_success_gain1 = delivery_successBig(logical(gain1idx),:);
        xlocGain1 = xlocBig(logical(gain1idx),:);
        ylocGain1 = ylocBig(logical(gain1idx),:);
        xlocGain0 = xlocBig(logical(gain0idx),:);
        ylocGain0 = ylocBig(logical(gain0idx),:);
        % remove bad trials
        correctVectorGain1 = reshape( correctVectorGain1, size( correctVectorGain1,1) *size( correctVectorGain1,2),1);
        correctVectorGain1 = correctVectorGain1(~isnan(delivery_success_gain1));
        xlocGain1 = reshape( xlocGain1, size( xlocGain1,1) *size( xlocGain1,2),1);
        ylocGain1 = reshape( ylocGain1, size( ylocGain1,1) *size( ylocGain1,2),1);
        xlocGain0 = reshape( xlocGain0, size( xlocGain0,1) *size( xlocGain0,2),1);
        ylocGain0 = reshape( ylocGain0, size( ylocGain0,1) *size( ylocGain0,2),1);
        xlocGain1 = xlocGain1(~ismissing(xlocGain1));
        ylocGain1 = ylocGain1(~ismissing(xlocGain1));
        ylocGain0 = ylocGain0(~ismissing(ylocGain0));
        ylocGain0 = ylocGain0(~ismissing(ylocGain0));

        % if there is a subject without a certain duration, leave it blank
if ~isempty(ylocGain0)
        propCorrectBootstrapGain1 = zeros(numBootstraps,1); % Pre-allocate
        % Do the simulation
        for n = 1:numBootstraps
            % Resample with replacement
            samplingVector = randi([1 length(correctVectorGain1)], length(correctVectorGain1),1); % We will use the data at these indices only; "with replacement" means some indices will be included more than once.
            % Compute bootstrapped percent correct for this iteration
            propCorrectBootstrapGain1(n,1) = sum(correctVectorGain1(samplingVector))./length(correctVectorGain1);
        end
        

        gain0idx = conditions(:,1) == dur(d) & conditions(:,2) == 0;
        correctVectorGain0 = correctVectorBig(logical(gain0idx),:);
        correctVectorGain0 = reshape( correctVectorGain0, size( correctVectorGain0,1) *size( correctVectorGain0,2),1);
        delivery_success_gain0 = delivery_successBig(logical(gain0idx),:);
        xlocGain0 = reshape( xlocGain0, size( xlocGain0,1) *size( xlocGain0,2),1);
        xlocGain0 = xlocGain0(~ismissing(xlocGain0));
        ylocGain0 = reshape( ylocGain0, size( ylocGain0,1) *size( ylocGain0,2),1);
        ylocGain0 = ylocGain0(~ismissing(ylocGain0));
        

        % record how many trials we are keeping for each trial
        num_trials_gain0(s,d) = length(xlocGain0);
        num_trials_gain1(s,d) = length(xlocGain1);

        propCorrectBootstrapGain0 = zeros(numBootstraps,1); % Pre-allocate
        % Do the simulation
        for n = 1:numBootstraps
            % Resample with replacement
            samplingVector = randi([1 length(correctVectorGain0)], length(correctVectorGain0),1); % We will use the data at these indices only; "with replacement" means some indices will be included more than once.
            % Compute bootstrapped percent correct for this iteration
            propCorrectBootstrapGain0(n,1) = sum(correctVectorGain0(samplingVector))./length(correctVectorGain0);
        end
        
        bootstrapCorrRatios = log10(propCorrectBootstrapGain1./propCorrectBootstrapGain0);
        
                
        
        pCorrGain1=sum(correctVectorGain1)./length(correctVectorGain1);
        pCorrGain0=sum(correctVectorGain0)./length(correctVectorGain0);
        
        pCorrRatios(d) = pCorrGain1./pCorrGain0;
        pCorrLogRatios(d) = log10(pCorrRatios(d));

        % Compute some quantiles that span the central % of the simulated data
        firstQuantile(d) = quantile(bootstrapCorrRatios, alpha/2);
        lastQuantile(d) = quantile(bootstrapCorrRatios, 1-(alpha/2));
else
    % if the subject does not have data at this duration, leave it blank
    bootstrapCorrRatios(d) = NaN;
    pCorrLogRatios(d) = NaN;
    pCorrRatios(d) = NaN;
    firstQuantile(d) = NaN;
    lastQuantile(d) = NaN;

end
        
        figure(h1); subplot(2,ceil(length(dur)/2),d);
        histogram(bootstrapCorrRatios,15);
        hold on;
        ylimits = get(gca, 'YLim');
        % Plot the actual proportion correct as a dashed line
        plot([pCorrLogRatios(d) pCorrLogRatios(d)], ylimits, 'k:', 'LineWidth', 3)
        
        
        % Plot those quantiles
        plot([firstQuantile(d) firstQuantile(d)], ylimits, 'k-', 'LineWidth', 1.5);
        plot([lastQuantile(d) lastQuantile(d)], ylimits, 'k-', 'LineWidth', 1.5);
        
        ylabel('Count', 'FontSize', 14);
        xlabel('Proportion Correct', 'FontSize', 14);
        title(['Proportion correct:' pCorrRatios(d)]);
        axis square;

    end
    
    h2 = figure; 
    errorbar(dur,pCorrLogRatios,abs([firstQuantile - pCorrLogRatios]),abs([lastQuantile - pCorrLogRatios]),'o:')
    xlimits = get(gca, 'XLim');
    hold on; plot([xlimits], zeros(size(xlimits)), '-k')
    xlabel('Duration (ms)');
    ylabel('Log ratio (stabilized/unstabilized)'); 
    title(['Proportion correct:' subjectIdsAll(s)])

    subtitle([num2str(sum(num_trials_gain0(s,:))) ' unstabilized & ' num2str(sum((num_trials_gain1(s,:)))) ' stabilized trials total'])

    saveName = [char(subjectIdsAll(s)),'_bootstrapCI.mat'];
    save(saveName,'dur', 'firstQuantile', 'lastQuantile', 'pCorrLogRatios')
    
    figName = [char(subjectIdsAll(s)),'_LogratioVsDur.png'];
    saveas(h2, figName);
%     
%     figName = [subjectId,'_BootstrapHistograms.png'];
%     saveas(h1, figName);

end


% make variable 'use this trial', which takes a few parameters and == 1 if
% the trial should be kept in any analysis

for i = 1:length(table_goodDelivery)
    % if none of these is NaN, use it
    A = [table_unstxlocs(i), table_stxlocs(i), table_goodDelivery(i), table_stimulus_travel_dist(i)];
    use_trial(i) = 1;
    if anymissing(A)
        use_trial(i) = 0;
    end
end


T = table(num_trials_gain1, num_trials_gain0, 'RowNames', subjectIdsAll);
tableName = ['NumberTrialsKept.mat'];
save(tableName, 'T')

data_table = table();
data_table.stim_duration = table_stim_duration;
data_table.subjId = table_subjId;
data_table.trialNum = table_trialNum;
data_table.matfileName = table_matfileName;
data_table.unstxlocs = table_unstxlocs;
data_table.unstylocs = table_unstylocs;
data_table.stxlocs = table_stxlocs;
data_table.stylocs = table_stylocs;
data_table.goodDelivery = table_goodDelivery;
data_table.stimulus_travel_dist = table_stimulus_travel_dist;
data_table.tracking_gain = table_trackingGain;
data_table.correctVector = table_correctVector;
data_table.stimOrientation = table_stimOrientation;
data_table.responseVector = table_responseVector;
data_table.useTrial = use_trial';

tableName = ['AllData.mat'];
save(tableName, 'data_table')

