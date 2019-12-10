function t = findpeaks (signal, threshold, tmin);% Find peaks in the signal.% Copyright (c) 2006-2009. Kevin C. McGill and others.% Part of EMGlab version 1.0.% This work is licensed under the Aladdin free public license.% For copying permissions see license.txt.% email: emglab@emglab.net	[sig, t0, dt] = sigsep (signal);	if nargin<3; tmin = 0; end;	% find all peaks that exceed the threshold	ix = find (abs(sig) > threshold);    if isempty(ix); t=[]; return; end;	x = sig(ix); 	a = sig(max(ix-1,1));	if ix(1)==1; a(1) = 0; end;	b = sig(min(ix+1,length(sig)));	if ix(end)==length(sig); b(end) = 0; end;	k = find((x>0 & x>a & x>=b) | (x<0 & x<a & x<=b));	ix = ix(k);	% keep only the largest peak in each window	l = floor(tmin / dt);	if l > 0; 		oldlength = 0;		while length(ix) ~= oldlength			oldlength = length(ix);			k = find(diff(ix)<l);			i = find(abs(sig(ix(k)))<=abs(sig(ix(k+1))));			ix(k(i))=[];			k = find(diff(ix)<l);			i = find(abs(sig(ix(k+1)))<abs(sig(ix(k))));			ix(k(i)+1)=[];		end;	end;		t = t0 + dt*(ix-1);