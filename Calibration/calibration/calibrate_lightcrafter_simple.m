%%%%% Display Device Calibration %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script was written to characterize the output of a Lightcrafter 4500
% projector using a PR-650 spectroradiometer. Measure the outputs of the
% three LEDs at x number of intensity levels, as well as the R,G,B, & W
% spectra and chromaticity coordinates. Modification for other measurement
% & display devices should be pretty straightforward.
%  06/24/19 JEV - Wrote it.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Screen('Preference', 'SkipSyncTests', 1);
clear; close all;

rng('shuffle'); %seed RNG

% which port has been assigned to the PR650?
pr_port = 'COM4';
meter_type = 1; %PR-650

%% Input monitor & computer names
commandwindow;

cal.monitorID = input(['Please enter the name of the display you''re '...
    'calibrating: '],'s');
cal.computerID = input(['Please enter the name of the computer you''re '...
    'using to calibrate: '],'s');
filename = input(['Please enter a sensible name for your '...
    'calibration file: '],'s');

%% Measurement parameters
cal.num_int_levels_measured = 16; %number of gun intensity levels to measure. Should be
%an integer factor of 256, since each Lightcrafter LED has 8 bits of color
%resolution
cal.num_leds = 3; %number of LEDs
cal.meas_delay = 3; %delay between when the intensity level changes and when a
%measurement is taken, in seconds. It can take a few seconds for a new RGB
%value to "settle".
cal.screen_scalar = 1; %percent of the total screen area to be filled with 
%the colored patch. The value of 75% is taken from the Bits# documentation
cal.num_total_meas = cal.num_int_levels_measured * cal.num_leds; %total number of measurements 
%to be taken

%The PR-650 has a minimum light level that it needs to take an accurate
%measurement, and if light levels are too low, it throws an error. Matlab
%treats this as a proper error, which can crash your script. We're going to
% sidestep the whole issue by assuming that with zero voltage input to the 
%display device, it would produce an output of zero candelas.
cal.num_int_levels = cal.num_int_levels_measured + 1;

%% Connect to PR-650
units = 1;
repeats = 1;
[port, status] = PR650_Init(units, repeats, pr_port);
disp(status);

cal.wavelength_sampling = 380:4:780; %default spectral wampling for PR-650
cal.num_wl = length(cal.wavelength_sampling);

%% Create random sequence of LEDs & intensities
cal.int_step = 256 / cal.num_int_levels_measured;
cal.int_list = (cal.int_step:cal.int_step:256)-1;
int_rep = repmat(cal.int_list,[1,cal.num_leds]);
rand_list = randperm(cal.num_total_meas);
cal.int_sequence = int_rep(rand_list); %final sequence

led_list = 1:cal.num_leds;
led_rep = repmat(led_list,[1,cal.num_int_levels_measured]);
cal.led_sequence = led_rep(rand_list);

%% Declare variables
cal.raw_lum_output = zeros(cal.num_int_levels,cal.num_leds); %leave an open space for
%the "zero" intensity
cal.rgb_spectra = zeros(cal.num_int_levels,cal.num_wl,cal.num_leds); %for saving SPDs
cal.all_xyz = zeros(cal.num_int_levels,3,cal.num_leds); %for saving XYZ values
cal.all_xyl = zeros(cal.num_int_levels,3,cal.num_leds); %for saving xyL values

%% Open a window
AssertOpenGL;

screen = max(Screen('Screens'));
[w, rect] = Screen('OpenWindow',screen,[128 128 128]); %open a gray screen

LoadIdentityClut(w); %load in a linear LUT

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

fprintf([...
    '\nPlease position the telescope so that it''s focused on the '...
    '\npatch in the middle of the screen. Press any key when you''re '...
    '\nready to begin measurements...\n']);
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
hbar = waitbar(0, 'Beginning measurement...'); %create progress bar
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
    spd = data.spectral_data;

    % save luminance, XYZ, and SPD to matrices, remembering to push every
    % assignment up by one to leave room for "zero intensity"
    cal.raw_lum_output(i+1,which_led) = xyz(2); %grab luminance from XYZ
    cal.all_xyz(i+1,:,which_led) = xyz; 
    cal.rgb_spectra(i+1,:,which_led) = spd; 
    
    %update progress bar
    waitbar(m/cal.num_total_meas, hbar, ...
        sprintf('%1.1g%% done', m/cal.num_total_meas*100));
end

%save measurements & variables
cal = orderfields(cal);
save(filename,'cal');

%% Measure white
Screen('FillRect',w,[255 255 255],[x1,y1,x2,y2]);
Screen('Flip',w);

data = PR650_MeasureAll(port, repeats);
cal.white_xyz = [data.X,data.Y,data.Z];
cal.white_spd = data.spectral_data;

%% Save measurements & variables
cal.int_list(2:end+1) = cal.int_list(1:end);
cal.int_list(1) = 0;

cal = orderfields(cal);
save(filename,'-append','cal');

%% Close PR650 and save cal file
cal.time_to_measure = (GetSecs - start_time) / 60;
fprintf('Total measurement time: %d minutes.\n\n',cal.time_to_measure);

cal = orderfields(cal);
save(filename,'-append','cal');

PR650close;
Screen('CloseAll');

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp('%%%%%%%   All done!   %%%%%%%');
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');