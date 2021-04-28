function [zeroflag] = PR650_Quality( quality )
% Interpret the Measurement Quality Code.
% If an error occured, print out error message.

% Author: CBurns - Bankslab UC Berkeley
% Date: 03/30/2005
%
% Code primarily from Laurence Maloney & Katja Doerschner @ NYU
% with a few edits.
%

zeroflag = 0;

if (quality ~= 0)
   switch quality
   case -1, msg = 'Device is not responding';
   case  1, msg = 'No EOS signal at start of measurement';
   case  3, msg = 'No start signal';
   case  4, msg = 'No EOS signal to start integration time';
   case  5, msg = 'DMA failure';
   case  6, msg = 'No EOS after changed to SYNC mode';
   case  7, msg = 'Unable to sync to light source';
   case  8, msg = 'Sync lost during measurement';
   case 10, msg = 'Weak light signal (data zeroed)';
   case 12, msg = 'Unspecified hardware malfunction';
   case 13, msg = 'Software error';
   case 14, msg = 'No sample in L*u*v* or L*a*b* calculation';
   case 16, msg = 'Adaptive integration failing.  Possible variable light source';
   case 17, msg = 'Main battery is low';
   case 18, msg = 'Low light level (data still acquired)';
   case 19, msg = 'Light level too high (overload)';
   case 20, msg = 'No sync signal';
   case 21, msg = 'RAM error';
   case 29, msg = 'Corrupted data';
   case 30, msg = 'Noisy signal';
   otherwise, msg = ['Unknown error number (error = ' num2str(quality) ')'];
   end
   if (quality == 18 | quality == 10)
      if (quality == 10)
         zeroflag = 1;
      end
      msg=strcat ('Warning: ',msg);
      disp (msg);
      %warning(msg); % Data is still acquired for this error.
   else
      error(msg);
   end
end