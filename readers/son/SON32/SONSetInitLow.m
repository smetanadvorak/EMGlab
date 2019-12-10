function SONSetInitLow(fh, chan, flag)
% SONSETINITLOW sets the initial state on an EventBoth (level) channel
% 
% SONSETINITLOW(FH, CHAN, FLAG)
% where FH is the SON file handle and CHAN is the channel number.
% FLAG is 'TRUE' if the first transition is high-to-low, 'FALSE' otherwise.
% No return value
% 
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

switch (flag(1)) 
    case {'T','t'}
        state=1;
    case {'F','f'}
        state=0;
end;

calllib('son32','SONSetInitLow', fh, chan, state);