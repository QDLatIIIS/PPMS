classdef PPMS < handle
    % PPMS describe and control QDInstrument DynaCool at IIIS via QDInstrument.dll,
    % which is much faster than using dll created from LabVIEW.
    %
    % Calling dll created from LabVIEW is slow and generates new client
    % at each function call, which is very bad and troublesome. This
    % version of PPMS avoided the above two problems.
    %
    % EXAMPLES (assuming instance named 'ppms'):
    %
    % Initialization:
    %   ppms = PPMS;
    %   ppms = PPMS('address','101.6.98.151','isremote',true,'dllfilepath','C:\Users\IIIS\Documents\MATLAB\PPMS\QDInstrument.dll');
    % Get temperature value and status:
    %   temp = ppms.temp;
    %   stat = ppms.tempStatus;     % This returns a .NET object, use
    %                               % char(stat.ToString) to get the
    %                               % string, or directly use char(ToString(ppms.fieldStatus))
    %   statStr = ppms.tempStatusStr;   % Directly get the temperature
    %                                   % status string
    % Get field value and status:
    %   fld = ppms.field;
    %   stat = ppms.fieldStatus;    % See notes for ppms.tempStatus above
    %   statStr = ppms.fieldStatusStr;  % Directly get the field
    %                                   % status string
    %
    % Set temperature:
    %   ppms.setTemp(4);
    %   ppms.setTemp(2,'tempRate',5,'tempApproach','NoOvershoot');
    %   ppms.setTemp(300,'tempRate',20,'tempApproach','FastSettle');
    %
    % Set field, field strength in Gauss (Oe):
    %   ppms.setField(0,'fieldRate',50,'fieldApproach','Linear');
    %   ppms.setField(200,'fieldRate',100);
    %   ppms.setField(500,'fieldMode','Persistent');
    % 
    % See Constant properties for available options for 'tempApproach',
    % 'fieldApproach', and 'fieldMode'
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ATTENTION: 
    %   1. Setting 'fieldMode' to 'Persistent' etc. is not working as
    %       expected.
    %   2. Sometimes you might need to manually load the dll file using NET.addAssembly(dllfilepath)
    %       e.g.:  NET.addAssembly('C:\Users\IIIS\Documents\MATLAB\PPMS\QDInstrument.dll');
    %       when you first started MATLAB, try initializing ppms and also try
    %       calling QuantumDesign.QDInstrument.QDInstrumentType.DynaCool
    %       etc. for multiple times until it works. It will work when
    %       auto-completion (by using TAB button) works.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % In development (May 12, 2017)
    % Testing (May 13, 2017)
    % Add get status in string format (May 14, 2017)
    % TODO:
    %   add method for chamber
    % Wentao, May 2017
    %

properties (Constant)
    % the second argument (numeric arrays) of these Constants is of no use
    % the containers.Map is used for utilizing the isKey method, see
    % the prirvate methods for parameter verification.
    INSTR_TYPE = containers.Map({'PPMS','VersaLab','DynaCool','SVSM'},[0,1,2,3]);
    
    TEMP_APPROACH = containers.Map({'FastSettle','NoOvershoot'},[0,1]);
    
    FIELD_APPROACH = containers.Map({'Linear','NoOvershoot','Oscillate'},...
                        [0,1,2]);
    FIELD_MODE = containers.Map({'Persistent','Driven'},[0,1]);
    
end

properties
    dllfilepath
    address
    isremote
    instrType
    
    QDInstr
    vi
    
    temp
    field
    tempStatus
    fieldStatus
    
    tempApproach
    tempRate
    fieldMode
    fieldRate
    fieldApproach
end

