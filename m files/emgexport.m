function emgexport (opt, p1)  
% EMGlab function for the Export command.

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net


    global SCREEN CURR DECOMP EMG


    if ~strcmp (opt, 'create');
        fig = get (gcbo, 'parent');
        u = get (fig, 'user');
    end;
    
    switch  lower(opt)
          
    case 'create';
        dialog_width = 400;
        dialog_height = 350; 
        screenSize = get(0,'ScreenSize');
        screenWidth = screenSize(3);
        screenHeight = screenSize(4);
        %Positioning in the middle of the screen
        position = [(screenWidth-dialog_width)/2,(screenHeight-dialog_height)/2,dialog_width,dialog_height];

        h = dialog (...
            'name', 'Export EMGlab variable',...
            'color', [.9,.9,.9],...
            'defaultuicontrolbackgroundcolor', [0.8,0.8,0.8],...
            'position', position,...
            'visible', 'on', ...
            'windowstyle', 'normal', ...
            'defaultuicontrolfontsize', 12, ...
            'defaultuicontrolhorizontalalignment', 'left');            

        t = uicontrol (h, 'style', 'text', 'string', 'X', 'vis', 'off');
        e = get (t, 'extent');
        character_size = e(4);	

        margin_x = 15;
        margin_y = 15;
        button_width = 4*character_size;
        button_height = character_size;
        label_width = 5*character_size;
        radio_width = dialog_width - 2*margin_x - label_width;
        radio_height = button_height + 4;

        y0 = dialog_height - margin_y;
        x0 = margin_x + label_width;
        text_offset = -4;
        
        if get(gcbo,'parent') == get(SCREEN.firing.text(1),'uicontextmenu');
            request = 'pattern';
        elseif CURR.band==1;
            request = 'muap';
        else
            request = 'template';
        end;
            
        u.unit = p1;
        
        uicontrol (h, ...
            'style', 'text', ...
            'string', 'Export the    ', ...
            'horizontal', 'right', ...
            'backgroundcolor', [.9,.9,.9], ...
            'position', [margin_x, y0 - 1*radio_height + text_offset, label_width, radio_height]);
        u.temp = uicontrol (h, ...
            'style', 'radiobutton', ...
            'String','Template',...
            'Value', strcmp (request, 'template'),...
            'position', [x0, y0 - 1*radio_height, radio_width, radio_height],...
            'callback','emgexport(''temp'');');
        u.muap = uicontrol (h, ...
            'style', 'radiobutton', ...
            'String','MUAP waveform',...
            'value', strcmp (request, 'muap'), ...
            'position', [x0, y0 - 2*radio_height, radio_width, radio_height],...
            'callback','emgexport(''muap'');'); 
        u.fpat = uicontrol (h, ...
            'style', 'radiobutton', ...
            'String', 'Firing pattern',...
            'value', strcmp (request, 'pattern'),...
            'position', [x0, y0 - 3*radio_height, radio_width, radio_height],...
            'callback', 'emgexport(''fpat'');');
        u.ifr = uicontrol (h, ...
            'style', 'radiobutton', ...
            'String','Instantaneous firing rate',...
            'position', [x0, y0 - 4*radio_height, radio_width, radio_height],...
            'callback','emgexport(''ifr'');'); 
        
        uicontrol (h, ...
            'style', 'text', ...
            'string', 'of    ', ...
            'horizontal', 'right', ...
            'backgroundcolor', [.9,.9,.9], ...
            'position', [margin_x, y0 - 6*radio_height + text_offset, label_width, radio_height]);
        u.one = uicontrol (h, ...
            'style', 'radiobutton', ...
            'String', sprintf ('unit %i', p1),...
            'Value',1,...
            'position', [x0, y0 - 6*radio_height, radio_width, radio_height],...
            'callback','emgexport(''one'');');
        u.all = uicontrol (h, ...
            'style', 'radiobutton', ...
            'String', 'all the units (as a cell array)',...
            'position', [x0, y0 - 7*radio_height, radio_width, radio_height],...
            'callback','emgexport(''all'');');

        uicontrol (h, ...
            'style', 'text', ...
            'String','to the variable    ',...
            'backgroundcolor', [.9,.9,.9], ...
            'horizontal', 'right', ...
            'position', [margin_x, y0 - 9*radio_height + text_offset, label_width, radio_height]);
        u.name = uicontrol (h, ...
            'style', 'edit', ...
            'backgroundcolor', [1,1,1], ...
            'position', [x0, y0 - 9*radio_height, radio_width, radio_height], ...
            'callback', 'emgexport(''name'')');     

 
        uicontrol (h, ...
            'style', 'pushbutton', ...
            'position', [margin_x, margin_y,button_width ,button_height], ...
            'string', 'Cancel', ...
            'horizontal', 'center', ...
            'callback', 'emgexport(''cancel'');');
        uicontrol (h, ...
            'style', 'pushbutton', ...
            'position', [position(3)-button_width-margin_x,margin_y,button_width,button_height], ...
            'string', 'OK', ...
            'horizontal', 'center', ...
            'callback', 'emgexport(''OK'');');
        
       u.edited = 0;
       create_name (u);
       set (h, 'user', u);

            
    case 'temp';
        set (u.temp, 'value', 1);
        set (u.muap, 'value', 0);
        set (u.fpat, 'value', 0);
        set (u.ifr,  'value', 0);            

    case 'muap';
        set (u.temp, 'value', 0);
        set (u.muap, 'value', 1);
        set (u.fpat, 'value', 0);
        set (u.ifr,  'value', 0);            

    case 'fpat';
        set (u.temp, 'value', 0);
        set (u.muap, 'value', 0);
        set (u.fpat, 'value', 1);
        set (u.ifr,  'value', 0);            

    case 'ifr';
        set (u.temp, 'value', 0);
        set (u.muap, 'value', 0);
        set (u.fpat, 'value', 0);
        set (u.ifr,  'value', 1);            

    case 'one';
        set (u.one, 'value', 1);
        set (u.all, 'value', 0);

    case 'all';
        set (u.one, 'value', 0);
        set (u.all, 'value', 1);
        
    case 'name'
        u.edited = 1;
        set (fig, 'user', u);

    case 'cancel';
        delete (fig);
        return;

    case 'ok';
        one = get (u.one, 'value');
        fc = [0.5, 1, 2, 4, 8, 16];
        fc = fc(get(SCREEN.firing.lowpass, 'value'));

        if get (u.temp, 'value') & one
            x = emgtemp(u.unit, 'interp');
            data = x.sig;

        elseif get (u.temp, 'value');
            for i=1:DECOMP.nunits;
                x = emgtemp(i, 'interp');
                data (:,i) = x.sig;
            end;

        elseif get (u.muap, 'value') & one;
            data = DECOMP.unit(u.unit).waveform.sig;

        elseif get (u.muap, 'value');                
            for i=1:DECOMP.nunits;
                data(:,i) = DECOMP.unit(i).waveform.sig;
            end;

        elseif get (u.fpat, 'value') & one
            data = emgslist (u.unit);

        elseif get (u.fpat, 'value');
            for i=1:DECOMP.nunits;
                data{i} = emgslist (i);
            end

        elseif get (u.ifr, 'value') & one;
            t = [0: .01: EMG.duration-.01]';
            x = emgslist(u.unit);
            data = ifr (x, t, fc);

        elseif get (u.ifr, 'value')
            t = [0: .01: EMG.duration-.01]';
            for i=1:DECOMP.nunits;
                x = emgslist(i);
                data(:,i) = ifr (x, t, fc);
            end;

        end;

        assignin ('base', get(u.name, 'string'), data);
        delete(gcf);
        return;

    end;
    
    create_name (u);
    
function create_name (u)
    if u.edited; return; end;
    if get (u.temp, 'value');
        request = 'template';
    elseif get (u.muap, 'value');
        request  = 'muap';
    elseif get (u.fpat, 'value');
        request = 'pattern';
    else
        request = 'ifr';
    end;
    if get (u.one, 'value');
        name = sprintf ('%s_%i', request, u.unit);
    else
        name = sprintf ('%ss', request);
    end;
    set (u.name, 'string', name);
        

