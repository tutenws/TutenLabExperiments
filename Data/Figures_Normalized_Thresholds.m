% Figure with the 

clear all;

%%%%% Participant 20207
%load the data
load('20207_400TotalTrials_HomeVersion_05_05_20_1212.mat'); 

%calc diff in luminance between the test circle and the test spot
TestLum = data.TestLuminance(2:end,:); %remove the top row of labels
TestLum = cell2mat(TestLum); %convert cell array to normal variable array
TestLum_diff = TestLum - expParams.CircLum(1,1);%subtracts the circle luminance from all the last spot values
TestLum_Threshold = TestLum_diff(end,:); %last test luminance presented in the staircase

%Average of Last Luminance Value in Staircase  
if expParams.NumbOfStaircasesPerCond == 2
    SpotLum_Grey = mean(TestLum_Threshold(1,1:2));
    SpotLum_Grating0Hz = mean(TestLum_Threshold(1,3:4));
    SpotLum_Grating4Hz = mean(TestLum_Threshold(1,5:6));
    SpotLum_Grating10Hz = mean(TestLum_Threshold(1,7:8));
    SpotLum_Grating15Hz = mean(TestLum_Threshold(1,9:10));
end

%Calculate the Y Values (Normalized Threshold Values)
NormLum_Grating0Hz = log10(SpotLum_Grey./SpotLum_Grating0Hz);
NormLum_Grating4Hz = log10(SpotLum_Grey./SpotLum_Grating4Hz);
NormLum_Grating10Hz = log10(SpotLum_Grey./SpotLum_Grating10Hz);
NormLum_Grating15Hz = log10(SpotLum_Grey./SpotLum_Grating15Hz);
AllNormLum = [NormLum_Grating0Hz,NormLum_Grating4Hz,NormLum_Grating10Hz,NormLum_Grating15Hz];



%%%PARTICIPANT 01

load('01_400TotalTrials_HomeVersion_05_08_20_1020')

%Average of Last Luminance Value in Staircase 
TestLum_01 = cell2mat(data.TestLuminance(end,:));
TestLum_Threshold_01 = TestLum_01 - expParams.CircLum(1,1);%subtracts the circle luminance from the last spot values

if expParams.NumbOfStaircasesPerCond == 2
    SpotLum_Grey_01 = mean(TestLum_Threshold_01(1,1:2));
    SpotLum_Grating0Hz_01 = mean(TestLum_Threshold_01(1,3:4));
    SpotLum_Grating4Hz_01 = mean(TestLum_Threshold_01(1,5:6));
    SpotLum_Grating10Hz_01 = mean(TestLum_Threshold_01(1,7:8));
    SpotLum_Grating15Hz_01 = mean(TestLum_Threshold_01(1,9:10));
end

%Calculate the Y Values (Normalized Threshold Values)
NormLum_Grating0Hz_01 = log10(SpotLum_Grey_01./SpotLum_Grating0Hz_01);
NormLum_Grating4Hz_01 = log10(SpotLum_Grey_01./SpotLum_Grating4Hz_01);
NormLum_Grating10Hz_01 = log10(SpotLum_Grey_01./SpotLum_Grating10Hz_01);
NormLum_Grating15Hz_01 = log10(SpotLum_Grey_01./SpotLum_Grating15Hz_01);
AllNormLum_01 = [NormLum_Grating0Hz_01,NormLum_Grating4Hz_01,NormLum_Grating10Hz_01,NormLum_Grating15Hz_01];


%%%PARTICIPANT 01

load('02_400TotalTrials_HomeVersion_05_09_20_0649');

%Average of Last Luminance Value in Staircase 
TestLum_02 = cell2mat(data.TestLuminance(end,:));
TestLum_Threshold_02 = TestLum_02 - expParams.CircLum(1,1);%subtracts the circle luminance from the last spot values

if expParams.NumbOfStaircasesPerCond == 2
    SpotLum_Grey_02 = mean(TestLum_Threshold_02(1,1:2));
    SpotLum_Grating0Hz_02 = mean(TestLum_Threshold_02(1,3:4));
    SpotLum_Grating4Hz_02 = mean(TestLum_Threshold_02(1,5:6));
    SpotLum_Grating10Hz_02 = mean(TestLum_Threshold_02(1,7:8));
    SpotLum_Grating15Hz_02 = mean(TestLum_Threshold_02(1,9:10));
end

%Calculate the Y Values (Normalized Threshold Values)
NormLum_Grating0Hz_02 = log10(SpotLum_Grey_02./SpotLum_Grating0Hz_02);
NormLum_Grating4Hz_02 = log10(SpotLum_Grey_02./SpotLum_Grating4Hz_02);
NormLum_Grating10Hz_02 = log10(SpotLum_Grey_02./SpotLum_Grating10Hz_02);
NormLum_Grating15Hz_02 = log10(SpotLum_Grey_02./SpotLum_Grating15Hz_02);
AllNormLum_02 = [NormLum_Grating0Hz_02,NormLum_Grating4Hz_02,NormLum_Grating10Hz_02,NormLum_Grating15Hz_02];




%%%%%%%%%%%%%%%%%% Plot Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

%X values - Oscillation frequeency
Freq = [0,4,10,15];

%Plot Parameters
xmin = -0.5;
xmax = 15.5;
ymax = 0.4;
ymin = 0;
xtick = [0, 4, 10,15];

MarkerSize = 40;



figure,
scatter(Freq, AllNormLum, MarkerSize, 'o','MarkerFaceColor','b')
hold on
scatter(Freq, AllNormLum_01, MarkerSize, 'o','MarkerFaceColor','r')
hold on
scatter(Freq, AllNormLum_02, MarkerSize, 'o', 'MarkerFaceColor','g','MarkerEdgeColor','g')
xlim([xmin xmax]);
%ylim([ymin ymax]);
xticks(xtick);
ylabel('\bfLog(\DeltaLgray / \DeltaLgrating)');
xlabel('\bfOscillation Frequency (Hz)');
legend('20207','01','02');
set(gcf,'color','w'); %background white
hold off



