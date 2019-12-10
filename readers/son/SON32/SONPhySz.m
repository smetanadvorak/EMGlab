function buffsize=SONPhySz(fh, chan)
% SONPHYSZ returns the buffer size for the specified chanel
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

buffsize=calllib('son32','SONPhySz', fh, chan);
