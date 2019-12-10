function emgstatus (opt, p1, p2)
% Handles major changes in EMGlab state.

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net

global CURR SETS

switch lower(opt);
    
    case 'init'
        emgprefs ('init');
        emgsettings ('init');
        emgsignal ('init');
        emgunit ('init');
        emgvault ('init');
        emgcompare ('init');
        emgcursors ('init');
        
    case 'new signal';  %  new signal (reset)  
        emgsettings ('reset');
        emgunit ('init');
        emgvault ('init');
        emgcompare ('init');
        emgcursors ('init');

    case 'init annotation'
        emgunit ('init');
        emgcompare ('init');
        emgvault ('init annotation');
        SETS.firing.style = 'normal';
        SETS.template.first_unit = 1;
        emgstatus ('new annotation');

    case 'new annotation'   
        SETS.closeup.style='empty';
        CURR.unit = 0;
        CURR.swap = 0;
        CURR.compare = 0;
        emgsettings ('show all templates');
        
    case 'new unit'
        emgcompare ('synch');
        emgsettings ('show all templates');
        
    case 'change channel'
        emgvault ('channel', p1);
        emgsignal ('filter');
        emgunit ('filter');
 	      
    case 'new template size'
        emgunit ('resize');
        if isempty(DECOMP.closeup);
            SETS.closeup.style = 'empty';
        end;
        emgcursors ('timebase', 'closeup', '?');
        
    case 'new buffer size';
        emgsignal ('connect', CURR.chan, 1);
        emgsignal ('connect', CURR.auxchan, 2);
        emgcursors ('timebase', 'navigation', '?');
        
    case 'import annotation'
        Ann = p1;
        filename = p2;
        emgcompare ('compare', 0);
        emgvault ('swap', 0);
        emgunit ('import', Ann, filename);
        emgunit ('reaverage');

        
end;
