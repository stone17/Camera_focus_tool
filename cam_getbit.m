function [bit]=cam_getbit(bitclass)
b=length(bitclass);
    if strcmp(bitclass(b),'8')
        bit=256;
    elseif strcmp(bitclass(b),'2')
        if strcmp(bitclass(end-1),'1')
            bit=4096;
        else
             bit=2^(16);
        end
    elseif strcmp(bitclass(b),'6')
        bit=65536;
    else
        bit=256;
    end

end