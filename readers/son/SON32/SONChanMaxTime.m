function MaxTime=SONChanMaxTime(fh, chan)
% SONCHANMAXTIME returns the sample time for the last data item on a channel
% 
% MAXTIME=SONCHANMAXTIME(FH, CHAN) 
% where  FH is the SON file handle
%        CHAN the channel (0-SONMaxChannels()-1)
%
%        MAXTIME is returned in clock ticks
% 
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

MaxTime=calllib('son32','SONChanMaxTime',fh,chan);
return;