methods
    function obj = PPMS(varargin)
        % initialize PPMS
        p = inputParser;
        p.addParameter('address','101.6.98.151',@ischar);       % ip address of PPMS computer
        p.addParameter('dllfilepath','C:\Users\IIIS\Documents\MATLAB\PPMS\QDInstrument.dll',@ischar);
        p.addParameter('isremote',true,@islogical);             % is remote (is MATLAB and MultiVu on different computer)
        p.addParameter('instrType','DynaCool',@checkInstrType); % instrument type
        
        p.parse(varargin{:})
        expandStructure(p.Results);
        
        
        obj.address = address;
        obj.dllfilepath = dllfilepath;
        obj.isremote = isremote;
        obj.instrType = instrType;
        obj.tempApproach = 'Unknown';
        obj.fieldMode = 'Unknown';
        obj.fieldApproach = 'Unknown';
        obj.tempRate = NaN;
        obj.fieldRate = NaN;
        
        obj.QDInstr = NET.addAssembly(dllfilepath);
        pause(1);
        obj.tempStatus = QuantumDesign.QDInstrument.TemperatureStatus.TemperatureUnknown;
        obj.fieldStatus = QuantumDesign.QDInstrument.FieldStatus.MagnetUnknown;
        
        % initialize .NET object which is the vi for the ppms
        obj.vi = QuantumDesign.QDInstrument.QDInstrumentFactory.GetQDInstrument(...
                            QuantumDesign.QDInstrument.QDInstrumentType.(instrType),...
                            isremote,address,uint16(11000) );
        fprintf('PPMS %s at %s connected.\n',obj.instrType, obj.address);
        
        
    end
    
    %% set & get temperature
    function value = get.temp(obj)
        [~, value, obj.tempStatus] = GetTemperature(obj.vi, double(0), obj.tempStatus);
    end
    function value = get.tempStatus(obj)
        [~, obj.temp, value] = GetTemperature(obj.vi, double(0), obj.tempStatus);
    end
    function str = tempStatusStr(obj)
        str = char(ToString(obj.tempStatus));
    end
    
    function setTemp(obj,varargin)
        p = inputParser;
        p.addRequired('temperature');
        p.addParameter('tempRate',10,@isnumeric);
        p.addParameter('tempApproach','FastSettle',@obj.checkTempApproach);
        p.parse(varargin{:});
        expandStructure(p.Results);
        
        obj.tempApproach = tempApproach;
        obj.tempRate = tempRate;
        
        SetTemperature(obj.vi, double(temperature),double(tempRate),...
                        QuantumDesign.QDInstrument.TemperatureApproach.(tempApproach));     
        
        
    end
    
    
    %% set & get field
    function value = get.field(obj)
        [~, value, obj.fieldStatus] = GetField(obj.vi, 0, obj.fieldStatus);
    end
    function value = get.fieldStatus(obj)
        [~, obj.field, value] = GetField(obj.vi, 0, obj.fieldStatus);
    end
    function str = fieldStatusStr(obj)
        str = char(ToString(obj.fieldStatus));
    end
    
    function setField(obj,varargin)
        p = inputParser;
        p.addRequired('b_field');
        p.addParameter('fieldRate',100,@isnumeric);
        p.addParameter('fieldMode','Driven',@obj.checkFieldMode)
        p.addParameter('fieldApproach','Linear',@obj.checkFieldApproach);
        p.parse(varargin{:});
        expandStructure(p.Results);
        
        obj.fieldMode = fieldMode;
        obj.fieldRate = fieldRate;
        obj.fieldApproach = fieldApproach;
        
        SetField(obj.vi, double(b_field),double(fieldRate),...
                        QuantumDesign.QDInstrument.FieldApproach.(fieldApproach),...
                        QuantumDesign.QDInstrument.FieldMode.(fieldMode));         
        
    end
    
    %% TODO: add set & get chamber (not so necessary since we have remote desktop)
    
    %% quick methods
    function warmup(obj)
        obj.setField(0);
        obj.setTemp(300,'tempRate',20);
    end
    
    
end

methods(Access = private)
    % methods for checking string input validity
    function passed = checkInstrType(obj, instrType)
        passed = isKey(obj.INSTR_TYPE, instrType);
    end

    function passed = checkTempApproach(obj, tempMode)
        passed = isKey(obj.TEMP_APPROACH,tempMode);
    end
    
    function passed = checkFieldMode(obj, fieldMode)
        passed = isKey(obj.FIELD_MODE,fieldMode);
    end
    function passed = checkFieldApproach(obj, fieldApproach)
        passed = isKey(obj.FIELD_APPROACH,fieldApproach);
    end
end



end