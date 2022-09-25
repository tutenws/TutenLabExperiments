%% AMB, JOM & WT 11/22
% Compares FEM traces from ICANDI & RSLAM
% Still needs to be edited for time and offset between ICANDI&RSLAM
avg_PPD = 554.3; % change this based on the AOSLO's avg X&Y pixels per degree
ICandyvideoNumber = 2;
Rslam_VideoNumber = ICandyvideoNumber;
folder = '/Users/alisabraun/Documents/GitHub/TutenLabExperiments/Experiments/RetinalMotionAndAcuity/RSLAM_CSV/Stab';
ICandy_CSV_file = sprintf('10001R_00%d.csv', ICandyvideoNumber);
rslam_output_file = 'rslamv2_outputs.mat';
csvDataRaw = readtable(fullfile(folder, ICandy_CSV_file));
rslam_dataAll = load(fullfile(folder, rslam_output_file));
% reorganize csvdata
csvxdata = csvDataRaw{:,4:2:69}';
csvxdata = csvxdata(:);
csvydata = csvDataRaw{:,5:2:69}';
csvydata = csvydata(:);
csvdata = array2table([csvxdata csvydata], 'VariableNames',{'Xpos','Ypos'});
% center and transpose data to match
csvdata.XposZero = csvdata.Xpos - csvdata.Xpos(1);
csvdata.XposZero = csvdata.XposZero.*-1;
csvdata.YposZero = csvdata.Ypos - csvdata.Ypos(1);
csvdata.YposZero = csvdata.YposZero.*-1;
rslamdata = array2table(squeeze(rslam_dataAll.eye_motions(Rslam_VideoNumber,:,:)),'VariableNames',{'Timestamp', 'Xpos','Ypos'});
rslamdata.XposZero = rslamdata.Xpos-rslamdata.Xpos(1);
rslamdata.YposZero = rslamdata.Ypos-rslamdata.Ypos(1);
%convert to arcmin
csvdata.XposZeroArc = (csvdata.XposZero ./ avg_PPD) * 60;%% START HERE, look up PPD avg for all sessions
csvdata.YposZeroArc = (csvdata.YposZero ./ avg_PPD) * 60;
rslamdata.XposZeroArc = (rslamdata.XposZero ./ avg_PPD) * 60;
rslamdata.YposZeroArc = (rslamdata.YposZero ./ avg_PPD) * 60;
% plot
figure
subplot(2,1,1)
plot(csvdata.XposZero, 'g')
hold
plot(csvdata.YposZero);
legend('X pos','Y pos')
title(['Icandy ' strrep(ICandy_CSV_file,'_','\_')]);
subplot(2,1,2)
plot(rslamdata.Timestamp, rslamdata.XposZero, 'g')
hold
plot(rslamdata.Timestamp, rslamdata.YposZero);
legend('X pos','Y pos')
title(sprintf('Rslam video %d in %s', Rslam_VideoNumber, strrep(rslam_output_file,'_','\_')));