function flag=SONLatestTime(fh, chan, sTime)
% SONLATESTTIME is used to flush data to disk
% 
% FLAG=SONLATESTTIME(FH, CHAN, STIME)
% where FH is the SON file handle, Chan is the channel, and STIME is the
% latest valid time in clock ticks
% 
% See CED documentaion
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

flag=calllib('son32','SONLatestTime', fh, chan, sTime);

