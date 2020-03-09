function [port, status] = PR650_Init (units,repeats, USBcomPORT);
% Initialize the serial port to communicate with the PR650 Colorimeter
% Configure settings, open the port and return a port id.

% Author: CBurns - Bankslab UC Berkeley
% Date: 03/30/2005
%
% Includes some code from Laurence Maloney & Katja Doerschner @ NYU
%

% Cleanup any open serial ports
portobjs = instrfind;
delete(portobjs);
clear portobjs;
pause(0.1);

% init status... assume failure
status = 0;

%port = serial('COM4');
%port = serial('COM3');
port = serial( USBcomPORT);
set(port, 'BaudRate', 9600);
set(port, 'DataBits', 8);
set(port, 'Parity', 'none');
set(port, 'StopBits', 1);
set(port, 'Timeout', 2);
set(port, 'Terminator', 'CR/LF');
set(port, 'FlowControl', 'none');
% Increase the timeout interval on the serial port.  Hopefully this will
% help us maintain a connection to the colorimeter.
timeout = get(port,'Timeout');
if (timeout ~= 90)
    fprintf('Set port timeout to 90!\n');
    set(port,'Timeout',90);
end
set (port, 'InputBufferSize',2048);
% need at least 17 x 101 plus a few bytes for spectra reads

fopen(port); %seems to send a low to hi to low pulse

set(port, 'RequestToSend', 'off'); %needed to make RTS 'on work'
pause (0.5)

set(port, 'RequestToSend', 'on');
%pause(0.5);


%fopen(port);



% Send a quick command to keep it in command mode.
% Initialize/Setup measurement parameters.
% Params:   S1  - Default accessory
%           ,   - default, no 2nd accessory,
%           ,   - default, no 3rd accessory,
%           ,   - default, no 4th accessory,
%           ,   - default, no nom sync freq
%           0   - default, let PR650 determine optimal integration time
%           1   - default, number of measurements to average
%           0   - default, CIE Y unit type - English, footLamberts or
%                   footcandles

% at this juncture the S command doesn't utilize the arguments
% it is just used to establish communications
% issue another S1 later to select parameters
% note that this first S command appears NOT
% to be the "command required witin 5 seconds"
fprintf(port,'S1,,,,,0,1,0,\n');

% Wait one second before trying further communication!
% This seems critical... without this delay, establishing the Remote Mode
% communication is very difficult!
pause(.1);   % 0.1 seems enough
ClearBuffer(port); 

% Check Battery Status
% This also verifies if Remote Mode is working.
fprintf(port, 'D115\n');
pause(.1); % Need to give time for the colorimeter to respond!
%bytes = get(port,'BytesAvailable');
%if (bytes ~= 0)
[data, bytes, msg] = fscanf(port,'%d,%d');
if (~strcmp(msg,'')) fprintf('fprintf Error message %s \n',msg);end;
if (bytes ~= 0)    
    battery = data(1,1);
    if (battery == 0)
        fprintf('PR650 Battery Check - OK.\n');
    elseif (battery == 1)
        fprintf('PR650 Battery Check - Low Battery!\n');
    else
        fprintf('PR650 Battery Check - Undefined Status!\n');
    end
    % Successful communication!
    status = 1;
else
    fprintf('PR650 Battery Check - Remote Command Failed!\n');
end
string=sprintf('S1,,,,,0,%d,%d\n',[repeats units]);
fprintf(port,string);

bytes = get(port,'BytesAvailable');
[string, bytes, msg] = fscanf(port,'%d');
if (~strcmp(msg,'')) fprintf('fprintf Error message %s \n',msg);end;
if (string) fprintf ('PR650 S command error %d',string); end;

end
