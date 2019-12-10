function [units, points, preTrig]=SONGetExtMarkInfo(fh, chan)
% SONGETEXTMARKINFO returns details about an extended marker channel
% 
% [UNITS, POINTS, PRETRIG]=SONGETEXTMARKINFO(FH, CHAN)
%
% INPUTS: FH the SON file handle 
%         CHAN channel number (0 - SONMaxChans()-1)
%         
% OUTPUTS:   UNITS a string with the channel units
%            POINTS the number of items of extra data
%            PRETRIG the number of pre-trigger items
%
% Returns no error codes
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

global SON_UNITSZ;

units=char(zeros(1,SON_UNITSZ+1));
points=uint16(0);
preTrig=int16(0);

ppoints=libpointer('uint16Ptr',points);
ppreTrig=libpointer('int16Ptr',preTrig);

[units, points, preTrig]=...
    calllib('son32','SONGetExtMarkInfo', fh, chan, units, ppoints, ppreTrig);
