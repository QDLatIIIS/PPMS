% measure S parameter using vna, for testing. Already implemented as a method of E5071C.
%% clear
% Make sure if you want to do this or not
clear all;
close all;
vna = E5071C();

%% parameters
% sweep parameters
startfreq = 1e9;

stopfreq = 8e9;
resolution = 1e5;

freqSectionSpan = resolution * vna.MAX_POINTS;
freqSectionSpan = 1e6 * round(freqSectionSpan/1e6);
numOfSections = ceil((stopfreq - startfreq)/freqSectionSpan);
stopfreq = startfreq + numOfSections * freqSectionSpan;


% freqSectionSpan = 0.5e9;
% numOfSections = 14;
numOfAvg = 1;
% stopfreq =  startfreq + numOfSections * freqSectionSpan;

% vna parameters
ifbw = 100;
power = -10;
numOfPoints = vna.MAX_POINTS;     % numOfPoints per section
totalPoints = numOfPoints * numOfSections;

%% initialize
allfreqs = NaN(1, totalPoints);
alltrace.X = allfreqs;
alltrace.Y = allfreqs;

%% apply parameters
vna.ifbw = ifbw;
vna.power = power;
vna.numOfPoints = numOfPoints;
vna.freqSpan = freqSectionSpan;

sweepTime = vna.sweepTime;
waitTime = ceil(numOfAvg * sweepTime) + 1;

%% sweep
figure(233);
fprintf('\tsweep from %.2fGHz to %.2fGHz, %d sections, %ds per section\n\ttotal points: %d, total time: %ds.\n',...
    startfreq/1e9,stopfreq/1e9, numOfSections,waitTime,totalPoints, waitTime * numOfSections);
for i = 1:numOfSections
    vna.freqCenter = startfreq + freqSectionSpan/2 +  freqSectionSpan* (i-1);
    fprintf('sweeping %.2fGHz to %.2fGHz...\n',vna.freqStart/1e9,vna.freqStop/1e9);
    pause(waitTime);
    trace = vna.trace;
    freqs = vna.freqs;
%     str = vna.plotTrace;
%     sprintf(str)
    allfreqs((1 + (i-1)*numOfPoints):(i*numOfPoints)) = freqs;
    alltrace.X((1 + (i-1)*numOfPoints):(i*numOfPoints)) = trace.X';
    alltrace.Y((1 + (i-1)*numOfPoints):(i*numOfPoints)) = trace.Y';
    figure(233);
    plot(allfreqs/1e9, 20*log10(abs(alltrace.X + 1i*alltrace.Y)));
end
fprintf('Finished!\n');
%% plot
str = ['start_' num2str(startfreq/1e9)...
    'GHz_stop_'  num2str(stopfreq/1e9)...
    'GHz_pow_' num2str(power)...
    'dBm_AVGSET_' num2str(vna.avg)];
figure(233);
xlabel freq/GHz
ylabel SParameter/dB
title(str,'interpreter','none')
save([str '.mat'],'allfreqs','alltrace','str');


