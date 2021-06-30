% This script is an initial attempt at plotting some analyses from the
% stabilized vs unstabilized acuity experiments of AB/JOM/WST. It creates a
% stimulation map using stimulus delivery locations that have been computed
% from the individual trial videos (this part is done in another bit of
% code); this is plotted as a contour on the retinal image. It also shows
% how the stimulus location in the raster was distributed over the course
% of the experiment. Finally, performance is plotted for "natural eye
% motion" vs the "stabilized" condition where FEMs are counteracted by the
% AOSLO.
%
% 5-2-21    wst getting started on this 

close all
clear all
clc;

% Update this folder to be accurate for your own system
% startPath = 'C:\Users\William Tuten\Box\Tuten Lab\Projects\RetinalMotionAndAcuity\Raw Data';
startPath = '/Volumes/LaCie/RetinalMotionAndAcuity'; % Alisa's personal mac from removable drive
if ~ispc; menu('Select directory with natural motion acuity experiment','OK'); end % workaround for mac
unstabilizedDir = uigetdir(startPath, 'Select directory with natural motion acuity experiment');

if ~ispc; menu('Select directory with retinally-stabilized acuity experiment','OK'); end % workaround for mac
stabilizedDir = uigetdir(startPath, 'Select directory with retinally-stabilized acuity experiment');


% Find sumframe image in unstabilized dir
sumFrameImageList = dir([unstabilizedDir filesep 'sumframe*.tif']);
if length(sumFrameImageList) == 1
    sumFrameImage = im2double(imread(fullfile(sumFrameImageList.folder,sumFrameImageList.name)));
    sumFrameImageRGB = repmat(sumFrameImage, [1 1 3]); % Convert grayscale image to RGB format
else
    error('Sum frame image not found');
end


%% Start with "natural eye motion" condition

% Find data file to figure out the E size
dataFileList_Natural = dir([unstabilizedDir filesep '*acuityData.mat']);

for n = 1:length(dataFileList_Natural)
    try
        a = load(fullfile(dataFileList_Natural(n).folder, dataFileList_Natural(n).name));
        if isfield(a,'expParameters')
            expParameters = a.expParameters;
            if ~isfield(expParameters, 'MARPixels')
                expParameters.MARPixels = expParameters.MARsizePixels;
            end
        else
            error('expParameters not found');
        end
    catch
        % do nothing
    end
end

if isfield(a,'correctVector')
    percentCorrect_Natural = 100.*sum(a.correctVector)./length(a.correctVector);
else
    percentCorrect_Natural = [];
end

letterE_halfWidth = round(2.5*expParameters.MARPixels); % letter size is 5x MAR, so multiply by 2.5 to get the "halfwidth"

% Find delivery files
deliveryFiles_Natural = dir([unstabilizedDir filesep '*ELocs.mat']);

% Cycle through and determine where the E landed (1) on the retina and (2)
% in the raster on every stimulus frame; plot this as a contour


% Pre-allocate matrix for delivery contour images
deliveryContourImageUnstab_Natural = zeros(size(sumFrameImage));
deliveryContourImageStab_Natural = deliveryContourImageUnstab_Natural;
frameCounter = 0;
threshVal = 0.8; % Threshold for max_val

