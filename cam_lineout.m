function lineout(obj, event, handles, vid, camtype, pco, hImage)
global loutx louty loutstatus lims...
    peak chase vidRes loutplot...
    calibration strehl_vals fwhmr_vals fwhm_vals gmax_vals cmap marker xmarker ymarker
if camtype==1
    if getappdata(handles.vidscreen,'bit')>300
        data=swapbytes(getdata(vid,1,'native'));
    else
        data=swapbytes(getdata(vid,1,'native'));
    end
    [ySize,xSize]=size(data(:,:,1));
    flushdata(vid,'all')
elseif camtype==2
    [b, err] = getSingleFrameBasic(pco.hCam, pco.xSize, pco.ySize, pco.fp1, pco.sbn1, pco.hbuf1);
    data = reshape(b, 2560, [])';
    if err ~= 0
        err
        return
    else
    data=int32(data);
    data(data<0)=data(data<0)+2^(16);
    ySize=pco.ySize;
    xSize=pco.xSize;
    end
end

if get(handles.blackstatus,'value')==1
    try
        bdata=getappdata(handles.vidscreen,'bdata');
        data=data-bdata;
    end
end

if get(handles.fft_mode,'value')==1
    [m,n]=size(data);
    fftdata=zeros(m,2*n);
    da=zeros(m,2*n);
    fftdata=fft2(double(data));
    fftdata=abs(fftshift(fftdata));    
    da(1:m,1:n)=fftdata/(20*mean(mean(fftdata)))*getappdata(handles.vidscreen,'bit');
    %da(1:m,1:n)=log(fftdata/(mean(mean(fftdata))))/max(max(log(fftdata/(10*mean(mean(fftdata))))))*getappdata(handles.vidscreen,'bit');
    da(1:m,n+1:2*n)=double(data);%/double(max(max(data)))*10*double(mean(mean(fftdata)));
    data=da;
    [ySize,xSize]=size(data(:,:,1));
    set(handles.vidscreen,'ylim',[1 ySize]); %old axis limits
    set(handles.vidscreen,'xlim',[1 xSize]);
end

axes(handles.vidscreen);

yl=get(handles.vidscreen,'ylim'); %old axis limits
xl=get(handles.vidscreen,'xlim');

if yl(2)>ySize
    yl(2)=ySize;
end
if yl(1)<0
    yl(1)=0;
end
if yl(2)-yl(1)<0.1*ySize
    yl(2)=yl(1)+0.1*ySize;
end
if xl(2)>xSize
    xl(2)=xSize;
end
if xl(1)<0
    xl(1)=0;
end
if xl(2)-xl(1)<0.1*xSize
    xl(2)=xl(1)+0.1*xSize;
end


%data=log(double(data));
if get(handles.fft_mode,'value')==1
    imagesc(data, 'parent', handles.vidscreen)
else
    imagesc(data, 'parent', handles.vidscreen)
end

if getappdata(handles.vidscreen,'bit')>300
    axis(handles.vidscreen,'on','equal','xy')
else
    axis(handles.vidscreen,'on','equal','ij')
end

set(handles.vidscreen,'ylim',yl); 
set(handles.vidscreen,'xlim',xl);
set(handles.vidscreen,'Position',[0.0977088 0.228605 0.732301 0.690048])
set(handles.vidscreen,'OuterPosition',[-0.066401 0.115362 1.01634 0.880503])

if strcmp(get(handles.showmarker,'string'),'Remove M.')
    if isempty(xmarker)
        mark=load('cam_last_marker.txt');
        xmarker=mark(1);
        ymarker=mark(2);
    end
    delete(marker(ishandle(marker)))
    hold(handles.vidscreen,'on')
    xvals=round(xl(1)):round(xl(2));
    marker(1)=plot(handles.vidscreen,xvals,ymarker+0*xvals,'linewidth',2,'color','w');
    yvals=round(yl(1)):round(yl(2));
    marker(2)=plot(handles.vidscreen,xmarker+0*yvals,yvals,'linewidth',2,'color','w');
    hold(handles.vidscreen,'off')
