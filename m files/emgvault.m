function o1 = emgvault (opt, p1, p2)
% Implements undo/redo, changing channels, and swapping annotations.

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net

global SETS DECOMP CURR VAULT EMG

maxUndo = 10;

switch lower(opt);
    
    case 'init'
        UNDO = struct ('command', {}, 'state', {});
        REDO = struct ('command', {}, 'state', {});
        VAULT = struct ('undo', UNDO, 'redo', REDO, 'chan', 0, 'mark', 0);
        emgvault ('init annotation');
        
    case 'init annotation'
        CHAN = struct ('decomp', DECOMP, 'currunit', 0, 'closeup', SETS.closeup);
        for i=1:EMG.nchannels;
            CHAN(i,1) = CHAN(1,1);
            CHAN(i,2) = CHAN(1,1);
        end;
        VAULT.chan = CHAN;
        
    case 'mark'
        VAULT.mark = struct ('decomp', DECOMP, ...
            'curr', CURR, 'sets', SETS, 'chan', VAULT.chan);
        
    case 'remember'
        UNDO = VAULT.undo;
        if length(UNDO)>=maxUndo
            UNDO = UNDO(2:(length(UNDO)));
        end;
        l = length(UNDO)+1;
        UNDO(l).command = p1;
        if nargin==2;
            UNDO(l).state = struct('decomp', DECOMP, ...
                'curr', CURR, 'sets', SETS, 'chan', VAULT.chan);
        else
            UNDO(l).state = VAULT.mark;
        end;
        VAULT.redo = struct ('command', {}, 'state', {});
        VAULT.undo = UNDO;
       
    case 'undo'
        UNDO = VAULT.undo;
        REDO = VAULT.redo;
        if isempty(UNDO); return; end;
        if length(REDO)>=maxUndo
            REDO=REDO(2:(length(REDO)));
        end;
        l = length(REDO) + 1;
        lu = length(UNDO);
        REDO(l).command = UNDO(lu).command;
        REDO(l).state = struct('decomp', DECOMP, ...
            'curr', CURR, 'sets', SETS, 'chan', VAULT.chan);
        state = UNDO(lu).state;
        DECOMP = state.decomp;
        CURR   = state.curr;
        SETS   = state.sets;
        VAULT.chan   = state.chan;
        VAULT.undo = UNDO(1:lu-1);
        VAULT.redo = REDO;
        
    case 'redo'
        REDO = VAULT.redo;
        UNDO = VAULT.undo;
        if isempty(REDO); return; end;
         if length(UNDO) >= maxUndo
            UNDO = UNDO(2:(length(UNDO)));
        end;
        l =length(UNDO) + 1;
        lr = length(REDO);
        UNDO(l).command = REDO(lr).command;
        UNDO(l).state = struct ('decomp', DECOMP, ...
            'curr', CURR, 'sets', SETS, 'chan', VAULT.chan);
        state = REDO(lr).state;
        DECOMP = state.decomp;
        CURR   = state.curr;
        SETS   = state.sets;
        VAULT.chan   = state.chan;
        VAULT.redo = REDO (1:lr-1);
        VAULT.undo = UNDO;
       
    case 'channel'
        currcomp = CURR.compare;
        emgcompare ('compare', 0);
        VAULT.chan(CURR.chan, CURR.swap+1).decomp = DECOMP;
        VAULT.chan(CURR.chan, CURR.swap+1).currunit = CURR.unit;
        VAULT.chan(CURR.chan, CURR.swap+1).closeup = SETS.closeup;
        CURR.chan = p1;
        v = VAULT.chan(CURR.chan, CURR.swap+1);
        DECOMP = v.decomp;
        CURR.unit = v.currunit;
        SETS.closeup = v.closeup;
        emgcompare ('compare', currcomp);
        CURR.annot_file = VAULT.chan(CURR.chan,1).decomp.file;
        if size(VAULT.chan,2)>1;
            CURR.compare_file = VAULT.chan(CURR.chan,2).decomp.file;
        end;

        
    case 'swap'
 %       if isempty(CURR.compare_file);
 %           return;
 %       end;
        currcomp = CURR.compare;
        currunit = CURR.unit;
        emgcompare ('compare', 0);
        VAULT.chan(CURR.chan, CURR.swap+1).decomp = DECOMP;
        VAULT.chan(CURR.chan, CURR.swap+1).currunit = CURR.unit;
        VAULT.chan(CURR.chan, CURR.swap+1).closeup = SETS.closeup;
        CURR.swap = p1;
        v = VAULT.chan(CURR.chan, CURR.swap+1);
        DECOMP = v.decomp;
        CURR.unit = 0;
        if currunit>0;
            try
            i = find([DECOMP.unit(:).map]==currunit);
            if ~isempty(i);
                CURR.unit = i;
            end;
            end;
        end            
        SETS.closeup = v.closeup;
        emgunit ('filter');
        emgcompare ('compare', currcomp);
        
    case 'swap?'
        
        
        
    end;


    
 