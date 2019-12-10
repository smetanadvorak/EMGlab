function ret=SONUpdateStart(fh)
% SONUPDATESTART flushes the SON file header to disc
% 
% RET=SONUPDATESTART(FH)
% where FH is the SON file handle
%
% Returns zero or a negative error
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

ret=calllib('son32', 'SONUpdateStart', fh);