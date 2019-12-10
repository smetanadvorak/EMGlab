function [Ann, Vars] = load_ann (filename)
% Custom reader for .ann annotatons files.

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net

    sl = load (filename, '-ascii');
    status = 1;
    if size(sl,2)~=2;
        status = 0;
    elseif any(round(sl(:,2))~=sl(:,2));
        status = 0;
    elseif any(sl(:,1) <0);
        status = 0;
    end;
    if ~status 
        error ('Not a valid annotation file.')
    end;
    Ann.time = sl(:,1);
    Ann.unit = sl(:,2);
    Vars = [];