% power Sweep using timer
% In development
%

function [t1, t2] = VNAPowerSweepWithTimer(vna, varargin)
% scan VNA power
% Parameters:
%   Required: the vna object
%   Optional: see the inputParser
%
% Returns two timer object t1 and t2.
%
% Use expandStructure(t1.UserData) to get freqs, pows & SParams, etc.
%
% Wentao, May 2017
%

p = inputParser;
p.addParameter('minPow',-40,@isnumeric);
p.addParameter('maxPow',0,@isnumeric);
p.addParameter('numOfPowers',20,@isnumeric);
p.addParameter('config',struct('ifbw',100,...
                'avg',999,...
                'numOfPoints',1000,...
                'outp',1),@isstruct);
p.addParameter('hfig',2333,@isnumeric);
p.addParameter('maxAvg',500,@isnumeric);
p.parse(varargin{:});
expandStructure(p.Results);

%% parameters
% powers
pows = linspace(maxPow,minPow,numOfPowers);
% set vna configuration   
vna.setConfig(config);

SParams = NaN(numOfPowers,vna.numOfPoints);
freqs = vna.freqs;
avgs = round(10.^(-pows/20))+1;
avgs = min(maxAvg,avgs);
waitTimes = round(vna.sweepTime * avgs)+1;
totalTime = sum(waitTimes);
fprintf('Power sweep from %.1fdBm to %.1fdBm, %d power points,\n\t %d seconds.\n',...
    minPow,maxPow,numOfPowers,totalTime);


t1 = timer;
t2 = timer;
t1.UserData = struct('t',t2,...
                    'vna',vna,...
                    'freqs',freqs,...
                    'pows',pows,...
                    'ii',1,...
                    'SParams',SParams,...
                    'hfig',hfig,...
                    'waitTimes',waitTimes);
t2.UserData = struct('t',t1,...
                    'vna',vna,...
                    'freqs',freqs,...
                    'pows',pows,...
                    'ii',1,...
                    'SParams',SParams,...
                    'hfig',hfig,...
                    'waitTimes',waitTimes);
t1.TimerFcn = @(thisObj, event) timerCalled(thisObj, event);
t2.TimerFcn = @(thisObj, event) timerCalled(thisObj, event);
%% sweep power
t1.StartDelay = waitTimes(1);
startTime = datestr(now,30);
fprintf('Start sweep at %s.\n',startTime);
ii = 1;
pow = round(100*pows(ii))/100;
vna.power = pow;
vna.clearAvg;
start(t1);
fprintf('Sweeping with power %.2fdBm for %d seconds at %s...\n',...
    pow, waitTimes(1),datestr(now,30));
% figure(hfig);
% contourf(freqs,pows,20*log10(abs(SParams)),20,'edgecolor','none');
% xlabel frequency/Hz
% ylabel power/dBm
% title(sprintf('PowerSweep_start_%.4fGHz_stop_%.4fGHz_min_%ddBm_max_%ddBm',...
%                 min(freqs)/1e9,max(freqs)/1e9,minPow,maxPow),'interpreter','none');
% str = [get(get(gca,'Title'),'String') '.png'];
% saveas(gcf,str);

end


function timerCalled(thisObj, varargin)
userData = thisObj.UserData;
expandStructure(userData);

if ii < length(pows)
    tmpTrace = vna.trace;
    SParams(ii,:) = tmpTrace.X+1i*tmpTrace.Y;
    % ATT: plot within timer's TimerFcn will cause unknown error!
%     figure(hfig);
%     contourf(freqs,pows,20*log10(abs(SParams)),20,'edgecolor','none');    
    ii = ii+1;
    pow = round(100*pows(ii))/100;
    vna.power = pow;
    waitTime = waitTimes(ii);
    t.StartDelay = waitTime;
    
    userData.SParams = SParams;
    userData.ii = ii;
    tuserData = t.UserData;
    tuserData.ii = ii;
    tuserData.SParams = SParams;
    t.UserData = tuserData;
    thisObj.UserData = userData;
    
    vna.clearAvg;
    start(t);
    fprintf('Sweeping with power %.2fdBm for %d seconds at %s...\n',...
        pow, waitTime, datestr(now,30));
else
    fprintf('Sweep finished at %s!',datestr(now,30));
end

end










