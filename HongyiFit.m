function [ f_r,Q_i,Q_c,Q_l ] = HongyiFit( t0,y0,x0,doplot,tmp_name )
%HONGYIFIT 此处显示有关此函数的摘要
%   此处显示详细说明

if nargin<5
    tmp_name='';
end

% t0=data(6:end,1);
% y0=10.^(data(6:end,2)./20)*100;
% y0=data(:,2);
% define the initial fitting value
% x0 = [center frequencey, loaded Q, coupling Q, theta, alpha, A].


x1=x0;

t=t0(:);
y=y0(:);



% fit with complex S21 deduced theoretically
% 8 parameter, linear base
%         F = @(x,xdata)(20.*log10(abs(x(6).*(1+x(5).*(xdata-x(1).*1e9)./(x(1).*1e9)).*(1-(x(2).^2.*1e4.*x(3).^2.*1e4./cos(x(4)))./(x(2).^2.*1e4 + x(3).^2.*1e4./cos(x(4)))./(x(3).^2.*1e4).*(cos(x(4))+1i.*sin(x(4)))./(1+2.*1i.*(x(2).^2.*1e4.*x(3).^2.*1e4./cos(x(4)))./(x(2).^2.*1e4 + x(3).^2.*1e4./cos(x(4))).*(xdata-x(1).*1e9)./(x(1).*1e9)))))+x(7).*xdata.*1e-9+x(8));
% 7 parameter, constant base
F = @(x,xdata)(abs(x(6).*(1+x(5).*(xdata-x(1).*1e9)./(x(1).*1e9)).*(1-(x(2).^2.*1e4.*x(3).^2.*1e4./cos(x(4)))./(x(2).^2.*1e4 + x(3).^2.*1e4./cos(x(4)))./(x(3).^2.*1e4).*(cos(x(4))+1i.*sin(x(4)))./(1+2.*1i.*(x(2).^2.*1e4.*x(3).^2.*1e4./cos(x(4)))./(x(2).^2.*1e4 + x(3).^2.*1e4./cos(x(4))).*(xdata-x(1).*1e9)./(x(1).*1e9)))));
%x(1): f, center frequency, in GHz
%x(2): Qi, intrinsic Q, Ql = Qi*Qc/(Qi + Qc) =  (x(2).*x(3)./cos(x(4)))./(x(2) + x(3)./cos(x(4))), in 1e4
%x(3): |Qe|, parameter Q, 1/Qc = Re (1/Qe) = cos(theta)/Qe, in 1e4
%x(4): theta, phase of parameter Q
%x(5): alpha
%x(6): amplitude A
    

for loop_fit=1:5
    %%
    opt=optimset('MaxIter',10000,'MaxFunEvals',10000,'tolx',1e-16,'tolf',1e-9);
    [x_fit1,resnorm,~,exitflag,output] = lsqcurvefit(F,x1,t,y,[],[],opt);
    x1=x_fit1;
    if ((x1(4)>pi/2)|(x1(4)<-pi/2))
        tmp = floor(abs(x1(4))./(pi/2));
        if x1(4)>0
            x1(4)=x1(4)-tmp.*pi/2;
        end
        if x1(4)<0
            x1(4)=x1(4)+tmp.*pi/2;
        end
    end
end

f_r = x1(1)*1e9; % center frequency, in Hz
Q_i = x1(2).^2.*1e4; % interal Q
Q_c = x1(3).^2./cos(x1(4)).*1e4;  % coupled Q
Q_l = Q_i.*Q_c./(Q_i + Q_c);  % loaded Q



%
%      Fsumsquares = @(x)sum((F(x,t) - y).^2);
%     opts = optimoptions('fminunc','Algorithm','quasi-newton');
%     [x_fit1,ressquared,eflag,outputu] = fminunc(Fsumsquares,x0,opts);


if doplot
    figure_handle=figure('unit','normalized','outerposition',[0 0 1 1]);% plot full screen
    set(figure_handle,'PaperPositionMode','auto');  % make the saveas save the on-screen figure
    hold on;
    subplot(2,1,1)
    plot(t/1E9,20*log10(y),'.',t/1E9,20*log10(F(x_fit1,t)),'LineWidth',2);
    xlabel('probe tone(GHz)','FontSize',18);
    ylabel('S21/dB','FontSize',18);
    f_text=['f_r = '];
    f_text=[f_text num2str(f_r/1e9)];
    f_text=[f_text 'GHz'];
    Ql_text=['Q_l = ' num2str(round(Q_l))];
    Qi_text=['Q_i = ' num2str(round(Q_i))];
    Qc_text=['Q_c = ' num2str(round(Q_c))];
    text_pos=[(max(20*log10(y))-min(20*log10(y)))/4+min(20*log10(y)),min(20*log10(y))];
    text(t(1)/1E9,text_pos(1),f_text,'FontSize',18);
    text(t(1)/1E9,text_pos(2),Ql_text,'FontSize',18);
    text(t(round(end/1.5))/1E9,text_pos(1),Qi_text,'FontSize',18);
    text(t(round(end/1.5))/1E9,text_pos(2),Qc_text,'FontSize',18);

    title(tmp_name,'fontsize',20,'Interpreter','none');
    
    if isempty(tmp_name)
        tmp_name = [f_text ' ' Qi_text ' ' Qc_text];
    end
    
    subplot(2,1,2)
    plot(t/1E9,y-F(x_fit1,t));
    xlabel('probe tone(GHz)','FontSize',18);
    ylabel('diff S21','FontSize',18);
    title('fitting residual','FontSize',14);
    hold off;
    
    imagename=[strrep(tmp_name,' ','_'),'.png'];
    saveas(figure_handle,imagename);
end


end