for n = 1:length(deliveryFiles_Natural)
    try
    tempELocs = load(fullfile(deliveryFiles_Natural(n).folder, deliveryFiles_Natural(n).name)); %load in each trial
    if isfield(tempELocs, 'ELocs')
        ELocs = tempELocs.ELocs;
        if ~isfield(ELocs, 'stabilized') || ~isfield(ELocs, 'unstabilized')
            error('Need to have searched for the E in both stabilized and unstabilized videos')
        end
        for j = 1:length(ELocs.stabilized.xLoc)
            if ELocs.stabilized.max_val(j) >= threshVal % don't use frames below threshold
            % Start with a blank slate
            tempDCIM_unstab = zeros(size(sumFrameImage));
            tempDCIM_stab = tempDCIM_unstab;
            tempDCIM_unstab((ELocs.unstabilized.yLoc-letterE_halfWidth):(ELocs.unstabilized.yLoc+letterE_halfWidth), ...
                (ELocs.unstabilized.xLoc-letterE_halfWidth):(ELocs.unstabilized.xLoc+letterE_halfWidth)) = 1; % draws E in the matrix
            deliveryContourImageUnstab_Natural = deliveryContourImageUnstab_Natural + tempDCIM_unstab;
            
             tempDCIM_stab(ELocs.stabilized.yLoc-letterE_halfWidth:ELocs.stabilized.yLoc+letterE_halfWidth, ...
                ELocs.stabilized.xLoc-letterE_halfWidth:ELocs.stabilized.xLoc+letterE_halfWidth) = 1;
            deliveryContourImageStab_Natural = deliveryContourImageStab_Natural + tempDCIM_stab;
            
            % Update frame counter
            frameCounter = frameCounter+1;
            end
        end
    end
    catch
        % do nothing
    end
end

deliveryContourImageStabNormalized_Natural = deliveryContourImageStab_Natural./frameCounter;
deliveryContourImageUnstabNormalized_Natural = deliveryContourImageUnstab_Natural./frameCounter;

% show image
f1 = figure; hold on;
set(f1,'Units', 'inches', 'position',[2 2 12 8], 'Color', 'w')

subplot('Position', [0.0500    0.5500    0.2667    0.4000]), imshow(sumFrameImageRGB), hold on
xlim([101 612]); ylim([101 612]); title('Retinal coordinates');
text(115, 612-10, 'Natural FEM', 'Color', 'w', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'FontSize', 14);
[~,c1] = contour(deliveryContourImageStabNormalized_Natural, [0.05 0.1:0.1:1], 'LineWidth', 1.5);
caxis([0 1]);

subplot('Position', [0.3333    0.5500    0.2667    0.4000]), imagesc(deliveryContourImageUnstabNormalized_Natural), axis square, 
xlim([1 512]); ylim([1 512]); title('Raster coordinates'); set(gca, 'YTick', '', 'XTick', ''); caxis([0 1]);

%% Next do the "NO FEM" condition

% Find data file
dataFileList_Natural = dir([stabilizedDir filesep '*acuityData.mat']);
for n = 1:length(dataFileList_Natural)
    try
        b = load(fullfile(dataFileList_Natural(n).folder, dataFileList_Natural(n).name));
    catch
    end
end

if isfield(b,'correctVector')
    percentCorrect_NoFEM = 100.*sum(b.correctVector)./length(b.correctVector);
else
    percentCorrect_NoFEM = [];
end

% Find delivery files
deliveryFiles_NoFEM = dir([stabilizedDir filesep '*ELocs.mat']);

% Cycle through and determine where the E landed (1) on the retina and (2)
% in the raster on every stimulus frame; plot this as a contour


