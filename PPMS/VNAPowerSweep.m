function [freqs, pows, SParams] = VNAPowerSweep(vna, varargin)
% scan VNA power
% Parameters:
%   Required: the vna object
%   Optional: see the inputParser

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
%powers
% numOfPowers = 20;
pows = linspace(minPow,maxPow,numOfPowers);
% vna configuration
% config = struct('ifbw',100,...
%                 'avg',999,...
%                 'numOfPoints',1000,...
%                 'outp',1);
% hfig = 2333;
            
% set config
vna.setConfig(config);

SParams = NaN(numOfPowers,vna.numOfPoints);
freqs = vna.freqs;
avgs = round(10.^(-pows/20))+1;
avgs = min(maxAvg,avgs);
totalTime = sum(round(vna.sweepTime * avgs)+1);
fprintf('Power sweep from %.1fdBm to %.1fdBm, %d power points,\n\t %d seconds.\n',...
    minPow,maxPow,numOfPowers,totalTime);
%% sweep power
startTime = datestr(now,30);
fprintf('Start sweep at %s.\n',startTime);
for ii = 1:numOfPowers
    pow = round(10*pows(ii))/10;
    vna.power = pow;
    avg = avgs(ii);    % take avg according to power
%     avg = 1;          % for testing
    waitTime = round(vna.sweepTime * avg)+1;
    fprintf('Sweeping with power %.1fdBm for %d seconds...\n',...
        pow, waitTime);
    vna.clearAvg;
    pause(waitTime);
    tmpTrace = vna.trace;
    SParams(ii,:) = tmpTrace.X+1i*tmpTrace.Y;
    figure(hfig);
    contourf(freqs,pows,20*log10(abs(SParams)),20,'edgecolor','none');
end
xlabel frequency/Hz
ylabel power/dBm
title(sprintf('PowerSweep_start_%.4fGHz_stop_%.4fGHz_min_%ddBm_max_%ddBm',...
                min(freqs)/1e9,max(freqs)/1e9,minPow,maxPow),'interpreter','none');
str = [get(get(gca,'Title'),'String') '.png'];
saveas(gcf,str);

%% finalize
vna.power = -10;
stopTime = datestr(now,30);
fprintf('Sweep finished at %s.\n',startTime);
save(sprintf('PowerSweep_start_%.4fGHz_stop_%.4fGHz_min_%ddBm_max_%ddBm.mat',...
                min(freqs)/1e9,max(freqs)/1e9,minPow,maxPow),...
    'pows','freqs','SParams','config','startTime','stopTime');

%% fit
f0s = NaN(1,numOfPowers);
Qis = f0s;
Qcs = f0s;
Qls = f0s;
for ii = 1:numOfPowers
    [ f_r,Q_i,Q_c,Q_l ] = vna.fit('fitall',true,'issavefig',false,...
                                  'xdata',freqs,'ydata',20*log10(abs(SParams(ii,:))),...
                                  'titleNotes',sprintf('_pow_%ddBm',pows(ii)) );
    f0s(ii) = f_r;
    Qis(ii) = Q_i;
    Qcs(ii) = Q_c;
    Qls(ii) = Q_l;
end
% save fit figure to png
str = ['PowerSweepFits_' get(get(gca,'Title'),'String') '.png'];
saveas(gcf,str);
fprintf(['Image ' str ' saved.\n'])

% plot f0 and Q versus power
figure;

subplot(1,2,1);
plot(pows, f0s);
xlabel powers/dBm;
ylabel f0/GHz;
title('frequency vs power');

subplot(1,2,2);
hold all;
plot(pows, Qis);
plot(pows, Qcs);
plot(pows, Qls);
xlabel powers/dBm;
ylabel Q
title('Q values vs power');
legend('Q_i','Q_c','Q_l')
hold off

saveas(gcf,sprintf('PowerSweep_freq_Q_vs_power_%s.png',datestr(now,30)) );


end











