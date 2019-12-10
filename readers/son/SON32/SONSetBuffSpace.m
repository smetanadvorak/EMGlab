function ret=SONSetBuffSpace(fh)
% SONSETBUFFSPACE allocates buufer space for file writes
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

ret=calllib('son32','SONSetBuffSpace',fh);
