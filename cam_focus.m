%function [strehl,fwhm]=focusdiagnostic(x,y,data)

%[X, map] = gray2ind(data,2^16);
       


radius=3;

[lengthY, lengthX]=size(data);

if lengthX/2>x
    limx=lengthX-x-radius;
else
    limx=x-radius;
end

if lengthY/2>y
    limy=lengthY-y-radius;
else
    limy=y-radius;
end

index1=0;
for a=1:radius:limx
    index1=index1+1;
    if a==1
        intensity(index1,1)=sum(data(y,(x-(radius-1)/2:x+(radius-1)/2)));
    else
        intensity(index1,1)=sum(data(y,(x-index1*radius-(radius-1)/2:x-index1*radius+(radius-1)/2))); %left side
        intensity(index1,1)=intensity(index1,1)+sum(data(y,(x+index1*radius-(radius-1)/2:x+index1*radius+(radius-1)/2))); %right side
    end
end

index2=0;
for b=1:radius:limy
    index2=index2+1;
    if b==1
        intensity(index2,2)=sum(data(y-(radius-1)/2:y+(radius-1)/2,x));
        intensity(index2,3)=(intensity(index2,1)+intensity(index2,2))/2;
    else
        intensity(index2,2)=sum(data(y-index2*radius-(radius-1)/2:y-index2*radius+(radius-1)/2,x));
        intensity(index2,2)=intensity(index2,2)+sum(data(y+index2*radius-(radius-1)/2:y+index2*radius+(radius-1)/2,x));
        intensity(index2,3)=(intensity(index2,1)+intensity(index2,2))/2;
    end
end