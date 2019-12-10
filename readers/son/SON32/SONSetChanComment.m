function SONSetChanComment(fh, chan, str)
% SONSETCHANCOMMENT sets the channel comment
% FH = SON file handle
% CHAN = channel number (0 to Max-1)
% str = string with new comment
% 
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

global SON_CHANCOMSZ;
str=str(1:min(SON_CHANCOMSZ,length(str)));
calllib('son32','SONSetChanComment', fh, chan, str);
