function Ann = load_decomp (filename)
% Custom reader for .decomp annotation files.

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net

    d = load (filename, '-mat');
    sl = [];
    for ic = 1:size(d.CHAN);
        s = d.CHAN(ic).slist;
        sl = [sl; s, s(:,1)*0+ic];
    end;
    Ann = struct ('time', sl(:,1), 'unit', sl(:,2), 'chan', sl(:,3));