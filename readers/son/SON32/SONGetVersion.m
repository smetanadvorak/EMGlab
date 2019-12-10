function version=SONGetVersion(fh)
% SONGETVERSION returns the SON file system version number for a file
%
% VERSION=SONGETVERSION(FH)
% where fh is the SON File handle
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

version=calllib('son32', 'SONGetVersion', fh);