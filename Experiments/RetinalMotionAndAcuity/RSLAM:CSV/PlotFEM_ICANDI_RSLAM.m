%% AMB & JOM Analysis 11/22
% can be used to compare FEM traces from ICANDI & RSLAM
% 
ICandyvideoNumber = 2;
Rslam_VideoNumber = ICandyvideoNumber;
folder = '/Users/alisabraun/Desktop/FEM Trace Verification/Unstab';
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
csvdata.XposZero = csvdata.Xpos - csvdata.Xpos(1);
csvdata.XposZero = csvdata.XposZero.*-1;
csvdata.YposZero = csvdata.Ypos - csvdata.Ypos(1);
csvdata.YposZero = csvdata.YposZero.*-1;
rslamdata = array2table(squeeze(rslam_dataAll.eye_motions(Rslam_VideoNumber,:,:)),'VariableNames',{'Timestamp', 'Xpos','Ypos'});
rslamdata.XposZero = rslamdata.Xpos-rslamdata.Xpos(1);
rslamdata.YposZero = rslamdata.Ypos-rslamdata.Ypos(1);
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