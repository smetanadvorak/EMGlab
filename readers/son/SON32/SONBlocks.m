function nblocks=SONBlocks(fh,chan)
% SONBLOCKS returns the number of blocks written to disk for the channel
% [NBLOCKS]=SONBLOCKS(FH,CHAN)
%                    FH  SON file handle
%                    CHAN is the channel number from 0 to SONMAXCHANS-1
% Returns 0 or the number of blocks;
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

if nargin ~= 2
    nblocks=-1000;
    return;
end;

nblocks=calllib('son32','SONBlocks',fh,chan);
return;
