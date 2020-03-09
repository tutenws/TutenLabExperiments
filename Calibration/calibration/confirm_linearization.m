%%%%% Confirm Linearization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script was written to confirm that the calibration of the
% Lightcrafter 4500 was successful. The 'calibrate_lightcrafter' script
% outputs a lookup table (stored in cal.lookup_table) which should
% linearize the outputs of the LEDs. This script applies that lookup table
% and then re-measures the display outputs to test this. Best practice is
% to run this script after running 'calibrate_lightcrafter'.
%  07/01/19 JEV - Wrote it.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Screen('Preference', 'SkipSyncTests', 1);
clear; close all;

rng('shuffle'); %seed RNG

% which port has been assigned to the PR650?
pr_port = 'COM3';
meter_type = 1; %PR-650

%% Input monitor & computer names
commandwindow;

fileID = input('Please enter a suffix for this file: ','s');
filename = strcat('linear_test_',fileID);

fprintf('\nPlease select a calibration file to test.\n');
file = uigetfile('*.mat');
load(file);

%check for needed struct & field
if ~exist('cal','var')
    error('Struct "cal" not found. Select another file.');
else
    if isfield(cal,'lookup_table') ~= 1
        error('Field "cal.lookup_table" not found. Select another file.');
    end
end

%% Measurement parameters
cal.num_int_levels = 16; %number of gun intensity levels to measure. Should be
%an integer factor of 256, since each Lightcrafter LED has 8 bits of color
%resolution
cal.num_leds = 3; %number of LEDs
cal.meas_delay = 3; %delay between when the intensity level changes and when a
%measurement is taken, in seconds. It can take a few seconds for a new RGB
%value to "settle".
cal.screen_scalar = 1; %percent of the total screen area to be filled with 
%the colored patch. The value of 75% is taken from the Bits# documentation
cal.num_total_meas = cal.num_int_levels * cal.num_leds; %total number of measurements 
%to be taken

%% Connect to PR-650
units = 1;
repeats = 1;
[port, status] = PR650_Init(units, repeats, pr_port);
disp(status);

cal.wavelength_sampling = 380:4:780; %default spectral wampling for PR-650
cal.num_wl = length(cal.wavelength_sampling);

%% Create random sequence of LEDs & intensities
cal.int_step = 256 / cal.num_int_levels;
cal.int_list = (cal.int_step:cal.int_step:256)-1;
int_rep = repmat(cal.int_list,[1,cal.num_leds]);
rand_list = randperm(cal.num_total_meas);
cal.int_sequence = int_rep(rand_list); %final sequence

led_list = 1:cal.num_leds;
led_rep = repmat(led_list,[1,cal.num_int_levels]);
cal.led_sequence = led_rep(rand_list);

%% Declare variables
cal.raw_lum_output = NaN(cal.num_int_levels+1,cal.num_leds); %leave an open space for
%the "zero" intensity
cal.rgb_spectra = NaN(cal.num_int_levels,cal.num_wl,cal.num_leds); %for saving SPDs
cal.all_xyz = NaN(cal.num_int_levels,3,cal.num_leds); %for saving XYZ values
cal.all_xyl = NaN(cal.num_int_levels,3,cal.num_leds); %for saving xyL values

%% Open a window
AssertOpenGL;

screen = max(Screen('Screens'));
[w, rect] = Screen('OpenWindow',screen,[128 128 128]); %open a gray screen

LoadIdentityClut(w); %load in a linear LUT
Screen('LoadNormalizedGammaTable',w,cal.lookup_table); %load the clut to test

[screen_width, screen_height] = Screen('WindowSize',w); %query screen size
cal.screen_width = screen_width;
cal.screen_height = screen_height;

smx = screen_width / 2; %screen middle x
smy = screen_height / 2; %screen middle y
rect_size = 10; %size of alignment rectangle in pixels

