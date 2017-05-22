
function [tempTmr] = trackTemp(ppms, varargin)
% trackTemp tracks temperature in the background using timer tempTmr
% temperature and time stamp data will be saved automatically after temperature stable.
% 
% Parameter: ppms, the PPMS object
% Return: tempTmr, timer object. Remember to delete and clear it
%
% Wentao, May 2017
%

p = inputParser;
p.addParameter('maxNumOfTemp',5000,@isnumeric);
p.addParameter('queryPeriod',1,@isnumeric);
p.parse(varargin{:});
expandStructure(p.Results);

temps = NaN(1,maxNumOfTemp);
timeStamps = NaN(1,maxNumOfTemp);

tempTmr = timer;
set(tempTmr,'period',queryPeriod);
set(tempTmr,'ExecutionMode','fixedRate');
set(tempTmr,'UserData',struct('ppms',ppms,'temps',temps,...
                                'timeStamps',timeStamps));
set(tempTmr,'TimerFcn',@tempTmrCalled);
start(tempTmr);
fprintf('Track temperature timer started...\n');

end



function tempTmrCalled(thisObj, event)
ud = thisObj.UserData;
expandStructure(ud);
if (strcmpi(ppms.tempStatusStr, 'Stable'))
    stop(thisObj);
    fprintf('Temperature stable. Temperature Track Timer Stopped.\n');
    expandStructure(thisObj.UserData);
    fname = sprintf('TempTrack_%s_%s.mat',...
        datestr(timeStamps(1),30),...
        datestr(timeStamps(find(isnan(timeStamps),1)-1),30) );
    save(fname, 'temps','timeStamps');
    fprintf('%s saved.\n',fname);
else
    ind = find(isnan(temps),1);
    if isempty(ind)
        temps(end+1) = ppms.temp;
        timeStamps(end+1) = now;
    else
        temps(ind) = ppms.temp;
        timeStamps(ind) = now;
    end
    ud.temps = temps;
    ud.timeStamps = timeStamps;
    thisObj.UserData = ud;
end


end