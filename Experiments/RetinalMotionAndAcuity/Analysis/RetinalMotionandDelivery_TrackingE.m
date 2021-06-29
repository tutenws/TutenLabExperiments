close all
clear all
clc;

currentDir = pwd;
%cd('C:\Users\AOSLO-AO\Documents\MATLAB\toolboxes\AOVIS_toolbox'); %
%Desktop in 408
cd('/Users/alisabraun/Documents/GitHub/AOVIS_toolbox') % Alisa's personal mac

% Start with unstabilized folder
%startPath = 'C:\Users\William Tuten\Box\Tuten Lab\Projects\RetinalMotionAndAcuity\Raw Data\';
% startPath = '/Users/alisabraun/Box/Projects/RetinalMotionAndAcuity/Raw
% Data/'; %Alisa's personal mac
startPath = '/Volumes/LaCie/RetinalMotionAndAcuity'; % Alisa's personal mac from removable drive
[~, expFolderName, ~] = fileparts(startPath); % get folder name for use in file names later on


% sum images
% get files from removable drive, only take those images that are 
vid.image_adder('startPath', startPath, 'imageType','avi', 'filterForStabilized', 'true') 
% vid.image_adder('startPath', 'C:\Users\tuten\Desktop', 'imageType','tif')


% %Make a nice image for plotting delivery locations by adding sumnorm images together
if ~ispc; menu('Select image(s)','OK'); end % workaround for mac
[fileNames, path] = uigetfile('*.tif', 'Select image(s)', ...
    'MultiSelect', 'on', startPath);

% % Cycle through images and add together
h = waitbar(0,'Adding images...');
for imageNum = 1:length(fileNames)
    waitbar(imageNum./length(fileNames), h, sprintf('Adding images (%d of %d)...', imageNum, length(fileNames)));
    tempIm = im2double(imread(fullfile(path, fileNames{imageNum})));
    if imageNum == 1
        sumImage = zeros(size(tempIm));
        sumImageBinary = sumImage;
    end
    sumImage = sumImage+tempIm; % add images together
    sumImageBinary = sumImageBinary+imbinarize(tempIm,1/257); % add binarized version for nice normalization later
end
close(h); % Close the waitbar

sumImageFinal = sumImage./sumImageBinary; % Normalize by the binarized image and save
imwrite(sumImageFinal, fullfile(path, ...
    ['sumframe_' expFolderName '.tif']), 'tiff', 'compression', 'none');


% Find Es in unstabilized videos (stim locations in raster/world
% space)
if ~ispc; menu('Select unstabilized video(s)','OK'); end % workaround for mac
[videoNames, path] = uigetfile('*.avi', 'Select unstabilized video(s)', ...
    'MultiSelect', 'on', path);

h = waitbar(0,'Finding Es in unstabilized videos...');

%load in the .mat file so that the E can be rotated accordingly
dataFile = dir([path '*_acuityData.mat']);

% for some reason there are two items, not sure why
if length(dataFile) == 1
    load(fullfile(dataFile.folder, dataFile.name))
elseif length(dataFile) > 1
    load(fullfile(dataFile(end).folder, dataFile(end).name));
else
    error('Data file not found!');
end

% stim size from exp file 
if isfield(expParameters,'MARsizePixels') == 1
    size = expParameters.MARsizePixels;
else
    size = expParameters.MARPixels;
end

for vidNum = 1:length(videoNames)
    waitbar(vidNum./length(videoNames), h, sprintf('Finding Es (video %d of %d)...', vidNum, length(fileNames)));
    % Find Es in video
    videoName = fullfile(path,videoNames{vidNum});
    % call each orientation
    orientation = testSequence(vidNum,2);
    [xLoc,yLoc,frameNum, max_val] = vid.find_E(videoName,size,orientation,0);

    % Save cross information to .mat file
    ELocs.unstabilized.xLoc = xLoc;
    ELocs.unstabilized.yLoc = yLoc;
    ELocs.unstabilized.frameNum = frameNum;
    ELocs.unstabilized.max_val = max_val;
    ELocs.unstabilized.vidName = videoName;
    
    save([videoName(1:end-4) '_ELocs.mat'], 'ELocs');
end
close(h); % Close the waitbar

% Now, find E in stabilized videos (stim locations in retina space)
if ~ispc; menu('Select stabilized video(s)','OK'); end % workaround for mac
[videoNames, path] = uigetfile('*stabilized.avi', 'Select stabilized video(s)', ...
    'MultiSelect', 'on', path);

h = waitbar(0,'Finding Es in stabilized videos...');
for vidNum = 1:length(videoNames)
    waitbar(vidNum./length(videoNames), h, sprintf('Finding Es (video %d of %d)...', vidNum, length(videoNames)));
    % Find Es in video
    videoName = fullfile(path,videoNames{vidNum});
    % call each orientation
    orientation = testSequence(vidNum,2);
    [xLoc,yLoc,frameNum, max_val] = vid.find_E(videoName,size,orientation,0);
    matFileName = [videoName(1:end-15) '_ELocs.mat'];    % Save E information to .mat file
    if exist(matFileName, 'file') == 2
        load(matFileName);
    end
    ELocs.stabilized.xLoc = xLoc;
    ELocs.stabilized.yLoc = yLoc;
    ELocs.stabilized.frameNum = frameNum;
    ELocs.stabilized.max_val = max_val;
    ELocs.stabilized.vidName = videoName;
    save(matFileName, 'ELocs');
end
close(h); % Close the waitbar
