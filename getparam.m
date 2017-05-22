function vals = getparam(fn,varargin)
% get parameter values from file name
%   fn: file name to parse
%   varargin: parameter names
%   Example: vals = getparam('CENTER_11.3G_SPAN_10M.CSV', 'CENTER_', 'SPAN_')
%       then vals = [11.3, 10];
%
%   notes added by Wentao, 04/24/2017

vals = [];
for k = 1:length(varargin)
    vals(end+1) = sscanf(fn(findstr(fn,varargin{k}):end), [ varargin{k} '%f']);
end
end