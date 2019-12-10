function bytes=SONFileBytes(fh)
% SONFILEBYTES Returns the number of bytes in the file 
%    BYTES=SONFILEBYTES(FH) where FH is the file handle
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006
             

bytes=calllib('son32','SONFileBytes',fh);
return;