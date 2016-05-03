function lineout(obj, event, handles, vid, hImage)
global loutx louty loutstatus...
    peak chase vidRes loutplot...
    calibration strehl_vals fwhm_vals gmax_vals data
    try
        frame=swapbytes(getdata(vid,1,'native'));
    catch
        return
    end
    %h_axes=axes('Tag','vidscreen' ,'parent', handles.camomatic);
    set(gcf,'CurrentAxes',handles.vidscreen)
    imagesc(frame, 'parent', h_axes)
%get last frame from buffer and clear memory
if loutstatus==1
    data = getimage(handles.vidscreen);
    %data = peekdata(obj, 1);
    flushdata(obj,'all')
    %clc
if isempty(data)
else
    bit=cam_getbit(class(data)); %get bit depth of source
    
    [y,x]=size(data);
    
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
    
    if louty<101
        louty=101;
    elseif louty>y-101
        louty=y-101;
    end
    if loutx<101
        loutx=101;
    elseif loutx>x-101
        loutx=x-101;
    end
   
    [gmax,gpos]=max(max(data(louty-100:louty+100,loutx-100:loutx+100)));
    [row,col] = find(data(louty-100:louty+100,loutx-100:loutx+100)==gmax);
    maxy=gmax;
    maxy_pos=louty-101+row(1);
    maxx=gmax;
    maxx_pos=loutx-101+col(1);
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
    peak=plot(handles.vidscreen,loutx,louty,'o','linewidth',2);%loutx-51+col,louty-51+row,'o','linewidth',2);
    hold(handles.vidscreen,'off')
    
    %plot lineout in vertical and horizontal direction
    if maxy>=bit-1
        vc=[1 0 0];
    else
        vc=[0 0 1];
    end
    plot(handles.vlineout,data(:,loutx),1:y,'linewidth',2,'color',vc)
       
    if maxx>=bit-1
        hc=[1 0 0];
    else
        hc=[0 0 1];
    end
    plot(handles.hlineout,data(louty,:),'linewidth',2,'color',hc)
    
    set(handles.globalmax,'string',num2str(gmax));
   
    %FWHM ax,bx,ay,by=horizontal/vertical pixel distance to spot center  
    [ax, bx, ay, by]=fwhm(globalmean,maxx,maxx_pos,maxy,maxy_pos,xlmin,xlmax,ylmin,ylmax,loutx,louty,data);
    if ax>50 || bx>50 || ay>50 || by>50 ||...
            maxx_pos-ax+1<=xlmin || maxx_pos+bx-1>=xlmax || maxy_pos-ay+1<=ylmin || maxy_pos+by-1>=ylmax ||...
            maxx_pos-ax <1 || maxy_pos-ay <1
        set(handles.strehl,'string','N/A');
        set(handles.fwhm,'string','N/A');
        set(handles.fwhmratio,'string','N/A');
    else
        hold(handles.vlineout,'on')
        %plot(handles.vlineout,data(maxy_pos-ay:maxy_pos+by,loutx),maxy_pos-ay:maxy_pos+by,'linewidth',3,'color','g')
        plot(handles.vlineout,data(round(maxy_pos-sqrt(2)*ay):round(maxy_pos+sqrt(2)*by),loutx),round(maxy_pos-sqrt(2)*ay):round(maxy_pos+sqrt(2)*by),'linewidth',3,'color','g')
        hold(handles.vlineout,'off')
        hold(handles.hlineout,'on') 
        %plot(handles.hlineout,maxx_pos-ax:maxx_pos+bx,data(louty,maxx_pos-ax:maxx_pos+bx),'linewidth',3,'color','g')
        plot(handles.hlineout,round(maxx_pos-sqrt(2)*ax):round(maxx_pos+sqrt(2)*bx),data(louty,round(maxx_pos-sqrt(2)*ax):round(maxx_pos+sqrt(2)*bx)),'linewidth',3,'color','g')
        hold(handles.hlineout,'off')
       
        %ratio peak to wings, "Strehl ratio"
        intensity=0;
        %meandiam=(ax+bx+ay+by)/2;
        meandiam=(ax+bx+ay+by)/sqrt(2);
        for ny=round(maxy_pos-meandiam):round(maxy_pos+meandiam)
            for nx=round(maxx_pos-meandiam):round(maxx_pos+meandiam)
                if sqrt((abs(nx-maxx_pos))^2+(abs(ny-maxy_pos))^2)<=meandiam/2
                    intensity=intensity+double(data(ny-1,nx-1))-globalmean;
                end
            end
        end
        %data=data(ylmin+1:ylmax-1,xlmin+1:xlmax-1);
        try
            strehl=intensity/sum(data(find(data>1.1*mean(mean(data)))))*100;
            set(handles.strehl,'string',num2str(round(strehl*10)/10));
        catch
           set(handles.strehl,'string','N/A');
           strehl=0;
        end
        set(handles.fwhm,'string',num2str(round((ax+bx+ay+by)/2*calibration*10)/10));
        set(handles.fwhmratio,'string',num2str(round((ax+bx)/(ay+by)*10)/10));
        
        %show real encircled energy (radii for 10% and 90% of energy)
        if get(handles.encon,'value')==1
            status=cam_encircled(data,calibration,maxx_pos,maxy_pos);
            set(handles.enc_text,'string',['EE: ',num2str(status(1)),' / ',num2str(status(2))]);
        end
        
        %add statistics to screen
        if get(handles.statistics,'value')==1
            [average_strehl, min_strehl, max_strehl, strehl_vals]=cam_averagevalue(strehl,strehl_vals);
            [average_fwhm, min_fwhm, max_fwhm, fwhm_vals]=cam_averagevalue((ax+bx+ay+by)/2*calibration,fwhm_vals);
            [average_gmax, min_gmax, max_gmax, gmax_vals]=cam_averagevalue(gmax,gmax_vals);
            if strehl>str2num(get(handles.strehl_max,'string'))
                c='r';
            elseif strehl<str2num(get(handles.strehl_min,'string'))
                c='b';
            else
                c='black';
            end
            set(handles.strehl,'string',[num2str(round(strehl*10)/10),'/',num2str(round(average_strehl*10)/10)],'foregroundcolor',c)
            set(handles.strehl_max,'string',num2str(round(max_strehl*10)/10),'foregroundcolor','r')
            set(handles.strehl_min,'string',num2str(round(min_strehl*10)/10),'foregroundcolor','b')
            if (ax+bx+ay+by)/2*calibration>str2num(get(handles.fwhm_max,'string'))
                c='r';
            elseif (ax+bx+ay+by)/2*calibration<str2num(get(handles.fwhm_min,'string'))
                c='b';
            else
                c='black';
            end
            set(handles.fwhm,'string',[num2str(round((ax+bx+ay+by)/2*calibration*10)/10),'/',num2str(round(average_fwhm*10)/10)],'foregroundcolor',c)
            set(handles.fwhm_max,'string',num2str(round(max_fwhm*10)/10),'foregroundcolor','r')
            set(handles.fwhm_min,'string',num2str(round(min_fwhm*10)/10),'foregroundcolor','b')
            if gmax>str2num(get(handles.globalmax_max,'string'))
                c='r';
            elseif gmax<str2num(get(handles.globalmax_min,'string'))
                c='b';
            else
                c='black';
            end
            set(handles.globalmax,'string',[num2str(gmax),'/',num2str(round(average_gmax))],'foregroundcolor',c)
            set(handles.globalmax_max,'string',num2str(max_gmax),'foregroundcolor','r')
            set(handles.globalmax_min,'string',num2str(min_gmax),'foregroundcolor','b') 
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
else
    flushdata(obj,'all')
end
end