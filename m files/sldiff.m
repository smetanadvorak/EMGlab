function [s, a, n] = sldiff (s1, s2, t0, t1, i1, i2)
% Compares two firing patterns.

%   a  = 0 means times match
%        1 means in s1 but not s2
%       -1 means in s2 but not s1
%   n  = 0 means not a near miss
%        1 means near miss, unit later
%       -1 means near miss, unit earlier

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net


    TOL1 = .0005; % tolerance for match
    TOL2 = .005;  % tolerance for near miss
    
    if ~isempty(s1);
    	s1 = s1(s1(:,1)>t0 & s1(:,1)<t1 & s1(:,2)>=i1 & s1(:,2)<=i2, :);
    end;

    if ~isempty(s2);
        s2 = s2(s2(:,1)>t0 & s2(:,1)<t1 & s2(:,2)>=i1 & s2(:,2)<=i2, :);
    end;

    
    a1 = zeros(size(s1,1),1);
    n1 = a1;
    a2 = zeros(size(s2,1),1);
    n2 = a2;
    if isempty(s1);
        s = s2;
        a = a2-1;
        n = n2;
        return;
    elseif isempty(s2);
        s = s1;
        a = a1+1;
        n = n1;
        return;
    end;
    nu = max([s1(:,2);s2(:,2)]);
    
    [b,ix] = sort(s1(:,1));
    s1 = s1(ix,:);
    
    [b,ix] = sort(s2(:,1));
    s2 = s2(ix,:);

    for i=1:nu
        i1 = find(s1(:,2)==i);
		t1 = s1(i1,1);
        i2 = find(s2(:,2)==i);
        t2 = s2(i2,1);
        if isempty(t1);
            a2(i2) = -1;
        elseif isempty(t2);
            a1(i1) = 1;
        else
            error = t1 - nearest (t2, t1);
            k = find(error>TOL1 & error<TOL2);
            n1(i1(k)) = 1;
            k = find(error>-TOL2 & error<-TOL1);
            n1(i1(k)) = -1;
            k = find(abs(error)>TOL1);
            a1(i1(k)) = 1;
            
            error = t2 - nearest (t1, t2);
            k = find(error>TOL1 & error<TOL2);
            n2(i2(k)) = 1;
            k = find(error>-TOL2 & error<-TOL1);
            n2(i2(k)) = -1;
            k = find(abs(error)>TOL1);
            a2(i2(k)) = -1;
           
        end;
    end;
    ix = find(a2);
    a = [a1;a2(ix)];
    n = [n1;n2(ix)];
    s = [s1;s2(ix,:)];
    return;
    

    for i=1:max(s2(:,2));
        i1 = find(s1(:,2)==i);
		t1 = s1(i1,1);
        i2 = find(s2(:,2)==i);
        t2 = s2(i2,1);
        if isempty(t2);
        elseif isempty(t1);
            a2(i2) = -1;
        else
            error = t2 - nearest (t1, t2);
            k = find(error>TOL1 & error<TOL2);
            n2(i2(k)) = 1;
            k = find(error>-TOL2 & error<-TOL1);
            n2(i2(k)) = -1;
            k = find(abs(error)>TOL1);
            a1(i1(k)) = 1;
        end;
    end;

%   a1 = 0 means times match
%        1 means near miss, s1 earlier
%        2 means near miss, s1 later
%        3 means error
%        4 means unit doesn't exist in s2


    TOL1 = .0005;
    TOL2 = .005;
    a1 = zeros(size(s1,1),1);
    if isempty(s1);
        return;
    elseif isempty(s2);
        a1 = a1+3;
        return;
    end;
    nu = max(s1(:,2));
    
    [b,ix] = sort(s1(:,1));
    s1 = s1(ix,:);
    
    [b,ix] = sort(s2(:,1));
    s2 = s2(ix,:);

    for i=1:nu;
        i1 = find(s1(:,2)==i);
		t1 = s1(i1,1);
        i2 = find(s2(:,2)==i);
        t2 = s2(i2,1);
        if isempty(t1);
%        elseif prog(i)==1;
%            a1(i1) = 4;
        elseif isempty(t2);
            a1(i1) = 3;
        else
            nearest_t2 = nearest (t2, t1);
            error = t1 - nearest_t2;
            k = find(error>TOL1 & error<TOL2);
            a1(i1(k)) = 2;
            k = find(error>-TOL2 & error<-TOL1);
            a1(i1(k)) = 1;
            k = find(abs(error)>TOL2);
            a1(i1(k)) = 3;
        end;
    end;
    
