

%%
function [fldStableTmr, setFldTmr] = FieldSweep(ppms,vna,BFields,varargin)
% field sweep
%
% Parameters:
%   ppms: the PPMS object
%   vna: the E5071C object
%   BFields: Magnetic fields to sweep, in ***GAUSS***!!! (1 gauss = 0.1 mT)
%   varargin: optional input arguments, see inputParser below for detail
%
% Returns:
%   Two timer object tempStableTmr and setTempTmr.
% 
%   Sweep results will be automatically saved.
%   You can also find parameters and sweep results in
%   fldStableTmr.UserData and setFldTmr.UserData
%   It's better to delete and clear the timer object since they'll remained
%   in the memory:
%         delete(fldStableTmr);
%         delete(setFldTmr);
%         clear fldStableTmr;
%         clear setFldTmr;
%
% ATTENTION: the waiting process (for the field to be stable) is 
% going in the background, when you can do stuff in the command line at
% the same time. HOWEVER, the vna sweep is not and the command line 
% won't react during the vna sweep.
%
% In development (May 16, 2017)
% 
% Wentao, May 2017
%

p = inputParser;
p.addParameter('vnaMode','plotTrace',@ischar);      % fetchTrace will directly fetch vna trace.
                                                    % Else, the E5071C/manualSweep method is called
p.addParameter('checkFldPeriod',5,@isnumeric);
p.addParameter('fldWaitMode','StableDriven',@ischar);    % another option is 'Near'
p.addParameter('manualSweepConfig',struct([]),@isstruct);   % parameters for the E5071C/manualSweep method as a structure

p.parse(varargin{:});
expandStructure(p.Results);

if strcmpi(vnaMode, 'plotTrace')
    freqs = vna.freqs;
    waitTime = vna.sweepTime;
else
    [freqs,waitTime] = vna.manualSweepFreqs(manualSweepConfig);
end
fldStableTmr = timer;
setFldTmr = timer;
set(fldStableTmr,'ExecutionMode','fixedRate');
set(fldStableTmr,'period',checkFldPeriod);    % check field stable period
set(fldStableTmr,'TimerFcn',@timerCalled);
set(fldStableTmr,'userdata',struct('ppms',ppms,'numOfFlds',length(BFields),...
                            'manualSweepConfig',manualSweepConfig,...
                            'fldWaitMode',fldWaitMode,...
                            'vnaMode',vnaMode,...
                            'freqs',freqs,...
                            'timeStamps',NaN(1,length(BFields)),...
                            'actualFields',NaN(1,length(BFields)),...
                            'vna',vna,'t',setFldTmr,'waitTime',waitTime,...
                            'cnt',1,'SParams',NaN(length(BFields),length(freqs)) ) );

set(setFldTmr,'userdata',struct('ppms',ppms,'t',fldStableTmr,...
                                'BFields',BFields,'cnt',1) );
set(setFldTmr,'TimerFcn',@setFldTimerCalled);

start(setFldTmr);
end

%%
function timerCalled(thisObj,event)
ud = thisObj.UserData;
expandStructure(ud);
stat = char(ToString(ppms.fieldStatus));
if strcmpi(stat, fldWaitMode)
    fprintf('Field %s, start vna averaging (%.2fs)...\n',...
            fldWaitMode,waitTime+0.1)
    
    % vna sweep
    if strcmpi(vnaMode, 'plotTrace')
        vna.clearAvg;
        pause(waitTime+0.1);
        trace = vna.trace;
    else
        [~,trace] = vna.manualSweep(manualSweepConfig);
    end
    fprintf('vna trace fetched.\n');
    
    % save SParams back into timer
    ud.actualFields(cnt) = ppms.field;
    ud.timeStamps(cnt) = now;
    ud.SParams(cnt,:) = trace.X(:)' + 1i*trace.Y(:)';
    ud.cnt = cnt + 1;
    thisObj.UserData = ud;
    stop(thisObj);
    fprintf('Field timer stopped at %s.\n', datestr(now,30))
    if ud.cnt <= numOfFlds
        fprintf('\n');
        start(t);
    else
        fprintf('Field sweep finished at %s\n',datestr(now,30));
        % save data
        expandStructure(ud);
        ud2 = t.UserData;
        setFields = ud2.BFields;
        actualFields = ud.actualFields;
        timeStamps = ud.timeStamps;
        startF = min(ud.freqs);
        stopF = max(ud.freqs);
        pow = vna.power;
        config = vna.getConfig;
        minB = min(setFields);
        maxB = max(setFields);
        fname = sprintf('FieldSweep_start_%.4fGHz_stop_%.4fGHz_pow_%.1fdBm_minB_%.0fG_maxB_%.0fG_numB_%d_%s.mat',...
            startF/1e9,stopF/1e9,pow,minB,maxB,length(setFields),datestr(now,30));
        save(fname,'SParams','waitTime','setFields','actualFields',...
            'freqs','config','timeStamps','manualSweepConfig');
        fprintf('%s saved.\n',fname);
    end
else
    fprintf('Field is %s, Waiting for field to be %s...\n',...
        stat,fldWaitMode)
end

end

%%
function setFldTimerCalled(thisObj,event)
ud = thisObj.UserData;
expandStructure(ud);
fld = BFields(cnt);
fprintf('Set ppms field to %.4f Gauss, %s\n',fld,datestr(now,30));
ppms.setField(fld,'fieldApproach','Linear','fieldRate',50);
ud.cnt = cnt+1;
thisObj.UserData = ud;
pause(0.5);
start(t);

end