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
% convert to arcmin
csvdata.XposZeroArc = (csvdata.XposZero ./ avg_PPD) * 60;
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
plot(rslamdata.Timestamp, rslamdata.XposZero, '.-g');
hold
plot(rslamdata.Timestamp, rslamdata.YposZero, '.-r');
hold
% fill in missing datapoints
% scatter(x,y);
% x = [1,2,3,5,6,7,8,16,17,19,43];
% y = [12,53,73,4,40,45,7,12,54,67,14];
c = [0.7 0.7 0.7];
idx = diff(rslamdata.Timestamp)>1;
hold on;
ctr = 1;
for i=1:length(idx)
    if idx(i)==1
        X = [rslamdata.Timestamp(i) rslamdata.Timestamp(i+1) rslamdata.Timestamp(i+1) rslamdata.Timestamp(i)];
        Y = [-60 -60 60 60];
        fill(X,Y,c);hold on;
    end
    ctr = ctr + 1;
end
legend('X pos','Y pos')
xlabel('Timestamp (total 1 second)')
ylabel('Arcmin')
title(sprintf('Rslam video %d in %s', Rslam_VideoNumber, strrep(rslam_output_file,'_','\_')));