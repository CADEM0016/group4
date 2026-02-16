function UpdateAero(obj)
    % If the ADP object has a custom CD0 calculation method (e.g. 747), run it first
    if ismethod(obj, 'CalculateCD0')
        obj.CalculateCD0(); 
    end
    
    obj.AeroPolar = B777.AeroPolar(obj);
end