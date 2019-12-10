function ret=SONSetBuffering(fh, chan, bytes)
%SONSETBUFFERING specifies the buffer size for writing to a channel
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

ret=calllib('son32','SONSetBuffering', fh, chan, bytes);