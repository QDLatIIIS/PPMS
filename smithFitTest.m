% smith fit test

S21 = trace.X +1i*trace.Y;
avgS21 = (S21(1) + S21(end))/2;

S21tilde = S21/avgS21;

% figure;
% plot(1./S21tilde);
% xlabel('Re[S_{21}^{-1}]');
% ylabel('Im[S_{21}^{-1}]');

S21tildeInv = 1./S21tilde;
x0guess = (max(real(S21tildeInv)) + min(real(S21tildeInv)) )/2;
y0guess = (max(imag(S21tildeInv)) + min(imag(S21tildeInv)) )/2;
rguess = (max(real(S21tildeInv)) - min(real(S21tildeInv)))/2;
phiguess = atan(y0guess/(x0guess-1));

%% guess initial parameters
xlow = 1 + 2*rguess*cos(phiguess - pi/2);
ylow = 2*rguess*sin(phiguess - pi/2);
devS21Inv = abs(S21tildeInv - xlow - 1i*ylow);
flowInd = find(devS21Inv<=min(devS21Inv),1);
flow = freqs(flowInd);

xhigh = 1 + 2*rguess*cos(phiguess + pi/2);
yhigh = 2*rguess*sin(phiguess + pi/2);
devS21Inv = abs(S21tildeInv - xhigh - 1i*yhigh);
fhighInd = find(devS21Inv<=min(devS21Inv),1);
fhigh = freqs(fhighInd);

X = [2*rguess,...       % X(1): D
    phiguess,...        % X(2): phi
    (flow+fhigh)/2,...  % X(3): f0
    abs(flow - fhigh)   % X(4): Delta f
    ];
%% fit
opt=optimset('MaxIter',10000,'MaxFunEvals',10000,'tolx',1e-16,'tolf',1e-9);
tmp_X = X;
for ii = 1:5
    [X_fit,resnorm,~,exitflag,output] = lsqcurvefit(@(x1,x2)smithS21Inverse(x1,x2),tmp_X,freqs(:),[real(S21tildeInv(:)),imag(S21tildeInv(:))],[],[],opt);
    tmp_X = X_fit;
end
xy = smithS21Inverse(X_fit,freqs);
Qi = X_fit(3)/X_fit(4);
QcStar = Qi/X_fit(1);
fprintf('Qi =  %d\nQc* = %d\n', Qi, QcStar);

%% plot results
figure
hold all
plot(S21tildeInv);
plot(xy(:,1)+1i*xy(:,2))
xlabel('Re[S_{21}^{-1}]');
ylabel('Im[S_{21}^{-1}]');
title(sprintf('f_0=%.3fGHz Qi=%.0f Qc*=%.0f',X_fit(3)/1e9, Qi, QcStar));
hold off
saveas(gcf,sprintf('SmithFit_f_0=%.3fGHz_Qi_%.0f_QcStar_%.0f.png',X_fit(3)/1e9, Qi, QcStar))

S21fit = avgS21./(xy(:,1)+1i*xy(:,2));


figure
hold all
plot(freqs, 20*log10(abs(S21)));
plot(freqs, 20*log10(abs(S21fit)));
xlabel frequency/GHz
ylabel S21/dB
title(sprintf('f_0=%.3fGHz Qi=%.0f Qc*=%.0f',X_fit(3)/1e9, Qi, QcStar));
saveas(gcf,sprintf('SmithFitAmp_f_0=%.3fGHz_Qi_%.0f_QcStar_%.0f.png',X_fit(3)/1e9, Qi, QcStar))
hold off

