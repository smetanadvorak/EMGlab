function interleave=SONChanInterleave(fh, chan)
% SONCHANINTERLEAVE Returns the channel interleave factor for ADCMark channels
% in SON V6 or above
% INTERLEAVE=SONCHANINTERLEAVE(FH, CHAN)
%                         FH SON File Handle
%                         Chan Channel number
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006


interleave=calllib('son32','SONChanInterleave',fh, chan);
return;
