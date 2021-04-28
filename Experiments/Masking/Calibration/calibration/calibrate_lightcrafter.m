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
pr_port = 'COM3';
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
        sprintf('%g%% done', m/cal.num_total_meas*100));
end

%save measurements & variables
cal = orderfields(cal);
save(filename,'cal');

close(hbar);

%% Measure white
fprintf('\nMeasuring white...');
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

%% Calculate correction
fprintf('\nMeasurements complete. Calculating corrections...\n');

v = cal.int_list ./ 255;
xq = linspace(0,1,256);

for led = 1:cal.num_leds
    x = cal.raw_lum_output(:,led) ./ max(cal.raw_lum_output(:,led));
    cal.lookup_table(:,led) = interp1(x,v,xq);
end

cal = orderfields(cal);
save(filename,'-append','cal');

%% Post-processing
% Interpolate measured lums
x = cal.int_list ./ 255;
xq = linspace(0,1,256);

for led = 1:cal.num_leds
    v = cal.raw_lum_output(:,led) ./ max(cal.raw_lum_output(:,led));
    cal.norm_lum_output(:,led) = interp1(x,v,xq);
end

% A 3x3 matrix of the CIE 1931 XYZ values of the max LED outputs allows
% transformation between RGB & XYZ coordinates
for led = 1:cal.num_leds
    cal.RGB_to_XYZ(led,:) = cal.all_xyz(end,:,led);
end

%inverse matrix goes from XYZ to RGB
cal.XYZ_to_RGB = inv(cal.RGB_to_XYZ);

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

%convert white point from XYZ to xyL
X = cal.white_xyz(1);
Y = cal.white_xyz(2);
Z = cal.white_xyz(3);
x = X / (X + Y + Z);
y = Y / (X + Y + Z);
cal.white_xyl = [x,y,Y];

cal.calibration_date = datestr(now,'local');
cal.refresh_rate = Screen('FrameRate',w);
cal.max_luminance = cal.raw_lum_output(end,:);

%% Close PR650 and save cal file
cal.time_to_measure = (GetSecs - start_time) / 60;
fprintf('Total measurement time: %d minutes.\n\n',cal.time_to_measure);

cal = orderfields(cal);
save(filename,'-append','cal');

PR650close;
Screen('CloseAll');

%% Plot data
make_display_character_plots(cal);

beep; beep; beep;

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp('%%%%%%%   All done!   %%%%%%%');
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function make_display_character_plots(cal)

f = 1; %figure number
lw = 2; %line width

lambda = cal.wavelength_sampling;

%% Plot LED spectra
h = axes('Parent',figure(f),'FontSize',12);
hold(h,'all');
f = f + 1;

plot(lambda,cal.rgb_spectra(end,:,1),'r','LineWidth',lw);
plot(lambda,cal.rgb_spectra(end,:,2),'g','LineWidth',lw);
plot(lambda,cal.rgb_spectra(end,:,3),'b','LineWidth',lw);

h = zeros(3,1);
h(1) = plot(NaN,NaN,'r','LineWidth',lw);
h(2) = plot(NaN,NaN,'g','LineWidth',lw);
h(3) = plot(NaN,NaN,'b','LineWidth',lw);
legend(h, 'Red LED','Green LED','Blue LED','Location','northwest');

xlabel('Wavelength (nm)');
ylabel('Watts/sr/m^2');
title('LED SPDs (with ND filter)');

saveas(f-1,'lightcrafter_spd.fig');
print('lightcrafter_spd','-dpng','-r600');

%% Plot input-output functions
h = axes('Parent',figure(f),'FontSize',12);
hold(h,'all');
f = f + 1;

plot(cal.int_list,cal.raw_lum_output(:,1),'r','LineWidth',lw);
plot(cal.int_list,cal.raw_lum_output(:,2),'g','LineWidth',lw);
plot(cal.int_list,cal.raw_lum_output(:,3),'b','LineWidth',lw);

h = zeros(3,1);
h(1) = plot(NaN,NaN,'r','LineWidth',lw);
h(2) = plot(NaN,NaN,'g','LineWidth',lw);
h(3) = plot(NaN,NaN,'b','LineWidth',lw);
legend(h, 'Red LED','Green LED','Blue LED','Location','northwest');

xlabel('8 bit intensity');
ylabel('Luminance (cd/m^2)');
title('Measured input-output functions (with ND filter in place)');

