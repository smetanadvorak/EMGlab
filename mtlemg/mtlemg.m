function site = mtlemg(signal, rate, gaflag)
% MTLEMG Stand alone MTL automatic decomposition function.
%
%   annotation = mtlemg (signal, rate, gaflag)
% 
%       signal: the EMG signal to be decomposed. It can be either a vector 
%               (single-channel) or a matrix (multi-channel). Vector or matrix 
%               orientation (i.e., nxm vs. mxn) is unimportant. For best results, 
%               the signal should be high-pass filtered, with a cut-off frequency 
%               between 500 and 1000 Hz.
%
%       rate:	The sampling rate in Hz. The sampling rate is a positive scalar. 
%
%       gaflag: Optional. If set to 1, then the genetic algorithm will be used to 
%               resolve superimpositions. 
%
%       annotation: a 1xn cell structure, where n is the number of channels. Each cell 
%               is a dx2 matrix, where d is the total number of discharges identified 
%               in each individual channel. For each row of the matrix, the first and 
%               second columns represent the detected time occurrence in seconds and the 
%               MU ID, respectively. Also note that MU numbering is consistent across channels, 
%               e.g. MU #1 in channel 1 will be the same as MU #1 in channels 2 through n.   

%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 

if nargin<3; gaflag = 0; end;

vStr = 'mtlemg';
nStr = length(vStr);
vPat = which(vStr);
vPat = vPat(1 : end - nStr - 2);

if strcmp(computer, 'PCWIN')
    addpath([vPat, 'dll files']);
else
    addpath([vPat, 'm files']);
end

if ~exist('interp')
    addpath([vPat, 't files']);
end

[cMup, cSeg, mPsC]  = mtlcluster(signal, rate, 2);

cSit = mtlidentify(signal, cMup, rate, mPsC, gaflag);

[nCan, nMup] = size(cSit);

for i = 1 : nCan
    for j = 1 : nMup
        [t, k] = max(abs(cMup{i, j}));
        cSit{i, j} = cSit{i, j} + k;
    end
end

site = cell(1, nCan);
for iCan = 1 : nCan
    mAnn = [];
    for iMup = 1 : nMup
        nSit = size(cSit{iCan, iMup}, 2);
        if nSit>0;
            mAnn = [mAnn; [cSit{iCan, iMup} / rate; iMup * ones(1, nSit)]'];
        end;
    end
    [tmp, iTri] = sort(mAnn(:, 1));
    site{iCan} = mAnn(iTri, :);
end