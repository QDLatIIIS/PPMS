function [f0s, Qis, Qcs, Qls] = PowerSweepDataProc(vna)
fname = uigetfile('PowerSweep_*.mat');
load(fname);
numOfPowers = length(pows);
frequencies = freqs(:);
%% fit
f0s = NaN(1,numOfPowers);
Qis = f0s;
Qcs = f0s;
Qls = f0s;
for ii = 1:numOfPowers
    Stmp = abs(SParams(ii,:));
    Stmp = smooth(Stmp,8);
    [val, ind] = min(Stmp);
    vMax = max(Stmp);
    freqLeft = freqs(find(Stmp<(val+vMax)/2,1,'first'));
    freqRight = freqs(find(Stmp<(val+vMax)/2,1,'last'));
    QGuess = freqs(ind)/abs(freqLeft - freqRight);
    QGuess = max(QGuess, 100);
    QGuess = min(QGuess, 1e6);
    
    [ f_r,Q_i,Q_c,Q_l ] = vna.fit('fitall',true,'issavefig',false,...
                                  'QGuess',QGuess,...
                                  'xdata',frequencies/1e9,'ydata',20*log10(abs(SParams(ii,:))),...
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