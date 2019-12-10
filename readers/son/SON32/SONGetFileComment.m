function string=SONGetFileComment(fh, n)
% SONGETFILECOMMENT returns the file comment
% 
% STRING=SONGETFILE(FH, N)
% where FH is the file handle and N is the comment number (0-4);
% 
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

string=char(zeros(1,80));
string=calllib('son32', 'SONGetFileComment', fh, n, string, 79);