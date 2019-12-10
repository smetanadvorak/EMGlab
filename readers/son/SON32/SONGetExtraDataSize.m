function bytes=SONGetExtraDataSize(fh)
% SONGETEXTRADATASIZE returns the size of the extra data area of file FH in bytes
% 
% BYTES=SONGETEXTRADATASIZE(FH)
% 
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

bytes=calllib('son32', 'SONGetExtraDataSize', fh);