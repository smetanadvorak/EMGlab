function emgkeypress (src, evnt)
% EMGlab function for keypress events

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net

    global EMGLAB 
    panels={'signal','signal','signal','signal','firing','firing','navigation','navigation',...
            'signal','signal','firing','firing',...
            'signal','signal','firing','firing','navigation','navigation',...
            'template','template'};
    buttons={'<','>','<','>','<','>','<','>',...
            '-','+','-','+',...
            '| |','|||', '| |','|||', '| |','|||',...
            '-','+'};

    if ispc
        limitVersion = 7.01;
        keys = [28,29,44,46,60,62,12,18,...
                45,61,95,43,...
                110,119,78,87,14,23,...
                45,61]; % PC
    else
         limitVersion = 7.20;
         keys = [-1,-1,44,46,60,62,12,18,...
                45,61,95,43,...
                110,119,78,87,14,23,...
                45,61]; %% Mac: -1 because l/r arrows do not work in X11 window
     end

    if EMGLAB.matlab_version < limitVersion
        key=get(gcbf,'CurrentCharacter');
        if ~isempty(key)
            index = find(keys==abs(key));
            if ~isempty(index)
                for i=1:length(index)
                emgbutton (panels{index(i)}, buttons{index(i)});
                end
                drawnow; %fix for Mac continous scrolling
            end

        end
    else
        panel='signal';
        if ~isempty(evnt.Modifier)
            switch evnt.Modifier{1}
                case 'shift'
                    panel='firing';
                case 'control'
                    panel='navigation';
                otherwise
                    panel='signal';
            end
        end
        switch evnt.Key
            case {'rightarrow', 'period'}
                emgbutton (panel, '>');

            case {'leftarrow', 'comma'}
                emgbutton (panel, '<');

            case 'equal'
                if strcmp (panel, 'firing');
                    emgbutton ('firing', '+');
                else 
                    emgbutton ('signal', '+');
                    emgbutton ('template', '+');
                end;

            case 'hyphen'
                if strcmp (panel, 'firing');
                    emgbutton ('firing', '-');
                else 
                    emgbutton ('signal', '-');
                    emgbutton ('template', '-');
                end;
            case 'w'
                emgbutton (panel, '|||');

            case 'n'
                emgbutton (panel, '| |');
        end
    end

