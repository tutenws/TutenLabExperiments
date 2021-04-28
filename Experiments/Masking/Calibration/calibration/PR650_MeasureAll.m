function [results] = PR650_ReadMemFile (port,repeats)
% Send measure command to the PR650 Colorimeter on specified port.  

% Author: CBurns - Bankslab UC Berkeley
% Date: 03/30/2005
%
% Includes some code from Laurence Maloney & Katja Doerschner @ NYU
%
% minimum delay per repeat (sec)
delay=3;
% Dump data in RS-232 buffer. 
ClearBuffer(port);

% Send the measure command to the device.
% and get X, Y, Z
fprintf(port,'M2\n')
pause(3*repeats);
% Retrieve the data string from the device.
%[string, bytes, msg] = fgetl(port);
[data, bytes, msg] = fscanf(port,'%d,%d,%g,%g,%g');
 if (~strcmp(msg,'')) fprintf('fscanf Error message from PR650_Init %s \n',msg);
    end
if (bytes == 0)
    % Possible problem with serial port
   quality = -1;
else
    % Get the Measurement Quality Code from the string
   quality = data(1);
end

% BUG:  Need to account for this case where light level is low
% and data is still being acquired.  quality == 18

% Determine if there was an error.
if (quality ~= 0)
    fprintf('Error in PR650_MeasureCIE!\n');
    PR650_Quality(quality);
else
    % Haven't had this case yet, but we should probably check for it!
    if (bytes ~= 36)
        fprintf('Error! Wrong number of bytes in data string (%d)\n', bytes);
    end
end    
results.X=data(3); results.Y=data(4); results.Z=data(5);

% Dump data in RS-232 buffer. 
ClearBuffer(port);


%  LUM,x,y,u',v'
fprintf(port,'D6\n')
%pause(3*repeats);
% Retrieve the data string from the device.
%[string, bytes, msg] = fgetl(port);
[data, bytes, msg] = fscanf(port,'%d,%d,%g,%g,%g,%g,%g');
 if (~strcmp(msg,'')) fprintf('fscanf Error message from PR650_Init %s \n',msg);
    end
if (bytes == 0)
    % Possible problem with serial port
   quality = -1;
else
    % Get the Measurement Quality Code from the string
   quality = data(1);
end

% BUG:  Need to account for this case where light level is low
% and data is still being acquired.  quality == 18

% Determine if there was an error.
if (quality ~= 0)
    fprintf('Error in PR650_MeasureCIE!\n');
    PR650_Quality(quality);
else
    % Haven't had this case yet, but we should probably check for it!
    if (bytes ~= 40 && bytes ~= 41)
        fprintf('Error! Wrong number of bytes in data string (%d)\n', bytes);
    end
end
    
results.Lv=data(3); results.x=data(4); results.y=data(5);results.uPrime=data(6);results.vPrime=data(7);

%COLOR TEMPERATURE
% Dump data in RS-232 buffer. 
ClearBuffer(port);
% Send the measure command to the device.
fprintf(port,'D4\n')
%pause(3*repeats);
% Retrieve the data string from the device.
%[string, bytes, msg] = fgetl(port);
[data, bytes, msg] = fscanf(port,'%d,%d,%g,%g,%g');
 if (~strcmp(msg,'')) fprintf('fscanf Error message from PR650_Init %s \n',msg);
    end
if (bytes == 0)
    % Possible problem with serial port
   quality = -1;
else
    % Get the Measurement Quality Code from the string
   quality = data(1);
end

% BUG:  Need to account for this case where light level is low
% and data is still being acquired.  quality == 18

% Determine if there was an error.
if (quality ~= 0)
    fprintf('Error in PR650_MeasureCIE!\n');
    PR650_Quality(quality);
else
    % Haven't had this case yet, but we should probably check for it!
    if (bytes ~= 31)
        fprintf('Error! Wrong number of bytes in data string (%d)\n', bytes);
    end
end
results.T=data(4);
%  

%RADIOMETRIC SPECTRUM% Dump data in RS-232 buffer. 
% Dump data in RS-232 buffer.
ClearBuffer(port);
%get spectra lambda limits of PR650
fprintf(port,'D120\n');
[limits, bytes, msg] = fscanf(port,'%d,%f,%f,%f,%f');

% Dump data in RS-232 buffer.
ClearBuffer(port);
% Send the read spectra command to the device.
fprintf(port,'D5\n')
%pause(1);
% Retrieve the data string from the device.
[code5, bytes, msg] = fscanf(port,'%d,%d');
quality=code5(1);
if (quality ~= 0)
    fprintf('Error in PR650_MeasureSpectrum!\n');
    PR650_Quality(quality);
end
radunits=code5(2);
[intinten, bytes, msg] = fscanf(port,'%e');
index=1;
top=limits(1,1)+1;
while (index < top)
[data,bytes,msg]=fscanf(port,'%f, %e');
    if (~strcmp(msg,'')) fprintf('Error message from PR650_Init %s \n',msg);
    end
lambda(index)=data(1);
inten(index)=data(2);
index=index+1;
end;
results.wavelengths=lambda;
results.spectral_data=inten;
results.Le=intinten;
%  
