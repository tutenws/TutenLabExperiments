function [] = ClearBuffer(port)
% Clear data in RS-232 buffer. 
bytes = get(port,'BytesAvailable');
while (bytes ~= 0)
   fread(port,bytes);
   pause(0.1);
   bytes = get(port,'BytesAvailable');
end
