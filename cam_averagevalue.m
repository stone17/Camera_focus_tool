function [average_val, min_val, max_val, new_values]=cam_averagevalue(value,old_values)
try
	vals=length(old_values);
catch
	vals=0;
    old_values=0;
end
if vals<10
    new_values=old_values;
    new_values(vals+1)=value;
else
	new_values(1:9)=old_values(2:10);
    new_values(10)=value;
end
average_val=mean(new_values);
min_val=min(new_values);
max_val=max(new_values);
end
