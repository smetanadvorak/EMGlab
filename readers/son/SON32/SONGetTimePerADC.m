function ticks=SONGetTimePerADC(fh)
% SONGETTIMEPERADC returns the number of clock ticks per ADC conversion
%     TICKS=SONGETTIMEPERADC(FH)
%             FH = file handle
% Returns the number of ticks (no error codes)
% 
% See also SONGETUSPERTIME, SONCHANDIVIDE
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

if nargin ~= 1
    ticks=-1000;
    return;
end;

ticks=calllib('son32','SONGetTimePerADC',fh);
return;