function bytes=SONFileSize(fh)
% SONFILESIZE Returns the expected size of a file
%    BYTES=SONFILESIZE(FH) where FH is the file handle
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006
             

bytes=calllib('son32','SONFileSize',fh);
return;