% Pre-allocate matrix for delivery contour images
deliveryContourImageUnstab_NoFEM = zeros(size(sumFrameImage));
deliveryContourImageStab_NoFEM = deliveryContourImageUnstab_NoFEM;
frameCounter = 0;
for n = 1:length(deliveryFiles_NoFEM)
    try
        %tempELocs = load(fullfile(deliveryFiles_NoFEM(n).folder, deliveryFiles_NoFEM(n).name));
        tempELocs = load(fullfile(deliveryFiles_NoFEM(n).folder, deliveryFiles_NoFEM(n).name));
        if isfield(tempELocs, 'ELocs')
            ELocs = tempELocs.ELocs;
            if ~isfield(ELocs, 'stabilized') || ~isfield(ELocs, 'unstabilized')
                error('Need to have searched for the E in both stabilized and unstabilized videos')
            end
            for j = 1:length(ELocs.stabilized.xLoc)
                % Start with a blank slate
                tempDCIM_unstab = zeros(size(sumFrameImage));
                tempDCIM_stab = tempDCIM_unstab;
                
                tempDCIM_unstab(ELocs.unstabilized.yLoc-letterE_halfWidth:ELocs.unstabilized.yLoc+letterE_halfWidth, ...
                    ELocs.unstabilized.xLoc-letterE_halfWidth:ELocs.unstabilized.xLoc+letterE_halfWidth) = 1;
                deliveryContourImageUnstab_NoFEM = deliveryContourImageUnstab_NoFEM + tempDCIM_unstab;
                
                tempDCIM_stab(ELocs.stabilized.yLoc-letterE_halfWidth:ELocs.stabilized.yLoc+letterE_halfWidth, ...
                    ELocs.stabilized.xLoc-letterE_halfWidth:ELocs.stabilized.xLoc+letterE_halfWidth) = 1;
                deliveryContourImageStab_NoFEM = deliveryContourImageStab_NoFEM + tempDCIM_stab;
                
                % Update frame counter
                frameCounter = frameCounter+1;
            end
        end
    catch
        % do nothing
    end
end

deliveryContourImageStabNormalized_NoFEM = deliveryContourImageStab_NoFEM./frameCounter;
deliveryContourImageUnstabNormalized_NoFEM = deliveryContourImageUnstab_NoFEM./frameCounter;

% show image
set(f1,'Units', 'inches', 'position',[2 2 9 6], 'Color', 'w')

subplot('Position', [0.0500    0.1250    0.2667    0.4000]), imshow(sumFrameImageRGB), hold on
xlim([101 612]); ylim([101 612]); %title('Retinal coordinates');
text(115, 612-10, 'No FEM', 'Color', 'w', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'FontSize', 14);
[~,c2] = contour(deliveryContourImageStabNormalized_NoFEM, [0.05 0.1:0.1:1], 'LineWidth', 1.5);
caxis([0 1]);

subplot('Position', [0.3333    0.1250    0.2667    0.4000]), imagesc(deliveryContourImageUnstabNormalized_NoFEM), axis square, 
xlim([1 512]); ylim([1 512]); %title('Raster coordinates'); 
set(gca, 'YTick', '', 'XTick', ''); caxis([0 1]);

% Plot the color bar manually so it looks nice
cmap = colormap;
axColorbar = subplot('Position', [0.0500    0.1000    0.5500    0.0200]); 
imagesc(imrotate((reshape((cmap),[length(cmap),1,3])),90));
axColorbar.YTick = '';
axColorbar.XTick = linspace(1,64,3);
axColorbar.XTickLabel = {'0', '0.5', '1.0'};
axColorbar.FontSize = 10;
axColorbar.TickLength = [0 0];
xlabel('Proportion stimulated')
%% Plot performance

if ~isempty(percentCorrect_NoFEM) || ~isempty(percentCorrect_Natural)
    subplot(2,3,[3 6]); hold on
    b1 = bar(1, percentCorrect_Natural, 'FaceColor', [0 50 98]./255);
    b2 = bar(2, percentCorrect_NoFEM, 'FaceColor', [196 130 14]./255);
    ylim([25 75]);
    set(gca, 'YAxisLocation', 'right')
    ylabel('Percent correct (4AFC)', 'FontSize', 14, 'Rotation', 270, 'VerticalAlignment', 'Bottom')
    set(gca, 'YTick', 25:5:100, 'XTick', [1 2], 'XTickLabel',{'Natural FEM', 'No FEM'}, 'XTickLabelRotation', 45, 'LineWidth', 1);
    grid on; box on
    title('Tumbling E performance')
end

% Save the figure
print(gcf, fullfile(startPath, [expParameters.subjectID '_FEM_Acuity_Results_04_29_2021.png']), '-dpng2')



    