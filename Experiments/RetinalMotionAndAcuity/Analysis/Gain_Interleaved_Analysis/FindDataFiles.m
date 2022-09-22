function [filenames] = FindDataFiles(dataDir, strCode)

% will find all data files in the input folder (dataDir) that contain a
% specific string identifier in the file name.
% inputs, 
% dataDir, the directory where the data files are stored. 
% strCode, a string unique to the files you are trying to identify. 

curdir = cd;
cd(dataDir);
fnames = dir; fnames = dir; 
fnames={fnames.name};
fileIdx = find(~cellfun('isempty',strfind(fnames,strCode)));
filenames = fnames(fileIdx);
cd(curdir)

end