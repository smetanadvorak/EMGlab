function [varargout] = read_sc2(opt,varargin)
% Custom reader for MUtools data files.

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net

varargout=[];
switch lower(opt)
    
    case 'open'
           [chan,info,status]= read_sc1(opt,varargin{:});
           varargout={chan,info,status};
    case 'load'
           [data]= read_sc1(opt,varargin{:});
           varargout{1}=data;
end
