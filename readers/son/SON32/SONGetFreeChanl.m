function chan=SONGetFreeChan(fh)
% SONGETFREECHAN returns the number of the first free channel in a file
% 
% CHAN=SONGETFREECHAN(FH)
% where FH is the SON file handle
% 
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

chan=calllib('son32', 'SONGetFreeChan', fh);
