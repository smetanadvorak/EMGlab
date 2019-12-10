function emgplugin (opt, varargin)
% EMGlab interface for plugins

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net


    global EMGLAB
    
    switch (opt)
        
        case 'init'
            EMGLAB.plugin = {};
            currdir = pwd;
            d = dir (EMGLAB.path);
            for i = 1:length(d);
                if d(i).isdir & ~strcmp(d(i).name, '.') & ~strcmp(d(i).name, '..') ...
                        & ~strcmp(d(i).name, 'm files');
                    cd (fullfile(EMGLAB.path, d(i).name));
                    m = dir;
                    for im = 1:length(m);
                        name = m(im).name;
                        if length(name)<9;
                        elseif name(1)=='.'
                        elseif ~strcmp(name(end-7:end),'plugin.m');
                        else
                            func = name(1:end-2);
                            %try;
                            if feval (func, 'init');
                                EMGLAB.plugin{end+1} = func;
                                addpath (fullfile (EMGLAB.path, d(i).name));
                            end;
                            break;
                            %end;
                        end;
                    end;
                end;
            end;
            cd (currdir);
            
        otherwise
            for i=1:length(EMGLAB.plugin);
                feval (EMGLAB.plugin{i}, opt, varargin{:});
            end;
            
    end;
                    