function timerTest()
tic
t = timer;
t2 = timer;
t.UserData = struct('waitTimes',[6 4 2 1 0.5],'t',t2);
t2.UserData = struct('waitTimes',[6 4 2 1 0.5],'t',t);
t.TimerFcn = @(varargin) timerCalled(varargin{:});
t2.TimerFcn = @(varargin) timerCalled(varargin{:});
start(t);
end


function timerCalled(thisObj, varargin)
userData = thisObj.UserData;
waitTimes = userData.waitTimes;
t = userData.t;
if ~isempty(waitTimes)
    display('Timer!');
    t.StartDelay = waitTimes(1);
    waitTimes = waitTimes(2:end);
    userData.waitTimes = waitTimes;
    thisObj.UserData = userData;
    start(t);
else
    display('Timer!');
end
end