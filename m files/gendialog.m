function [prefs,  status] = gendialog (prefs, title, fontsize)
% Implements dialog boxes, such as Preferences.

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net

if nargin<2; title = ' '; end;
if nargin<3; fontsize = 10; end;
ncol=1;
fields=fieldnames(prefs);
%nrow=length(fields);
nrow=0;
nseparators=0;
for i=1:length(fields)
	field=getfield(prefs,fields{i});
	if(field.access)
		nrow=nrow+1;
		if(field.separator==1)
			nrow=nrow+1;
			nseparators=nseparators+1;
		end
	end
	
end

h = dialog (...
	'name', title,...
	'color', [.9,.9,.9], ...
	'defaultuicontrolbackgroundcolor', [0.9,0.9,0.9], ...
	'visible', 'off');

set (h, 'windowstyle', 'normal', 'defaultuicontrolfontsize', fontsize);

legend_width = 0;
spopup_width = 0;
string_width = 0;

%get the extent of a text
t = uicontrol (h, 'style', 'text', 'string', 'X');
e = get(t, 'extent');
delete (t);
character_size = e(4);

for i=1:length(fields)
    field=getfield(prefs,fields{i});
	t = uicontrol(h, 'style', 'text', 'string',field.description);
	e = get(t,'extent')+5;
	legend_width = max(legend_width, e(3));
	delete (t);
	
	if field.access & ~isempty(field.choices)
		t = uicontrol(h, 'style', 'popup', 'string',field.choices );
		e = get (t,'extent');
		spopup_width = max (spopup_width, e(3));
		delete(t);
    elseif field.access & strcmp (field.type, 'string');
        t = uicontrol (h, 'style', 'text', 'string', field.value);
        e = get (t, 'extent');
        string_width = max(string_width, e(3));
        delete(t);
	end;
end

screenSize=get(0,'ScreenSize');
screenH=screenSize(4);
button_width = 4*character_size;
button_height = character_size;
margin = 25;
large_gap = 20;
small_gap = 5;
spopup_width = spopup_width + 3*character_size;
npopup_width = 4*character_size;
control_width = max([npopup_width, spopup_width, string_width]);
edit_adjust = [0, -1, 0, 2];
text_adjust = -4;


window_width = max (2*margin + ncol * (legend_width + small_gap + control_width) ...
	+ (ncol-1) * large_gap,  2*margin + 2*control_width + large_gap);
window_height = 2*margin + nrow*button_height + (nrow-1)*small_gap ...
	+ large_gap + button_height;
window_width=max((2*(margin+1+button_width)+margin),window_width);
sliderH=[];
%display rows is the number of rows
displayRows=nrow;
if(window_height>screenH)
	window_height=screenH-3*margin;
	%number of displayed Rows
	displayRows=floor(window_height/(button_height+small_gap+1));
	window_height=displayRows*(button_height+small_gap+1);
	displayRows=displayRows-1;
	a=nrow-displayRows;
	sliderW=20;
	sliderH=window_height-margin-1-button_height;
	sliderH=uicontrol('parent',h,...
		'Style', 'slider', ...
		'Units', 'pixels', ...
		'Min',0,...
		'Max',a,...
		'Callback',@scroll,...
		'pos',[window_width-sliderW,margin+1+button_height,sliderW,sliderH],...
		'SliderStep', [1/a,displayRows/(nrow-displayRows)], ...
		'Value', a );

end


p = get (h, 'pos');
set (h, 'position', [p(1), p(2), window_width, window_height], ...
	'visible', 'on', ...
	'userdata',prefs,...
	'windowstyle', 'normal');

uicontrol (h, ...
	'style', 'pushbutton', ...
	'backgroundcolor', [.8,.8,.8], ...
	'position', [margin+1, margin+1, button_width, button_height], ...
	'string', 'Cancel', ...
	'callback', 'delete(gcf)');
uicontrol (h, ...
	'style', 'pushbutton', ...
	'backgroundcolor', [.8,.8,.8], ...
	'position', [window_width-margin-button_width, margin+1, ...
	button_width, button_height], ...
	'string', 'OK', ...
	'callback','uiresume(gcf)');

iy=0;
ix=0;
countRows=0;

textHandles=zeros(1,nrow);
displayTextPos=zeros(displayRows,4);
boxHandles=zeros(1,nrow);
displayBoxPos=zeros(displayRows,4);

