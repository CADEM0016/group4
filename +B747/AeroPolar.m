classdef AeroPolar
    %AEROPOLAR Class to estimate the drag coeefficent of a B747-8F like
    %aircraft during flight
    properties
        Beta
        e
        CD0
        CDmin
        CLmin % Cl at min drag
    end

    methods
        function obj = AeroPolar(ADP)
            % CD0 estimate
            % Using the value from ADP instead of hardcoding
            obj.CD0 = ADP.CD0; 

            % calc AR
            AR = ADP.Span^2/ADP.WingArea;

            % calc induced factor
            % Updated for large widebody
            obj.e = ADP.e; 
            obj.Beta = 1/(pi*AR*obj.e);            
        end

        function CD = CD(obj,CL)
            % calc CD for a given CL
            CD = obj.CD0 + obj.Beta*CL.^2;
        end
    end
end