end

if strcmp(cmap,'jet')
    %set(handles.camomatic,'colormap',jet)
elseif strcmp(cmap,'gray')
    %colormap(handles.vidscreen,'gray')
end
try
catch exception
    exception
    return
end
if get(handles.fft_mode,'value')==10
    caxis(handles.vidscreen,[10*min(min(data(1:m,1:n))) 10*mean(mean(data(1:m,1:n)))]);
else
    caxis(handles.vidscreen,[get(handles.contrast_low,'Value') get(handles.contrast,'Value')]);
end
%caxis([0 0.9*max(max(data))])
%caxis(handles.vidscreen,[min(min(data)) max(max(data))])
    %frame=swapbytes(getdata(vid,1,'native'));
    %axes(handles.vidscreen)
    %image('parent',handles.vidscr,frame,I)
    %get last frame from buffer and clear memory
    %mean(mean(getimage(handles.vidscreen)))

if loutstatus==1
if isempty(data)
else
    bit=getappdata(handles.vidscreen,'bit'); %get bit depth of source
    [y,x]=size(data(:,:,1))
    
    %get axis limits of screen
    yl=get(handles.vidscreen,'ylim');
    xl=get(handles.vidscreen,'xlim');
    ylmin=double(fix(yl(1)));
    ylmax=double(floor(yl(2)));
    xlmin=double(fix(xl(1)));
    xlmax=double(floor(xl(2)));
    
    if xlmin<0 %reset limits while panning out of data
        xlmin=2;
    end
    if xlmax>=x
        xlmax=x-2;
    end
    if ylmin<0
        ylmin=2;
    end
    if ylmax>=y
        ylmax=y-2; 
    end
    
    if louty<401
        louty=401;
    elseif louty>y-401
        louty=y-401;
    end
    if loutx<401
        loutx=401;
    elseif loutx>x-401
        loutx=x-401;
    end
    
    try
        [gmax,gpos]=max(max(data(louty-400:louty+400,loutx-400:loutx+400)));
        [row,col] = find(data(louty-400:louty+400,loutx-400:loutx+400)==gmax);
        maxy=gmax;
        maxy_pos=louty-401+row(1);
        maxx=gmax;
        maxx_pos=loutx-401+col(1);
    catch exception
        exception
        try
        [gmax,gpos]=max(max(data(:,:,1)))
        [row,col] = find(data(:,:,1)==gmax)
        maxy=gmax;
        maxy_pos=row(1);
        maxx=gmax;
        maxx_pos=col(1);
        catch exception
            exception
        end
    end
    meanx=round(mean(data(louty,xlmin+1:xlmax-1)));
    meany=round(mean(data(ylmin+1:ylmax-1,loutx)));
    gmean=round(mean(mean(data(ylmin+1:ylmax-1,xlmin+1:xlmax-1))));
    globalmean=round(mean(mean(mean(data))));
    delete(peak(ishandle(peak)))
    hold(handles.vidscreen,'on')
    loutxold=loutx;
    loutyold=louty;
    loutx=maxx_pos;
    louty=maxy_pos;
    try
    peak=plot(handles.vidscreen,loutx,louty,'o','linewidth',2);%loutx-51+col,louty-51+row,'o','linewidth',2);
    end
    hold(handles.vidscreen,'off')
    
    %plot lineout in vertical and horizontal direction
    if maxy>=bit-1
        vc=[1 0 0];
    else
        vc=[0 0 1];
    end
    try
    plot(handles.vlineout,data(:,loutx),1:y,'linewidth',2,'color',vc)
    end
    if maxx>=bit-1
        hc=[1 0 0];
    else
        hc=[0 0 1];
    end
    plot(handles.hlineout,data(louty,:),'linewidth',2,'color',hc)
    
    set(handles.globalmax,'string',num2str(gmax));
   
    %FWHM ax,bx,ay,by=horizontal/vertical pixel distance to spot center  
    [ax, bx, ay, by]=fwhm(globalmean,maxx,maxx_pos,maxy,maxy_pos,xlmin,xlmax,ylmin,ylmax,loutx,louty,data);
    if ax>100 || bx>100 || ay>100 || by>100 ||...
            maxx_pos-ax+1<=xlmin || maxx_pos+bx-1>=xlmax || maxy_pos-ay+1<=ylmin || maxy_pos+by-1>=ylmax ||...
            maxx_pos-ax <1 || maxy_pos-ay <1
        set(handles.strehl,'string','N/A');
        set(handles.fwhm,'string','N/A');
        set(handles.fwhmratio,'string','N/A');
    else
        hold(handles.vlineout,'on')
        %plot(handles.vlineout,data(maxy_pos-ay:maxy_pos+by,loutx),maxy_pos-ay:maxy_pos+by,'linewidth',3,'color','g')
        try
        plot(handles.vlineout,data(round(maxy_pos-sqrt(2)*ay):round(maxy_pos+sqrt(2)*by),loutx),round(maxy_pos-sqrt(2)*ay):round(maxy_pos+sqrt(2)*by),'linewidth',3,'color','g')
        end
        hold(handles.vlineout,'off')
        hold(handles.hlineout,'on') 
        %plot(handles.hlineout,maxx_pos-ax:maxx_pos+bx,data(louty,maxx_pos-ax:maxx_pos+bx),'linewidth',3,'color','g')
        try
        plot(handles.hlineout,round(maxx_pos-sqrt(2)*ax):round(maxx_pos+sqrt(2)*bx),data(louty,round(maxx_pos-sqrt(2)*ax):round(maxx_pos+sqrt(2)*bx)),'linewidth',3,'color','g')
        end
        hold(handles.hlineout,'off')
       
        %ratio peak to wings, "Strehl ratio"
        intensity=0;
        %meandiam=(ax+bx+ay+by)/2;
        meandiam=(ax+bx+ay+by)/sqrt(2);
        %int_data=data(maxy_pos-meandiam:maxy_pos+meandiam,maxx_pos-meandiam:maxx_pos+meandiam);
        %intensity=int_dat()
        for ny=round(maxy_pos-meandiam):round(maxy_pos+meandiam)
            for nx=round(maxx_pos-meandiam):round(maxx_pos+meandiam)
                if sqrt((abs(nx-maxx_pos))^2+(abs(ny-maxy_pos))^2)<=meandiam/2
                    try
                    intensity=intensity+double(data(ny-1,nx-1))-globalmean;
                    end
                end
            end
        end
        %data=data(ylmin+1:ylmax-1,xlmin+1:xlmax-1);
        try
            strehl=intensity/sum(data(data>1.1*mean(mean(data))))*100;
            set(handles.strehl,'string',num2str(round(strehl*10)/10));
        catch
           set(handles.strehl,'string','N/A');
           strehl=0;
        end
        set(handles.fwhm,'string',num2str(round((ax+bx+ay+by)/2*calibration*10)/10));
        fwhmr=round((ax+bx)/(ay+by)*10)/10;
        set(handles.fwhmratio,'string',num2str(fwhmr));
        
        %show real encircled energy (radii for 10% and 90% of energy)
        if get(handles.encon,'value')==1
            try
            [EE,peakI]=cam_encircled(double(data),calibration,maxx_pos,maxy_pos,round((ax+bx+ay+by)/2*calibration*10)/10,str2double(get(handles.laserE,'string')),str2double(get(handles.laserT,'string')));
            set(handles.enc_text,'string',['EE: ',num2str(EE),' / ',num2str(peakI,'%1.1E'),'W/cm^2']);
            catch exception
                exception.message
            end
        end
        
        %add statistics to screen
        if get(handles.statistics,'value')==1
            [average_strehl, min_strehl, max_strehl, strehl_vals]=cam_averagevalue(strehl,strehl_vals);
            [average_fwhm, min_fwhm, max_fwhm, fwhm_vals]=cam_averagevalue((ax+bx+ay+by)/2*calibration,fwhm_vals);
            [average_fwhmr, min_fwhmr, max_fwhmr, fwhmr_vals]=cam_averagevalue(fwhmr,fwhmr_vals);
            [average_gmax, min_gmax, max_gmax, gmax_vals]=cam_averagevalue(gmax,gmax_vals);
            if strehl>str2double(get(handles.strehl_max,'string'))
                c='r';
            elseif strehl<str2double(get(handles.strehl_min,'string'))
                c='b';
            else
                c='black';
            end
            set(handles.strehl,'string',[num2str(round(strehl*10)/10),'/',num2str(round(average_strehl*10)/10)],'foregroundcolor',c)
            set(handles.strehl_max,'string',num2str(round(max_strehl*10)/10),'foregroundcolor','r')
            set(handles.strehl_min,'string',num2str(round(min_strehl*10)/10),'foregroundcolor','b')
            if (ax+bx+ay+by)/2*calibration>str2double(get(handles.fwhm_max,'string'))
                c='r';
            elseif (ax+bx+ay+by)/2*calibration<str2double(get(handles.fwhm_min,'string'))
                c='b';
            else
                c='black';
            end
            set(handles.fwhm,'string',[num2str(round((ax+bx+ay+by)/2*calibration*10)/10),'/',num2str(round(average_fwhm*10)/10)],'foregroundcolor',c)
            set(handles.fwhm_max,'string',num2str(round(max_fwhm*10)/10),'foregroundcolor','r')
            set(handles.fwhm_min,'string',num2str(round(min_fwhm*10)/10),'foregroundcolor','b')
            if fwhmr==1
                c='r';
            else
                c='black';
            end
            set(handles.fwhmratio,'string',[num2str(fwhmr),'/',num2str(round(average_fwhmr*10)/10)],'foregroundcolor',c)
            if gmax>str2double(get(handles.globalmax_max,'string'))
                c='r';
            elseif gmax<str2double(get(handles.globalmax_min,'string'))
                c='b';
            else
                c='black';
            end
            set(handles.globalmax,'string',[num2str(gmax),'/',num2str(round(average_gmax))],'foregroundcolor',c)
            set(handles.globalmax_max,'string',num2str(max_gmax),'foregroundcolor','r')
            set(handles.globalmax_min,'string',num2str(min_gmax),'foregroundcolor','b') 
        end
        try
        if get(handles.logging,'value')==1 %log data to file
            [average_strehl, min_strehl, max_strehl, strehl_vals]=cam_averagevalue(strehl,strehl_vals);
            [average_fwhm, min_fwhm, max_fwhm, fwhm_vals]=cam_averagevalue((ax+bx+ay+by)/2*calibration,fwhm_vals);
            [average_gmax, min_gmax, max_gmax, gmax_vals]=cam_averagevalue(gmax,gmax_vals);   
            if exist('focus_logging.txt','file')
            fid=fopen('focus_logging.txt', 'r+');
            fseek(fid,0,'eof');
            else
                fid = fopen('focus_logging.txt', 'w+');
                fseek(fid,0,'eof');
                fprintf(fid, '%s', 'Time');
                fseek(fid,0,'eof');        
                fprintf(fid, '\t%s', 'FWHM(avg)');
                fseek(fid,0,'eof');
                fprintf(fid, '\t%s', 'Strehl(avg)');
                fseek(fid,0,'eof');
                fprintf(fid, '\t%s', 'Max(avg)');
                fseek(fid,0,'eof');
            end
            time_=num2str(clock);
            strehl_=num2str(round(average_strehl*10)/10);
            fwhm_=num2str(round(average_fwhm*10)/10);
            globalm_=num2str(round(average_gmax));
            if isempty(strehl)
                strehl='N/A';
            end
            if isempty(fwhm_)
                fwhm_='N/A';
            end
            if isempty(globalm_)
                globalm_='N/A';
            end
            fprintf(fid, '\n%s', time_);
            fseek(fid,0,'eof');
            fprintf(fid, '\t%s', fwhm_);
            fseek(fid,0,'eof');        
            fprintf(fid, '\t%s', strehl_);
            fseek(fid,0,'eof');        
            fprintf(fid, '\t%s', globalm_); 
            fclose(fid);           
        end
        catch exception
            %exception
        end
    end
    
    %format axis
    set(handles.vlineout,'YDir','reverse')
    xlim(handles.vlineout,[0 bit])
    ylim(handles.vlineout,[ylmin ylmax])
    set(handles.vlineout,'XTick',[]) %remove ticks
    set(handles.vlineout,'YTick',[])
    
    xlim(handles.hlineout,[xlmin xlmax])
    ylim(handles.hlineout,[0 bit])
    set(handles.hlineout,'XTick',[]) %remove ticks
    set(handles.hlineout,'YTick',[])
 
    set(handles.vidscreen,'XTick',round(xlmin:(xlmax-xlmin)/10:xlmax+1))
    set(handles.vidscreen,'YTick',round(ylmin:(ylmax-ylmin)/10:ylmax+1))
    
    %update mean, max, min values in gui
    set(handles.meanx,'string',num2str(meanx));
    set(handles.fwhmx,'string',num2str(round((ax+bx)*calibration*10)/10));
    set(handles.meany,'string',num2str(meany));
    set(handles.fwhmy,'string',num2str(round((ay+by)*calibration*10)/10));
    set(handles.globalmean,'string',num2str(gmean));
    replotlineout=0;
    if chase==0 %no chasemode
        loutx = loutxold;
        louty = loutyold;
    else %chasemode
        if gmax>=globalmean+(bit-globalmean)/8
            rangex=xlmax-xlmin;
            rangey=ylmax-ylmin;
            loutxrel=loutx-xlmin;
            loutyrel=louty-ylmin;
            if loutxrel<0.2*rangex || loutxrel>0.8*rangex
                if round(loutx-rangex/2)<= 0 || round(loutx+rangex/2)>= vidRes(1)
                else
                    set(handles.vidscreen,'Xlim',[round(loutx-rangex/2) round(loutx+rangex/2)])
                    replotlineout=1;
                end
            
            end
            if loutyrel<0.2*rangey || loutyrel>0.8*rangey
                if round(louty-rangey/2)<= 0 || round(louty+rangey/2)>= vidRes(2)
                else
                set(handles.vidscreen,'Ylim',[round(louty-rangey/2) round(louty+rangey/2)])
                replotlineout=1;
                end
            end
            if replotlineout==1
                delete(loutplot(ishandle(loutplot)))
                hold(handles.vidscreen,'on')
                xleft=[1:(loutx-50)/10:loutx-51,loutx-50];
                xright=[loutx+50,loutx+51:(vidRes(1)-loutx+50)/10:vidRes(1)+1];
                yleft=[1:(louty-50)/100:louty-51,louty-50];
                yright=[louty+50,louty+51:(louty-50)/100:vidRes(2)+1];
                loutplot(1)=plot(handles.vidscreen,xleft,louty+0*xleft,'--','linewidth',1,'color','w');
                loutplot(2)=plot(handles.vidscreen,xright,louty+0*xright,'--','linewidth',1,'color','w');
                loutplot(3)=plot(handles.vidscreen,loutx+0*yleft,yleft,'--','linewidth',1,'color','w');
                loutplot(4)=plot(handles.vidscreen,loutx+0*yright,yright,'--','linewidth',1,'color','w');
                hold(handles.vidscreen,'off')
            end
        else
        	loutx = loutxold;
            louty = loutyold;
        end
    end
end
clear data
if camtype==1
    flushdata(obj,'all')
end
else
    if camtype==1
    	flushdata(obj,'all')
    end
end
end