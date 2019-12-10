function w = envelope (x);%	Compute the "hilbert window" of a signal specified by its RTP.% Copyright (c) 2006-2009. Kevin C. McGill and others.% Part of EMGlab version 1.0.% This work is licensed under the Aladdin free public license.% For copying permissions see license.txt.% email: emglab@emglab.net	xp = rtp (x);	lx = size(xp,1);	l2 = ceil (lx/2);	hp = zeros(size(xp));	hp(2:2*l2-1,:) = [xp(l2+1:2*l2-1,:); -xp(2:l2,:)];	w = x.^2 + irtp(hp).^2;	w = sqrt(w);	w = w / norm(w);