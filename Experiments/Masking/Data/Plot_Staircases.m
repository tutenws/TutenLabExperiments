% This script plots the staircases

%load ('20207_400TotalTrials_HomeVersion_05_05_20_1212');
load('02_400TotalTrials_HomeVersion_05_09_20_0649');

%Grey Condition
Gray_1 = data.TestLuminance(2:end,1);
Gray_1 = cell2mat(Gray_1);
Gray_2 = data.TestLuminance(2:end,2);
Gray_2 = cell2mat(Gray_2);
figure,
plot(Gray_1,'o-')
hold on
plot(Gray_2)
legend('Stair 1', 'Stair 2');
title('Gray - Staircase 1&2');
hold off


%Oscillation Freq 0Hz
Freq0Hz_1 = data.TestLuminance(2:end,3);
Freq0Hz_1 = cell2mat(Freq0Hz_1);
Freq0Hz_2 = data.TestLuminance(2:end,4);
Freq0Hz_2 = cell2mat(Freq0Hz_2);
figure,
plot(Freq0Hz_1,'-o')
hold on
plot(Freq0Hz_2)
legend('Stair 1', 'Stair 2');
title('Oscillation 0Hz - Staircase 1&2');
hold off

%Oscillation Freq 4Hz
Freq4Hz_1 = data.TestLuminance(2:end,5);
Freq4Hz_1 = cell2mat(Freq4Hz_1);
Freq4Hz_2 = data.TestLuminance(2:end,6);
Freq4Hz_2 = cell2mat(Freq4Hz_2);
figure,
plot(Freq4Hz_1,'-o')
hold on
plot(Freq4Hz_2)
legend('Stair 1', 'Stair 2');
title('Oscillation 4Hz - Staircase 1&2');
hold off

%Oscillation Frequency 10 Hz
Freq10Hz_1 = data.TestLuminance(2:end,7);
Freq10Hz_1 = cell2mat(Freq10Hz_1);
Freq10Hz_2 = data.TestLuminance(2:end,8);
Freq10Hz_2 = cell2mat(Freq10Hz_2);
figure,
plot(Freq10Hz_1,'-o')
hold on
plot(Freq10Hz_2)
legend('Stair 1', 'Stair 2');
title('Oscillation 10Hz - Staircase 1&2');
hold off

%Oscillation Frequency 15Hz
Freq15Hz_1 = data.TestLuminance(2:end,9);
Freq15Hz_1 = cell2mat(Freq15Hz_1);
Freq15Hz_2 = data.TestLuminance(2:end,10);
Freq15Hz_2 = cell2mat(Freq15Hz_2);
figure,
plot(Freq15Hz_1,'-o')
hold on
plot(Freq15Hz_2)
legend('Stair 1', 'Stair 2');
title('Oscillation 15Hz - Staircase 1&2');
hold off