% put up a small rectangle to help align PR650
Screen('FillRect',w,[55 55 55],...
    [smx-rect_size,smy-rect_size,smx+rect_size,smy+rect_size]);
Screen('Flip',w);

fprintf(['\nPlease position the telescope so that it''s focused on the '...
'patch in the middle of the screen. Press any key when you''re ready to'...
' begin measurements...\n']);
WaitSecs(1);

%% Calculate patch size
width_bound = screen_width * cal.screen_scalar; %x boundary of patch
height_bound = screen_height * cal.screen_scalar; %y boundary of patch
x1 = screen_width - width_bound;
y1 = screen_height - height_bound;
x2 = width_bound;
y2 = height_bound;

%% Begin measurement
KbWait;
start_time = GetSecs;

for m = 1:cal.num_total_meas
    intensity = cal.int_sequence(m);
    which_led = cal.led_sequence(m);
    
    fprintf('\nPreparing to measure LED %d, intensity %d...\n',...
        which_led,intensity);
    
    i = find(cal.int_list == intensity); %grab intensity index

    %there may be a smarter way to do this, but this way ought to work
    switch which_led
        case 1
            color = [intensity 0 0];
        case 2
            color = [0 intensity 0];
        case 3
            color = [0 0 intensity];
    end
    
    % display the proper patch chromaticity
    Screen('FillRect',w,color,[x1,y1,x2,y2]);
    Screen('Flip',w);
    WaitSecs(cal.meas_delay);
    
    data = PR650_MeasureAll(port, repeats);
    xyz = [data.X,data.Y,data.Z];

    cal.raw_lum_output(i,which_led) = xyz(2); %grab luminance from XYZ
    cal.all_xyz(i,:,which_led) = xyz;
    
end

%save measurements & variables
cal = orderfields(cal);
save(filename,'cal');

%% Post-processing

%convert CIE 1931 tristimulus values to chromaticity coordinates
for led = 1:cal.num_leds
    for int = 1:cal.num_int_levels
        X = cal.all_xyz(int,1,led);
        Y = cal.all_xyz(int,2,led);
        Z = cal.all_xyz(int,3,led);
        x = X / (X + Y + Z);
        y = Y / (X + Y + Z);
        cal.all_xyl(int,:,led) = [x,y,Y];
    end
end

cal.calibration_date = datestr(now,'local');
cal.refresh_rate = Screen('FrameRate',w);
cal.max_luminance = cal.raw_lum_output(end,:);

%% Plot normalized input-output functions
axes1 = axes('Parent',figure(1),'FontSize',12);
hold(axes1,'all');

lw = 2; %linewidth

norm_r = cal.raw_lum_output(:,1) ./ max(cal.raw_lum_output(:,1));
norm_g = cal.raw_lum_output(:,2) ./ max(cal.raw_lum_output(:,2));
norm_b = cal.raw_lum_output(:,3) ./ max(cal.raw_lum_output(:,3));

plot(cal.int_list,norm_r,'r','LineWidth',...
    lw,'DisplayName','Red LED');
plot(cal.int_list,norm_g,'g','LineWidth',...
    lw,'DisplayName','Green LED');
plot(cal.int_list,norm_b,'b','LineWidth',...
    lw,'DisplayName','Blue LED');

xlabel('8 bit intensity');
ylabel('Normalized luminance');
title('Normalized input-output functions');
legend1 = legend(axes1,'show');
set(legend1,'Location','northwest');

saveas(1,'linear_test_norm_lums.fig');
print('linear_test_norm_lums','-dpng','-r600');
close(1);

%% Close
cal.time_to_measure = (GetSecs - start_time) / 60;
fprintf('Total measurement time: %d minutes.\n\n',cal.time_to_measure);

cal = orderfields(cal);
save(filename,'-append','cal');

PR650close;
LoadIdentityClut(w); %load in a linear LUT
Screen('CloseAll');

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp('%%%%%%%   All done!   %%%%%%%');
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
