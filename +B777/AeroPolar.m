classdef AeroPolar
    %AEROPOLAR Class to estimate the drag coeefficent of a B777 like
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
            %  CD0 estimate 
            %  If ADP has CD0 property (like 747), use it. otherwise use default B777
            if isprop(ADP, 'CD0') && ~isempty(ADP.CD0)
                obj.CD0 = ADP.CD0;
            else
                obj.CD0 = 0.019; % Default B777 fallback
            end

            % calc AR
            AR = ADP.Span^2/ADP.WingArea;

            % calc induced factor
            if isprop(ADP, 'e') && ~isempty(ADP.e)
                obj.e = ADP.e;
            else
                Q = 1.05; P = 0.007;
                obj.e = 1/(Q+P*pi*AR); % Default B777 fallback
            end
            
            obj.Beta = 1/(pi*AR*obj.e);            
        end

        function CD = CD(obj,CL)
            % calc CD for a given CL
            CD = obj.CD0 + obj.Beta*CL.^2;
        end
    end
end