function [ax, bx, ay, by]=fwhm(globalmean,maxx,maxx_pos,maxy,maxy_pos,xlmin,xlmax,ylmin,ylmax,loutx,louty,data)
    
ay=1;
leftside=double(maxy);

while leftside>globalmean+(maxy-globalmean)/2 && leftside>globalmean && maxy_pos-ay>ylmin
    leftside=data(maxy_pos-ay,loutx);
    ay=ay+1;
end

by=1;
rightside=maxy;
while rightside>globalmean+(maxy-globalmean)/2 && rightside>globalmean && maxy_pos+by<ylmax
	rightside=data(maxy_pos+by,loutx);
    by=by+1;
end
    
ax=1;
leftside=maxx;
while leftside>globalmean+(maxx-globalmean)/2 && leftside>globalmean && maxx_pos-ax>xlmin
	leftside=data(louty,maxx_pos-ax);
	ax=ax+1;
end

bx=1;
rightside=maxx;
while rightside>globalmean+(maxx-globalmean)/2 && rightside>globalmean && maxx_pos+bx<xlmax
	rightside=data(louty,maxx_pos+bx);
	bx=bx+1;
end 

end