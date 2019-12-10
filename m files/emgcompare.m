function emgcompare (opt, p1, p2)
% EMGlab function for comparing annotations

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net

    global DECOMP CURR VAULT
    
    switch lower(opt);
        
        case 'init';
            CURR.compare_file = [];
            CURR.swap = 0;
            CURR.compare = 0;

        case 'load'
            emgvault ('swap', 1);
            emgunit ('import', p1, p2);
%    
%            if isfield (p1, 'chan');
%                ix = find(p1.chan == CURR.chan);
%                emgunit ('import', [p1.time(ix), p1.unit(ix)], p2);
%            else
%                emgunit ('import', p1, p2);
%            end;
            emgcompare ('compare', 1);
            emgvault ('swap', 0);
            emgcompare ('compare', 1);
                       
            
        case 'compare'
            if CURR.compare
                for i=DECOMP.nunits:-1:1;
                    m = DECOMP.unit(i).map;
                    if m>0;
                        VAULT.chan(CURR.chan, ~CURR.swap+1).decomp.unit(m).visible = ...
                            DECOMP.unit(i).visible;
                    end;
                    s = emgslist(i);
                    if isempty(s) & DECOMP.unit(i).virtual;
                        emgunit ('delete', i);
                    end;
                end;
            end;
            if p1;
                emgcompare ('match');
            else
                DECOMP.compare_slist = [];
            end;
            CURR.compare = p1;
            
        case 'synch'
            emgcompare ('compare', CURR.compare);                            
            
        case 'match'
            currswap = CURR.swap;
            
            emgcompare ('compare', 0);
            emgvault ('swap', ~currswap);
            
            s1 = emgslist;
            if isempty(s1);
                n1 = 0;
            else
                 n1 = max(s1(:,2));
            end;
            if DECOMP.nunits==0;
                vis1 = [];
            else
                vis1 = [DECOMP.unit(:).visible];
            end;
        
            emgvault ('swap', currswap)            
            s2 = emgslist;
            if isempty(s2);
                n2 = 0;
            else
                 n2 = max(s2(:,2));
            end;
            
            [map, off] = my_compare (s2, s1);

            s3 = [];
            
  %          nu = DECOMP.nunits;
            for i=1:n2;
                if i>length(map);
                    DECOMP.unit(i).map = 0;
                elseif map(i)>0;
                    t = s1(s1(:,2)==map(i),1);
                    s3 = [s3; t+off(i), i+0*t];
                    DECOMP.unit(i).map = map(i);
                else
                    DECOMP.unit(i).map = 0;
                end;
            end;
 
            for i=1:n1;
                if all(map~=i);
                    n2 = n2 + 1;
                    t = s1(s1(:,2)==i,1);
                    s3 = [s3; t, n2+0*t];
                    emgunit ('create', t, 'virtual');
                    DECOMP.unit(n2).map = i;
                    DECOMP.unit(n2).visible = vis1(i);
                end;
            end;
            if ~isempty(s3)
                [b,ix] = sort(s3(:,1));
                DECOMP.compare_slist = s3(ix,:);
            else
                DECOMP.compare_slist = [];
            end;
            CURR.swap = currswap;
                
end;
     
    
function [map, off, match] = my_compare (s1, s2);
    tol = .002;
    if isempty(s1) | isempty(s2);
        map = [];
        off = [];
        return
    end;
    n1 = max(s1(:,2));
    n2 = max(s2(:,2));
    map = zeros(n1,1);
    match = zeros(n1,n2);
    rmatch = match;
    qmatch = match;
    moff = match;
    p0 = max(min(s1(:,1)),min(s2(:,1)))-tol;
    q0 = min(max(s1(:,1)),max(s2(:,1)))+tol;
    for i1=1:n1;
        t1 = s1(s1(:,2)==i1,1);
        m1 = sum(t1>p0 & t1<q0);
        if ~isempty(t1);
        for i2=1:n2;
            t2 = s2(s2(:,2)==i2,1);
            if ~isempty(t2);
            m2 = sum(t2>p0 & t2<q0);
            p = max(t1(1),t2(1))-tol;
            q = min(t1(end),t2(end))+tol;
            x1 = t1(t1>p & t1<q);
            x2 = t2(t2>p & t2<q);
            if ~isempty(x1) & ~isempty(x2);
                d = x1 - nearest(x2,x1);
                ix = find(abs(d)<.01);
                off = median(d(ix));
                n = sum(abs(d-off)<tol);
                match(i1,i2) = n;
                rmatch(i1,i2) = n/min(length(x1),length(x2));
                qmatch(i1,i2) = n/max(m1,m2);
                moff(i1,i2) = off;
            end;
            end;
        end;
        end;
    end;
    x = find(qmatch < 0.7 & (rmatch<0.25 | match<6));
    match(x) = 0;
    for i2 = 1:n2;
        [b,i1] = max(match(:,i2));
        match(:,i2) = 0;
        match(i1,i2) = b;
    end;
    for i1 = 1:n1;
        [b,i2] = max(match(i1,:));
        if qmatch(i1,i2)>0.7 | (b>5 & rmatch(i1,i2)>0.25);
            map(i1) = i2;
            off(i1) = moff(i1,i2);
        end;
    end;