y0 = window_height - margin-button_height+1;
for i=1:length(fields)
	field=getfield(prefs,fields{i});

	if(field.access)
		countRows=countRows+1;

		iy=iy+1; ix=1;
		x0 = margin + (ix-1)*(legend_width + small_gap + control_width + large_gap) + 1;
		x1 = x0 + legend_width + small_gap;
	    %y0 = window_height - margin - (iy-1)*(button_height + small_gap) + 1;
	
        
		

		if(countRows<=displayRows)
			visisbleStr='on';
			displayTextPos(countRows,:)=[x0, y0+text_adjust, legend_width, button_height];
			displayBoxPos(countRows,:)=[x1, y0, control_width, button_height] + edit_adjust;
		else
			visisbleStr='off';
		end

		if(field.separator==1)
			
			textHandles(countRows)=uicontrol (h, ...
			'style', 'text', ...
			'position', [x0, y0+text_adjust, legend_width, button_height], ...
			'horiz', 'r', ...
			'backgroundcolor', [.9,.9,.9], ...
			'vis',visisbleStr,...
			'string', ' ');
		    boxHandles(countRows)=uicontrol (h, ...
				'style', 'text', ...
				'position', [x1, y0, control_width, button_height] + edit_adjust, ...
				'horiz', 'r', ...
				'background', [.9,.9,.9], ...
				'vis',visisbleStr,...
				'string','' );
			y0 = y0-(button_height + small_gap) + 1;
			countRows=countRows+1;
			if(countRows<=displayRows)
				visisbleStr='on';
				displayTextPos(countRows,:)=[x0, y0+text_adjust, legend_width, button_height];
				displayBoxPos(countRows,:)=[x1, y0, control_width, button_height] + edit_adjust;
			else
				visisbleStr='off';
			end
		end
		
		textHandles(countRows)=uicontrol (h, ...
			'style', 'text', ...
			'position', [x0, y0+text_adjust, legend_width, button_height], ...
			'horiz', 'r', ...
			'backgroundcolor', [.9,.9,.9], ...
			'vis',visisbleStr,...
			'string', field.description);
		if(isempty(field.choices))
			if ischar(field.value)
                value = field.value;
            elseif round(field.value)==field.value
                value = sprintf ('%g', field.value);
            else                
                value =sprintf ('%.3g', field.value);
			end

			boxHandles(countRows)=uicontrol (h, ...
				'style', 'edit', ...
				'position', [x1, y0, control_width, button_height] + edit_adjust, ...
				'horiz', 'r', ...
				'background', [1,1,1], ...
				'UserData',fields{i},...
				'Callback',@checkValue,...
				'vis',visisbleStr,...
				'string',value );
		else
			if(~ischar(field.value))
				popupValue=1;
				for p=1:length(field.choices)
					if(field.choices{p}==field.value)
						popupValue=p;
						break;
					end
				end


				boxHandles(countRows)=uicontrol (h, ...
					'style', 'popup', ...
					'position', [x1, y0, control_width, button_height], ...
					'background', [.8,.8,.8], ...
					'vis',visisbleStr,...
					'UserData',fields{i},...
					'string',  field.choices, ...
					'Value',popupValue,...
					'horiz', 'r');
			else
				popupValue=1;
				for p=1:length(field.choices)
					if(strcmp(field.choices{p},field.value)==1)
						popupValue=p;
						break;
					end
				end
				boxHandles(countRows)=uicontrol (h, ...
					'style', 'popup', ...
					'position', [x1, y0, control_width, button_height], ...
					'string',field.choices , ...
					'UserData',fields{i},...
					'background', [.8,.8,.8], ...
					'vis',visisbleStr,...
					'Value',popupValue,...
					'horiz', 'l');
			end


		end
		y0 = y0-(button_height + small_gap) + 1;
	end

end

if(~isempty(sliderH))
	sliderStruct=struct(...
		'textHandles',textHandles,...
		'displayTextPos',displayTextPos,...
		'boxHandles',boxHandles,...
		'displayBoxPos',displayBoxPos,...
		'displayRows',displayRows,...
		'nrows',nrow);

	set(sliderH,'UserData',sliderStruct);

end
uiwait(h);
if(ishandle(h))
	for i=1:length(boxHandles)
		fieldName=get(boxHandles(i),'UserData');
		if(isfield(prefs,fieldName))
			field=getfield(prefs,fieldName);
			style=get(boxHandles(i),'style');
			if(strcmp(style,'edit')==1)
				value = get(boxHandles(i), 'string');
				if(~ischar(field.value))
					value=sscanf(value,'%g');
					if(isstr(value))
						value=field.value;
					end
				end
				field.value=value;
				prefs=setfield(prefs,fieldName,field);
			else
				choices=get(boxHandles(i),'string');
				value=get(boxHandles(i),'Value');
				newValue=choices{value};
				if(~ischar(field.value))
					newValue=sscanf(choices{value},'%g');
				end
				field.value=newValue;
				prefs=setfield(prefs,fieldName,field);

			end

		end
	end
	delete(h);
    status = 1;
else
    status = 0;
end

function scroll(src,evnt)
sliderStruct=get(gcbo,'UserData');
textHandles=sliderStruct.textHandles;
displayTextPos=sliderStruct.displayTextPos;
boxHandles=sliderStruct.boxHandles;
displayBoxPos=sliderStruct.displayBoxPos;
displayRows=sliderStruct.displayRows;
nrows=sliderStruct.nrows;
value=get(gcbo,'Value');
value=floor(value);
startIndex=nrows-value-displayRows;
set(textHandles,'vis','off');
set(boxHandles,'vis','off');
for i=1:displayRows
	set(textHandles(startIndex+i),'pos',displayTextPos(i,:),'vis','on');
	set(boxHandles(startIndex+i),'pos',displayBoxPos(i,:),'vis','on');
end

%set(gcbo,'value',value);
function checkValue(src,evnt)
fieldName=get(gcbo,'UserData');
prefs=get(gcf,'UserData');
field=getfield(prefs,fieldName);
newValue=get(gcbo,'String');
h=gcbo;

if(~ischar(field.value))
	[value,count,errmsg,nextindex]=sscanf(newValue,'%g');
	
	
	if(~isempty(errmsg))
		warndlg('Value has to be a number!');
		s=sprintf ('%g', field.value);
		set(h,'String',s);
		
	end
end





