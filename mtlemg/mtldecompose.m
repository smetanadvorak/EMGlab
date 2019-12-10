%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 

%
% Sampling rate of your data in Hz
%
% SAMPLING_RATE = 23437.5;
SAMPLING_RATE = 10000;

%
% Level of difficulty for clustering
% Set to '1' if HIGH intra-MUAP variability and LOW inter-MUAP similarity 
% Set to '2' if medium
% Set to '3' if LOW intra-MUAP variability and HIGH inter-MUAP similarity 
%
CLUSTERING_DIFFICULTY_LEVEL = 2;

%
% Set to 'true' (or 1) to perform an automatic clustering,
% otherwise (e.g. you already have your MUAP templates and
% you are solely interested in identification) set to 'false'
%
PEFORM_AUTOMATIC_CLUSTERING = false;

%
% Set to 'true' (or 1) to perform an automatic identification,
% otherwise set to 'false'
%
PEFORM_AUTOMATIC_IDENTIFICATION = true;
% PEFORM_AUTOMATIC_IDENTIFICATION = ~PEFORM_AUTOMATIC_CLUSTERING;


if PEFORM_AUTOMATIC_CLUSTERING
    [cMuap, cSeg, mPsC]  = mtlcluster(signal, SAMPLING_RATE, CLUSTERING_DIFFICULTY_LEVEL);
end

if PEFORM_AUTOMATIC_IDENTIFICATION
    if ~exist('mPsC', 'var')
        mPsC = ones(size(cMuap));
    end
    cSite = mtlidentify(signal, cMuap, SAMPLING_RATE, mPsC);
    for i = 1 : size(cSite, 1)
        for j = 1 : size(cSite, 2)
            [t, k] = max(abs(cMuap{i, j}));
            cSite{i, j} = cSite{i, j} + k;
        end
    end
end

clear PEFORM_AUTOMATIC_CLUSTERING PEFORM_AUTOMATIC_IDENTIFICATION i j k t
clear SAMPLING_RATE CLUSTERING_MINIMUM_MUAPS CLUSTERING_DIFFICULTY_LEVEL