function xy = smithS21Inverse(X, XData)
% 
% X(1): D
% X(2): phi
% X(3): f0
% X(4): Delta f
% returns x & y in xy: xy(:,1) are all x, xy(:,2) are all y
% 
XDataReg = 2*(XData - X(3))/X(4);
D = X(1);
phi = X(2);

x = 1 + D*( cos(phi)./(1 + XDataReg.^2) + sin(phi)*XDataReg./(1 + XDataReg.^2) );
y = D*( sin(phi)./(1 + XDataReg.^2) - cos(phi)*XDataReg./(1 + XDataReg.^2) );
xy = [x(:),y(:)];
end