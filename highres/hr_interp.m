function x = hr_interp (p, t);% HR_INTERP Hi-resolution interpolation.%    V = HR_INTERP(P,T) -> evaluates the continuous time-domain %    signal specified by the RTP coefficients P at time instant T. %    If T is scalar, all the columns of P are evaluated at that instant.%    Otherwise T must have as many elements as P has columns.%    The output V has one element for each column of P.% Copyright (c) 2006-2009. Kevin C. McGill and others.% Part of EMGlab version 1.0.% This work is licensed under the Aladdin free public license.% For copying permissions see license.txt.% email: emglab@emglab.net	lx = size(p,1);	l2 = ceil(lx/2);	p = hr_shift (p, -t);	x = real (p(1,:)*sqrt(2) +2*sum(p(2:l2,:))) / sqrt(2*lx);