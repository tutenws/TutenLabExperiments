function [gamePad, time] = GamePadInput(timeOutSecs)
% this function listens for and stores button presses from Logitech F310 game controller;
% it requires Psychtoolbox
%W. Tuten, 8/12/2016

if nargin == 1
    timeOutSecs = [];
end
% Establish connection with the controller
gamePad = GamePad();
readGamePad = 1;
tic;
while readGamePad == 1
    [action, time] = gamePad.read(); %this runs continuously until the while loop is left
    switch (action)
        case gamePad.buttonChange   % a button was pressed
            readGamePad = 0;
            
        case gamePad.directionalButtonChange  % see which direction was selected
            readGamePad = 0;
    end
    
    if ~isempty(timeOutSecs)
        if toc > timeOutSecs
            readGamePad = 0;
        end
    end
end
gamePad.shutDown