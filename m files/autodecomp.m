function autodecomp ()
% wrapper for default auto decomp algorithm

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net

    global CURR DECOMP SETS

    currcomp = CURR.compare;
    emgcompare ('compare', 0);
    autoident;
    [t0, t1] = whattime (SETS.firing);
    sig = emgsignal (t0, t1);
    resid = emgresidual (t0, t1);
    n_orig = DECOMP.nunits;
    thresh = getthreshold (resid);
    [slist, se90] = autodetect (sig, resid, thresh);
    slist = automerge (sig, slist, se90);

    if ~isempty (slist);
        sslist = [emgslist(0, t0, t1); slist(:,1), slist(:,2)+n_orig];

        sslist = automerge (sig, sslist, se90, n_orig);
        emgslist ('delete', t0, t1);
        if any(sslist(:,2)<=n_orig);
            ix = find(sslist(:,2)<=n_orig);
            emgslist ('concat', sslist(ix,:));
        end;
        if any(sslist(:,2)>n_orig);
            ix = find(sslist(:,2)>n_orig);
            slist = [sslist(ix,1), sslist(ix,2)-n_orig];
            emgunit ('create', slist);
            emgcompare ('compare', currcomp);
            emgsettings ('show all templates');
            emgplot ({'signal', 'templates', 'firing'});
            drawnow;
            emgcompare ('compare', 0);
            autoident;
            emgunit ('reaverage');
            emgsettings ('show all templates');
        end;

    end;
    emgcompare ('compare', currcomp);

