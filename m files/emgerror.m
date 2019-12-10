function [status,errMes]=emgerror(err)
% EMGlab function for saving the errors in a log file 
% err: error 
% status: 1==>OK. 0==>error


% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net

logFileName = 'emglab.log';

%Initialize status to 0  (error)
status=0;
errMes='';

%create the path to the log file 
path = fileparts(which('emglab'));
logFile = fullfile (path,logFileName);

%try to open the log file
fid=fopen(logFile,'a');
%if failed to create or open the file return with status 0
if(fid<0); return; end;	


if(isstruct(err))
	%get the err struct fields
	fieldNames=fieldnames(err);
	%print separators
	
	fprintf(fid,'%s\n','==============================================');
	
	for i=1:length(fieldNames)
		fprintf(fid,'%s',fieldNames{i});
		fprintf(fid,'%s',': ');
		field=getfield(err,fieldNames{i});
		switch lower(fieldNames{i})
			case 'message'
				% the error Message
				if(ischar(field))
					errMes=[field,'\n\n'];
					fprintf(fid,'%s \n',field);
				end
				
			case 'identifier'
				%the identifier
				if(ischar(field))
					fprintf(fid,'%s \n',field);
				end
				
			case 'stack'
				numStructs=length(field);
			    curStruct=field;
				for count=1:numStructs
				fieldNames=fieldnames(curStruct(count));
				fprintf(fid,'%s\n','');
				for fieldNum=1:length(fieldNames)
					field=getfield(curStruct(count),fieldNames{fieldNum});
					fprintf(fid,'%s',fieldNames{fieldNum});
					fprintf(fid,'%s',': ');
					if(ischar(field))
						fprintf(fid,'%s \n',field);
					elseif(isnumeric(field))
						fprintf(fid,'%d\n',field);
					end

                   
							
                end
                file=getfield(curStruct(count),'file');
                name=getfield(curStruct(count),'name');
                line=getfield(curStruct(count),'line');
                if(isempty(line))
                    line='1';
                end
                file=regexprep(file,'\','\\\');
                lineMes=['Error in ==> <a href="error:',...
                         file,...
                         ',',num2str(line),',1">',...
                         name,' at ',num2str(line),'</a>\n\n'];
                 errMes=[errMes,lineMes];   

			end
				
		end
		

	end


	fprintf(fid,'%s\n','');
	fclose(fid);
	
	%success
	status=1;

else
	fclose(fid);
	%Invalid error
	return;
end
	





	



