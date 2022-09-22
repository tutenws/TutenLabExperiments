% AMB Plot: Retinal Motion and Acuity
% plot using outputs from RetinalMotionAcuity_Bootstrap
% loads in .mat files from PCorr_AllData by  subject
clear all; clc;
dataFolder = '/Users/alisabraun/Desktop/Combined';
subjectIds = {'10001R', '20114L', '20210R', '20217L', '10003L', '20229L'};
legend_text = {'10001R', '20114L', '20210R', '20217L', '10003L', '20229L','Average +/- SEM'};

% get data file names
for s = 1:length(subjectIds)
    subjectId = char(subjectIds(s));
    [FilenamesOld] = FindDataFiles([char(dataFolder) filesep],'_bootstrapCI');
end

Filenames = FilenamesOld;

% remove names w/ . first
for i = 1:length(FilenamesOld)
    if char(FilenamesOld{i}(1)) == '.'
        Filenames(i) = [];
    end
end

% load in data
for c = 1:length(Filenames)
        load([dataFolder, filesep, filesep, char(Filenames{c})])
        % load in data
        pCorrLogRatiosAll(c,:) = pCorrLogRatios * 100;
        firstQuantileAll(c,:) = firstQuantile * 100;
        lastQuantileAll(c,:) = lastQuantile * 100;
        sub(c) = extract(string(Filenames(c)),digitsPattern); % take only a part of the file name 1-5

end

ratios_firstQ = nanmean(firstQuantileAll);
ratios_lastQ = nanmean(lastQuantileAll);
mean_ratios = nanmean(pCorrLogRatiosAll);
sem_ratios = std(pCorrLogRatiosAll)/sqrt(length(subjectIds));
for i = 1:length(sem_ratios)
    if isnan(sem_ratios(i))
        sem_ratios(i) = nanstd(pCorrLogRatiosAll(:,i))/sqrt(sum(~isnan(pCorrLogRatiosAll(:,i))));
    end
end

upperEB = mean_ratios+sem_ratios;
lowerEB = mean_ratios-sem_ratios;


f1 = figure; hold on;
set(f1, 'Units', 'inches', 'Position', [.25 .25 12 9], 'Color', 'w');
fontSize = 30;
lineWidth = 2;
markerSize = 20;
plotColor = [.95 .58 .39];
jitterMultiplier = 0;

% markerTypes = ('k^:ks:kd:ko:');

for i = 1:length(subjectId)
    % some subjects don't have all durations, so if they have an NaN plot
    % durations except those with NaN
    if isnan(sum(pCorrLogRatiosAll(i,:)))
        temp_dur = dur(~isnan(pCorrLogRatiosAll(i,:)));
        temp_pCorrLogRatios = pCorrLogRatiosAll(i,(~isnan(pCorrLogRatiosAll(i,:))));
        % just take the durations where there aren't NaNs
        plot(temp_dur+(randn(1,length(temp_dur))*jitterMultiplier),temp_pCorrLogRatios, 'MarkerSize', markerSize*.5, 'MarkerEdgeColor',plotColor,'MarkerFaceColor',plotColor);
        hold on;
    else
        plot(dur+(randn(1,length(dur))*jitterMultiplier),pCorrLogRatiosAll(i,:), 'MarkerSize', markerSize*.5, 'MarkerEdgeColor',plotColor,'MarkerFaceColor',plotColor);
    end
    hold on;
end


linePlot = plot([0 799], [0 0], 'k:', 'LineWidth', 2, 'HandleVisibility', 'off'); 
avgData = errorbar(dur, mean_ratios, abs(mean_ratios - lowerEB), ...
    abs(mean_ratios-upperEB),'-o','MarkerSize', markerSize, 'MarkerEdgeColor', ...
    'black','MarkerFaceColor','black', 'LineWidth',2.5, 'Color', 'black');
hold on;
ylabel('Δ from Stabilization (% Gain 1-Gain 0)', 'FontSize', fontSize)
xlabel('Duration (ms)', 'FontSize', fontSize)
ylim([-10 20])
xlim([0 799])
set(gca, 'FontSize', fontSize)
set(gcf, 'Color', [1 1 1])
set(gca, 'LineWidth', lineWidth)

grid on; box on;
title('Group Average','FontSize', 30);
legend(legend_text, 'Location','northeast','FontSize', fontSize);
% hLegend = legend({'WT 680nm', 'Average +/- SEM'}, 'Location','northeast','FontSize', fontSize);
figName = 'Group_LogratioVsDur.png';
saveas(f1, figName);
