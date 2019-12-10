function handle=SONOpenNewFile(str, extrabytes)
% SONOPENNEWFILE (obsolete) creates a new SON file and returns the handle
% 
% HANDLE=SONOPENNEWFILE(STR, EXTRABYTES)
% where STR is the file name (with path). EXTRABYTES sets the size of the
% optional user data area
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

handle=calllib('son32','SONOpenNewFile', str, 0, extrabytes);