saveas(f-1,'lightcrafter_lums.fig');
print('lightcrafter_lums','-dpng','-r600');

%% Plot normalized input-output functions
h = axes('Parent',figure(f),'FontSize',12);
hold(h,'all');
f = f + 1;

x = linspace(0,1,256);

plot(x,cal.norm_lum_output(:,1),'r','LineWidth',lw);
plot(x,cal.norm_lum_output(:,2),'g','LineWidth',lw);
plot(x,cal.norm_lum_output(:,3),'b','LineWidth',lw);

plot(x,cal.lookup_table(:,1),'r-.','LineWidth',lw);
plot(x,cal.lookup_table(:,2),'g-.','LineWidth',lw);
plot(x,cal.lookup_table(:,3),'b-.','LineWidth',lw);

h = zeros(6,1);
h(1) = plot(NaN,NaN,'r','LineWidth',lw);
h(2) = plot(NaN,NaN,'g','LineWidth',lw);
h(3) = plot(NaN,NaN,'b','LineWidth',lw);
h(4) = plot(NaN,NaN,'r-.','LineWidth',lw);
h(5) = plot(NaN,NaN,'g-.','LineWidth',lw);
h(6) = plot(NaN,NaN,'b-.','LineWidth',lw);
legend(h, 'Red LED','Green LED','Blue LED',...
    'Inverse Red','Inverse Green','Inverse Blue','Location','northwest');

xlabel('Normalized intensity');
ylabel('Normalized luminance');
title('Normalized input-output functions');

saveas(f-1,'lightcrafter_norm_lums.fig');
print('lightcrafter_norm_lums','-dpng','-r600');

%% Plot white SPD
h = axes('Parent',figure(f),'FontSize',12);
hold(h,'all');
f = f + 1;

plot(lambda,cal.white_spd,'k','LineWidth',lw);
plot(lambda,cal.rgb_spectra(end,:,1),'r--','LineWidth',lw);
plot(lambda,cal.rgb_spectra(end,:,2),'g--','LineWidth',lw);
plot(lambda,cal.rgb_spectra(end,:,3),'b--','LineWidth',lw);

h = zeros(4,1);
h(1) = plot(NaN,NaN,'k-','LineWidth',lw);
h(2) = plot(NaN,NaN,'r--','LineWidth',lw);
h(3) = plot(NaN,NaN,'g--','LineWidth',lw);
h(4) = plot(NaN,NaN,'b--','LineWidth',lw);
legend(h, 'Max white','Red LED','Green LED','Blue LED','Location','northwest');

xlabel('Wavelength (nm)');
ylabel('Watts/sr/m^2');
title('White SPD (with ND filter in place)');

saveas(f-1,'lightcrafter_white.fig');
print('lightcrafter_white','-dpng','-r600');

%% Plot CIE 1931 coordinates of stimuli
try
    load colorimetric_data; %#ok<*LOAD>
catch ME
    warning(['Failed to load file "colorimetric_data". This file '...
        'is used for plotting only. Calibration completed '...
        'successfully, but CIE plot won''t be made.']);
    rethrow(ME);
end

cie_locus = chrom_coord.cie_1931.locus;

h = axes('Parent',figure(f),'FontSize',12);
hold(h,'all');

plot(cie_locus(:,1),cie_locus(:,2),'k','LineWidth',2);
plot(cal.all_xyl(end,1,1),cal.all_xyl(end,2,1),'ro','MarkerFaceColor','r');
plot(cal.all_xyl(end,1,2),cal.all_xyl(end,2,2),'go','MarkerFaceColor','g');
plot(cal.all_xyl(end,1,3),cal.all_xyl(end,2,3),'bo','MarkerFaceColor','b');
plot(cal.white_xyl(1),cal.white_xyl(2),'ko','MarkerFaceColor','k');

xlabel('x');
ylabel('y');
title('Max LED CIE 1931 chromaticity coordinates');

h = zeros(5,1);
h(1) = plot(NaN,NaN,'ro');
h(2) = plot(NaN,NaN,'go');
h(3) = plot(NaN,NaN,'bo');
h(4) = plot(NaN,NaN,'ko');
h(5) = plot(NaN,NaN,'k-');
legend(h,'Red max','Green max','Blue max','White max',...
    'CIE 1931 Spectrum Locus');

saveas(f-1,'lightcrafter_cie.fig');
print('lightcrafter_cie','-dpng','-r600');

end
