function [output, err] = clerk (action, PREFERENCES, varargin)
% EMGlab function for managing the Preference structure

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net


if nargin == 0
	action='construct';
end

err = '';
         
switch lower (action)
%--------------------------------------------------------------------------
	%construct the preferences 
	case 'construct'
			
		% default preferences
		output = [];
		
%--------------------------------------------------------------------------
	%add a preference
	case 'add'
        output = PREFERENCES;
        
		newField= struct(...
			 'type',[],...
			 'value',[],...
			 'choices',[],...
			 'access',1,...
			 'description',[],...
		     'separator',0);


        [fieldName, type, value, choices, access, description, separator, err] = getargs (varargin);
        if ~isempty(err);
            [fieldName, type, value, choices, access, description, err] = getargs (varargin);
            separator = 0;
            if ~isempty(err); return; end;
        end;
        
 		if ~ischar (fieldName);
            err = 'Field name must be a string';
            return; 
        end;
 			
		if isfield (PREFERENCES,fieldName)
			err = 'Field name already exists';
            return;
        end;
        
		if ~typecheck (type, 'string', {'int', 'string', 'double'});
            err = 'Invalid type';
            return;
        end;
        newField.type = type;
        
        err = typecheck (value, type, choices);
            if ~isempty(err); return; end;
        newField.value = value;
        
        newField.choices = choices;
        
        if ~typecheck (access, 'int', {0, 1});
            err = 'Access must be 0 or 1';
            return;
        end;
        newField.access = access;
        
        if ~ischar (description);
            err = 'Description must be a string';
            return;
        end;
        newField.description = description;
        
        if ~typecheck (separator, 'int', {0, 1});
            err = 'Separator must be 0 or 1';
            return;
        end;
        newField.separator = separator;
          
        output = setfield (PREFERENCES, fieldName, newField);
						
%--------------------------------------------------------------------------	
    %get the value of the field
	case 'get'
        output = [];
        [fieldName, err] = getargs (varargin);
            if ~isempty(err); return; end;

        [field, err] = mygetfield (PREFERENCES, fieldName);
            if ~isempty(err); return; end;

        output = field.value;	
        
%--------------------------------------------------------------------------	
    %set the value of the field		
	case 'set'
        output  = PREFERENCES;
        [fieldName, newValue, err] = getargs (varargin); 
            if ~isempty(err); return; end; 
                    
        [field, err] = mygetfield (PREFERENCES, fieldName);
            if ~isempty(err); return; end;
        
        err = typecheck (newValue, field.type, field.choices);
            if ~isempty(err); return; end;
        
        field.value = newValue;
        PREFERENCES  = setfield (PREFERENCES, fieldName, field);
        output = PREFERENCES;
    
    
%--------------------------------------------------------------------------
   %load the prefs file
	case 'load'
		output = PREFERENCES;
        
        [filename, err]  = getargs (varargin);
            if ~isempty(err); return; end;
            
		%load the preferences from the preferences file
		%open the preferences file
        fid = fopen (filename);
		if fid<=0;
            err = ['Cannot open preferences file:',filename];
			return;
		end
		
		while ~feof(fid);
			l = fgetl (fid);
		    if l(1)=='#'; break; end;
			[fieldName,l] = strtok (l);
			if all(isspace(l));break; end;
			while isspace (l(1));
				l(1)=[];
			end;
			if isfield(PREFERENCES,fieldName)
				field=getfield(PREFERENCES,fieldName);
                
                switch field.type;
                    case 'string'
                        newValue = l;
                    case 'double'
                        newValue = sscanf (l, '%g');
                    case 'int'
                        newValue = sscanf (l, '%i');
                end;
                
                err = typecheck (newValue, field.type, field.choices);
                if isempty(err);
                    field.value = newValue;
                end;
				PREFERENCES=setfield(PREFERENCES,fieldName,field);
			end
			

 		end
		fclose (fid); 
        output = PREFERENCES;
        varargout{1} = 1;
		 	
%--------------------------------------------------------------------------	
         %save the preferences to the preferences file
	case 'save'
        [filename, err] = getargs (varargin);
            if ~isempty(err); return; end;
                
        f = fieldnames(PREFERENCES);
		buffer={};
		%fields that already exist in the buffer
		fieldsInBuffer=[];
		fid = fopen (filename, 'r');
		if fid>0
			while ~feof(fid);
				l = fgetl (fid);
				buffer{end+1}=l;
			end
			fclose(fid);
			%find the coresponding fields in the buffer and change their value
			for p=1:length(buffer)
				if(buffer{p}(1)~='#')
					[fieldName,value]= strtok(buffer{p});
					if(isfield(PREFERENCES,fieldName))
						field=getfield(PREFERENCES,fieldName);
						if(isstr(field.value))
							newValue=field.value;
						else
							newValue=sprintf('%g ',field.value);
						end
						buffer{p}=[fieldName,' ',newValue];
						for i=1:length(f)
							if(strcmp(f{i},fieldName)==1)
								fieldsInBuffer(end+1)=i;
								break;
							end
						end

					end
				end
			end
		end
		%open the file to write the new values 
		fid = fopen (filename, 'wt');
		if fid<=0;
            err = 'Unable to save preferences file.';
			return
		end;
		%write the buffer first
		if(~isempty(buffer))
			for i=1:length(buffer);
				fprintf(fid,'%s\n',buffer{i});
			end
		end
			
		for i=1:length(f);
			%find if the fild already exists in the buffer
			existsInBuffer=find(fieldsInBuffer==i);
			if(isempty(existsInBuffer))
				fieldName = f{i};
				field = getfield (PREFERENCES, fieldName);
				val=field.value;
				if ischar (val);
					fprintf (fid, '%s %s\n', fieldName, val);
				else
					fprintf (fid, '%s %g %g %g %g', fieldName, val);
                    fprintf (fid, '\n');
				end
			end
		end;
		fclose (fid);
		output = PREFERENCES;
		
end




function varargout = getargs (arguments);
    varargout = cell(nargout,1);
    if length(arguments)==nargout - 1;
        [varargout{1:length(arguments)}] = deal(arguments{:});
    else
        varargout{end} = 'Wrong number of arguments';
    end;

function [field, err] = mygetfield (S, fieldName);
    if ~isfield (S, fieldName);
        field = [];
        err = 'Field does not exist';
    else
        field = getfield (S, fieldName);
        err = '';
    end;


function errmsg = typecheck (value, type, choices);
    errmsg = '';
    switch type;
        case 'string'
            if ~isstr (value);
                errmsg = 'The new value must be a string';
                return;
            end;            
        case 'int'
            if ~isnumeric (value);
                errmsg = 'The new value must be an integer';
                return;
            elseif value~=round(value);
                errmsg = 'The new value must be an integer';
                return;
            end;            
        case 'double'
            if ~isa(value, 'double');
                errmsg = 'The new value must be numeric';
                return;
            end; 
    end;
    
    if ~isempty(choices);
        OK = 0;
        for i=1:length(choices)
            if length(value) == length(choices{i});
                if all(value==choices{i});
                    OK = 1;
                end;
            end
        end;
        if ~OK
            errmsg = 'The new value is not a valid choice';
        end;
    end;

        
