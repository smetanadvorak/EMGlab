function dTickLen=SONTimeBase(fh, dTb)
% SONTIMEBASE Get or set the base time units for the file
% (usually 1e-6seconds)
% DTICKLEN=SONTIMEBASE(FH, DTB)
%                              FH  SON file handle
%                              DTB If <= 0 ignored
%                                     >0 the new value to set
%                                     
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

if nargin ~=2
    dTickLen=-1000;
    return;
end;

dTickLen=calllib('son32','SONTimeBase',fh,dTb);
return;
