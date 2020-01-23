% GetResp=1;
% while GetResp==1
%     GamePad = GamePadInput([]);
%     if GamePad.buttonLeftLowerTrigger
%        GetResp=0; 
%     else 
%         disp('Other Button Pressed');
%     end
%     
% end

clear all
GamePad = GamePadInput([]);
while GamePad.noChange ==1
    
A = 4; 
    
end

A = 0;
KbWait;

sca;