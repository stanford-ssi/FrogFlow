classdef DataStruct < handle
  properties
    data
  end
  
  methods
    function obj = DataStruct(data)
      obj.data = data;
    end
  end
end