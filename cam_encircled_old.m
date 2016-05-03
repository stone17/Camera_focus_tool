function [status]=cam_encircled(data,calibration,xmax,ymax)
status=0;
%[file,path]=uigetfile('*.tif','Load focus file');
%fullfile=[path, file];
%imfinfo(fullfile);
%focus=(imread(fullfile,'tiff'));
%[X, map] = gray2ind(focus,2^8);

X=double(data);
%imagesc(X)

X=X-mean(mean(X));

if nargin==2
rectangle=getrect;              
xrect=round(rectangle(1,1));
yrect=round(rectangle(1,2));
dx=round(rectangle(1,3));
dy=round(rectangle(1,4));
X=X(yrect:yrect+dy,xrect:xrect+dx);


%imagesc(X)
%[ymax,xmax]=find(X==max(max(X)));
%if length(xmax)>1
%    clear xmax ymax
     [xmax,ymax] = ginput(1);
%end  
end

radius=3;

gmean=mean(mean(data));

[lengthY, lengthX]=size(X);

index=0;
area=zeros(lengthX*lengthY,2);
for x=1:lengthX
    for y=1:lengthY
        index=index+1;
        if X(y,x)<0
            area(index,1)=0;
        else
            area(index,1)=X(y,x)-gmean;   %pixel value
        end
        area(index,2)=round((sqrt((x-xmax)^2+(y-ymax)^2))/radius)+1; %distance of pixel to maximum
    end
end

maxrad=max(area:2);  %maximum distance in units of radius
A=zeros(round(maxrad)+1,3);
for a=1:length(area)
    rad=area(a,2);
    A(rad,1)=rad;    %distance in units of radius
    A(rad,2)=A(rad,2)+area(a,1);    %sum of pixel values for specific distance
    A(rad,3)=A(rad,3)+1;            %number of pixel with specific distance
end
total=sum(A(:,2));
for a=1:length(A)
    relative(a,1)=A(a,1)^2*pi;      %area for sepcific distance
    relative(a,2)=A(a,1);           %distance to according area
    if a==1
        relative(a,3)=A(a,2)/total;
    else
        relative(a,3)=relative(a-1,3)+A(a,2)/total; %intensity in area
    end
end
%semilogy(A(:,1),A(:,2)./A(:,3))
mini10=sqrt((relative(:,3)-0.1).^2);
[val10,ind10]=min(mini10);
mini90=sqrt((relative(:,3)-0.9).^2);
[val90,ind90]=min(mini90);
status(1)=round(relative(ind10,2)*calibration*10)/10;
status(2)=round(relative(ind90,2)*calibration*10)/10;

if nargin==2
figure
plot(relative(:,2)*calibration,relative(:,3))
hold on
plot(relative(ind10,2)*calibration,relative(ind10,3),'o')
plot(relative(ind90,2)*calibration,relative(ind90,3),'o')
hold off
end



end
