function blocks=SONDelBlocks(fh, chan)
% SONDELBLOCKS returns the number of deleted blocks in file FH on channel CHAN
%
% BLOCKS=SONDELBLOCKS(FH, CHAN)
% 
% 
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

if nargin<2
    blocks=-1000;
    return;
end;

blocks=calllib('son32','SONDelBlocks', fh, chan);

    