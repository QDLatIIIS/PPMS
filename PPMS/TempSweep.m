

%%
function [tempStableTmr, setTempTmr] = TempSweep(ppms,vna,temps,varargin)
% temperature sweep
%
% Parameters:
%   ppms: the PPMS object
%   vna: the E5071C object
%   temps: temperatures to sweep
%   varargin: optional input arguments, see inputParser below for detail
%
% Returns:
%   Two timer object tempStableTmr and setTempTmr.
% 
%   Sweep results will be automatically saved.
%   You can also find parameters and sweep results in
%   tempStableTmr.UserData and setTempTmr.UserData
%   It's better to delete and clear the timer object since they'll remained
%   in the memory:
%         delete(tempStableTmr);
%         delete(setTempTmr);
%         clear setTempTmr;
%         clear tempStableTmr;
%
% ATTENTION: the waiting process (for the temperature to be stable) is 
% going in the background, when you can do stuff in the command line at
% the same time. HOWEVER, the vna sweep is not and the command line 
% won't react during the vna sweep.
%
% In development (May 13, 2017)
% 
% TODO: 
%   Done. add input parser
%   Done. choose vna sweep mode. Change 'plotTrace' to 'fetchTrace'
%   Done. choose temperature wait mode ('Near' or 'Stable')
%   Done. fetch actual temperatures and add timeStamps;
% 
% Wentao, May 2017
%

p = inputParser;
p.addParameter('vnaMode','plotTrace',@ischar);      % fetchTrace will directly fetch vna trace.
                                                    % Else, the E5071C/manualSweep method is called
p.addParameter('checkTempPeriod',10,@isnumeric);
p.addParameter('tempWaitMode','Stable',@ischar);    % another option is 'Near'
p.addParameter('manualSweepConfig',struct([]),@isstruct);   % parameters for the E5071C/manualSweep method as a structure

p.parse(varargin{:});
expandStructure(p.Results);

if strcmpi(vnaMode, 'plotTrace')
    freqs = vna.freqs;
    waitTime = vna.sweepTime;
else
    [freqs,waitTime] = vna.manualSweepFreqs(manualSweepConfig);
end
tempStableTmr = timer;
setTempTmr = timer;
set(tempStableTmr,'ExecutionMode','fixedRate');
set(tempStableTmr,'period',checkTempPeriod);    % check temperature stable period
set(tempStableTmr,'TimerFcn',@timerCalled);
set(tempStableTmr,'userdata',struct('ppms',ppms,'numOfTemps',length(temps),...
                            'manualSweepConfig',manualSweepConfig,...
                            'tempWaitMode',tempWaitMode,...
                            'vnaMode',vnaMode,...
                            'freqs',freqs,...
                            'timeStamps',NaN(1,length(temps)),...
                            'actualTemps',NaN(1,length(temps)),...
                            'vna',vna,'t',setTempTmr,'waitTime',waitTime,...
                            'cnt',1,'SParams',NaN(length(temps),length(freqs)) ) );

set(setTempTmr,'userdata',struct('ppms',ppms,'t',tempStableTmr,'temps',temps,'cnt',1) );
set(setTempTmr,'TimerFcn',@setTempTimerCalled);

start(setTempTmr);
end

%%
function timerCalled(thisObj,event)
ud = thisObj.UserData;
expandStructure(ud);
stat = char(ToString(ppms.tempStatus));
if strcmpi(stat, tempWaitMode)
    fprintf('Temperature %s, start vna averaging (%.2fs)...\n',...
            tempWaitMode,waitTime+0.5)
    
    % vna sweep
    if strcmpi(vnaMode, 'plotTrace')
        vna.clearAvg;
        pause(waitTime+0.5);
        trace = vna.trace;
    else
        [~,trace] = vna.manualSweep(manualSweepConfig);
    end
    fprintf('vna trace fetched.\n');
    
    % save SParams back into timer
    ud.actualTemps(cnt) = ppms.temp;
    ud.timeStamps(cnt) = now;
    ud.SParams(cnt,:) = trace.X(:)' + 1i*trace.Y(:)';
    ud.cnt = cnt + 1;
    thisObj.UserData = ud;
    stop(thisObj);
    fprintf('Temperature timer stopped at %s.\n', datestr(now,30))
    if ud.cnt <= numOfTemps
        fprintf('\n');
        start(t);
    else
        fprintf('Temperature sweep finished at %s\n',datestr(now,30));
        % save data
        expandStructure(ud);
        ud2 = t.UserData;
        setTemps = ud2.temps;
        actualTemps = ud.actualTemps;
        timeStamps = ud.timeStamps;
        startF = min(ud.freqs);
        stopF = max(ud.freqs);
        pow = vna.power;
        config = vna.getConfig;
        minT = min(setTemps);
        maxT = max(setTemps);
        fname = sprintf('TempSweep_start_%.4fGHz_stop_%.4fGHz_pow_%.1fdBm_minT_%.3fK_maxT_%.3fK_numT_%d_%s.mat',...
            startF/1e9,stopF/1e9,pow,minT,maxT,length(setTemps),datestr(now,30));
        save(fname,'SParams','waitTime','setTemps','actualTemps',...
            'freqs','config','timeStamps','manualSweepConfig');
        fprintf('%s saved.\n',fname);
    end
else
    fprintf('Temperature is %s. Waiting for temperature to be %s...\n',...
        stat,tempWaitMode)
end

end

%%
function setTempTimerCalled(thisObj,event)
ud = thisObj.UserData;
expandStructure(ud);
temp = temps(cnt);
fprintf('Set ppms temperature to %.4f K, %s\n',temp,datestr(now,30));
ppms.setTemp(temp,'tempApproach','NoOvershoot','tempRate',1);
pause(0.5);
start(t);
ud.cnt = cnt+1;
thisObj.UserData = ud;

end