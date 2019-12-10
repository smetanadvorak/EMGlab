function [bytes]=SONChanBytes(fh, chan)
% SONCHANBYTES returns the number of bytes written, or buffered, on the 
% specified channel
% BYTES=SONCHANBYTES(FH, CHAN)
%                     FH SON file handle
%                     CHAN Channel number 0 to SONMAXCHANS-1
% 
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

if nargin ~= 2
    bytes=-1000;
    return;
end;


bytes=calllib('son32','SONChanBytes',fh,chan);
return;