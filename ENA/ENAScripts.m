% this script save some scripts frequently used


%% plot loaded data
% assume freqs and trace are already loaded
tmpS = trace.X + 1i*trace.Y;
figure;
plot(freqs/1e9, 20*log10(abs(tmpS)))
xlabel freq/GHz
ylabel SParameter/dB
title(str,'interpreter','none')



%% save data
freqs = vna.freqs;
trace = vna.trace;
str = vna.plotTrace;
save([str '.mat'], 'freqs', 'trace', 'str');


%% fit
freqStartStop = getparam(str,'start_','stop_');
freq0 = mean(freqStartStop);    % in GHz
x0 = [freq0, 10, 10, 0, 0, 0];
[ f_r,Q_i,Q_c,Q_l ] = HongyiFit(freqs,...
                        abs(trace.X+1i*trace.Y),...
                        x0,...              initial guess
                        true,...            do save plot to file
                        ['Fit_' str]);