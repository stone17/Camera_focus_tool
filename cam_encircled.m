function [strehl,peakI]=cam_encircled(X,calibration,xmax,ymax,fwhm,laserE,laserT)

%X=double(data);
meanX=mean(mean(X));
[lengthY, lengthX]=size(X);
%X(520:670,550:660)=1;
bound=50;
limits=round(bound/calibration);
ylmin=ymax-limits;
ylmax=ymax+limits;
xlmin=xmax-limits;
xlmax=xmax+limits;

if ylmin<1
    ylmin=1;
end
if xlmin<1
    xlmin=1;
end
if ylmax>lengthY
    ylmax=lengthY;
    
end
if xlmax>lengthX
    xlmax=lengthX;
    
end

%X=X(ylmin:ylmax,xlmin:xlmax);
%xmax=limits+1;
%ymax=limits+1;


X=X-meanX;
X(X<0)=0;


radius=3;

[lengthY, lengthX]=size(X);
area=zeros(lengthY*lengthX,2);
index=0;
for x=1:lengthX
    for y=1:lengthY
        index=index+1;
        area(index,1)=X(y,x);   %pixel value
        area(index,2)=round((sqrt((x-xmax)^2+(y-ymax)^2))/radius)+1; %distance of pixel to maximum
    end
end

maxrad=max(area:2);  %maximum distance in units of radius
A=zeros(maxrad,3);
for a=1:length(area)
    rad=area(a,2);
    A(rad,1)=rad*calibration*3;    %distance in units of radius
    A(rad,2)=A(rad,2)+area(a,1);    %sum of pixel values for specific distance
    A(rad,3)=A(rad,3)+1;            %number of pixel with specific distance
end
total=sum(A(:,2));
for a=1:length(A)
    relative(a,1)=A(a,1)^2*pi;      %area for sepcific distance
    relative(a,2)=A(a,1);            %distance to center
    if a==1
        relative(a,3)=A(a,2)/total;
    else
        relative(a,3)=relative(a-1,3)+A(a,2)/total; %intensity in area
    end
end

%{
shading(gca,'interp')
figure
semilogy(A(:,1),A(:,2)./A(:,3))
figure
plot(relative(:,2),relative(:,3))
%}

maxX=max(max(X));
sumF=sum(sum(X));
strehl=round(relative(sqrt((relative(:,2)-fwhm).^2)==min(sqrt((relative(:,2)-fwhm).^2)),3)*1000)/10;
peakI=(laserE/sumF*maxX)/(laserT*1e-15*(calibration*1e-4)^2);
if isempty(strehl)
    strehl=0;
    peakI=0;
end
clear A relative area X
end