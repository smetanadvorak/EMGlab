function ver=SONVersion(varargin)
%SONVERSION returns/displays the version number of the matlab SON library
% 
% VER=SONVERSION
%       returns and displays the version while
% VER=SONVERSION('nodisplay')
%       suppresses the display
%
% Author: Malcolm Lidierth 10/06
% Copyright © The Author & King's College London 2002-2006

title='MATLAB SON  library';
ver=2.31;
if nargin==0 || strcmpi(varargin{1},'nodisplay')~=1
st=sprintf('Author:Malcolm Lidierth\nmalcolm.lidierth@kcl.ac.uk\n Copyright %c King%cs College London 2002-2007\n Version:%3.2f 20.05.06\n\nSON Filing system \nCopyright %c Cambridge Electronic Design 1988-2004 Version 7.0',169,39,ver,169);
(msgbox( st,title,'modal'));
end;
