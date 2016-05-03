function varargout = pike_control(varargin)
% Last Modified by GUIDE v2.5 28-Jan-2014 12:12:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pike_control_OpeningFcn, ...
                   'gui_OutputFcn',  @pike_control_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT



% --- Executes just before pike_control is made visible.
function pike_control_OpeningFcn(hObject, eventdata, handles, varargin)
global loutx louty cmap loutstatus chase calibration
handles.output = hObject;
%clc

%set(0,'RecursionLimit',1000)
cmap='jet';

if exist('cam_last_lineout.txt','file')
    lout=load('cam_last_lineout.txt');
    loutx=lout(1);
    louty=lout(1);
    set(handles.lout_text,'string',[num2str(loutx),'/',num2str(louty)])
else
    loutx=1;
    louty=1;
end
if exist('cam_calibration.txt','file')
    calibration=load('cam_calibration.txt');
    set(handles.calib_text,'string',[num2str(round(calibration*1000)/1000),' micron/px'])
else
    calibration=1;
end
loutstatus=0;
chase=0;
% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = pike_control_OutputFcn(hObject, eventdata, handles) 
try
varargout{1} = handles.output;
end
% --- Executes on button press in startpreview.
function startpreview_Callback(hObject, eventdata, handles)
global vid cmap loutx louty loutplot loutstatus vidRes src...
    strehl_vals fwhmr_vals fwhm_vals gmax_vals marker pco camtype
clear frameavg
status=get(hObject,'string');
if camtype==1
    vidRes = get(vid, 'VideoResolution');
elseif camtype==2
    vidRes(1)= 2160;
    vidRes(2)= 2560;
    set(handles.vidscreen,'ylim',[0 pco.xSize]); 
    set(handles.vidscreen,'xlim',[0 pco.ySize]);
end
yl=get(handles.vidscreen,'ylim'); %old axis limits
xl=get(handles.vidscreen,'xlim');
if yl(1)<0 || xl(1) < 0 || yl(2)>vidRes(2) || xl(2) > vidRes(1);
    yl(1)=0;
    yl(2)=vidRes(2);
    xl(1)=0;
    xl(2)=vidRes(1);
    set(handles.vidscreen,'ylim',xl)
    set(handles.vidscreen,'ylim',yl)
end

if loutx>vidRes(1) || louty>vidRes(2)
    loutx=round(vidRes(1)/2);
    louty=round(vidRes(2)/2);
    set(handles.vidscreen,'ylim',xl)
    set(handles.lout_text,'string',[num2str(loutx),'/',num2str(louty)],'Foregroundcolor','black')
end
 
if strcmp(status,'Start')
    %reset statistics
	strehl_vals=0;
    fwhm_vals=0; 
    fwhmr_vals=0;
    gmax_vals=0;
    %turn off buttons
    set(handles.format,'Enable','off')
    set(handles.snshot,'Enable','off')
    set(handles.frate,'Enable','off')
    set(handles.shuttermulti,'enable','off')
    set(handles.load,'enable','off')
    %reset marker
    delete(marker(ishandle(marker)))
    set(handles.showmarker,'string','Show M.','foregroundcolor','black')
    if camtype==1
        %reload shutter and gain values
        try
            src.gain=get(handles.cgain,'Value');
        end
        try
            src.shutter=get(handles.Shutter,'Value');
        end
        try
            %src.shuttermode='on';
            %src.ExposureOffset=0;
        catch exception
            exception
        end
        %set timer function

        vid.FramesPerTrigger = 1;
        vid.TimerFcn=[];
        vid.TimerPeriod=get(handles.refresh,'value');
        vid.FramesPerTrigger=Inf;
        flushdata(vid,'all')

        %get bit depth of source
        start(vid)
        data=getdata(vid,1,'native');
        stop(vid)
        bit=cam_getbit(class(data));
        setappdata(handles.vidscreen,'bit',bit)
        clear data
    elseif camtype==2
        % get ROI
        %[x0, y0, x1, y1, err] = getROI_PCO(hCam);
        %if err ~= 0
            %errMess = [getTime(), ' ERROR: ', getErrPCO(int32(err))];
            %set(outputWindow, 'String', [errMess; get(outputWindow, 'String')]);
        %end
        % set CamLink Image Parameters
        err   = setCLIP_PCO(pco.hCam, pco.xSize, pco.ySize);
        if err ~= 0
        	errMess = [getTime(), ' ERROR: ', getErrPCO(int32(err))]
        end
        % set trigger mode (software)
        err = setTrigModePCO(pco.hCam, uint16(1));
        if err ~= 0
        	errMess = [getTime(), ' ERROR: ', getErrPCO(int32(err))]
        end
        % arm camera
        err = armCameraPCO(pco.hCam);
        if err ~= 0
        	errMess = [getTime(), ' ERROR: ', getErrPCO(int32(err))]
        end
        % set recState on
        err = setRecStatePCO(pco.hCam, uint16(1));
        if err ~= 0
        	errMess = [getTime(), ' ERROR: Could not begin recording.']
            errMess2 = ['                    ', 'PLEASE RESTART THE CAMERA AND TRY AGAIN.']
        end
              
        vid = timer;
        set(vid,'ExecutionMode','fixedRate','BusyMode','drop','Period',.01);
        vid.TimerFcn = {@cam_lineout, handles, vid, camtype, pco};
        [b, err] = getSingleFrameBasic(pco.hCam, pco.xSize, pco.ySize, pco.fp1, pco.sbn1, pco.hbuf1);
        data = reshape(b, 2560, [])'; 
        bit=cam_getbit(class(data));
        setappdata(handles.vidscreen,'bit',bit)
        clear data
        
    end
    %plot lineout
    if loutstatus==1;
        delete(loutplot(ishandle(loutplot)))
        hold on
        xleft=[1:(loutx-50)/10:loutx-51,loutx-50];
        xright=[loutx+50,loutx+51:(vidRes(1)-loutx+50)/10:vidRes(1)+1];
        yleft=[1:(louty-50)/100:louty-51,louty-50];
        yright=[louty+50,louty+51:(louty-50)/100:vidRes(2)+1];
        loutplot(1)=plot(handles.vidscreen,xleft,louty+0*xleft,'--','linewidth',1,'color','w');
        loutplot(2)=plot(handles.vidscreen,xright,louty+0*xright,'--','linewidth',1,'color','w');
        loutplot(3)=plot(handles.vidscreen,loutx+0*yleft,yleft,'--','linewidth',1,'color','w');
        loutplot(4)=plot(handles.vidscreen,loutx+0*yright,yright,'--','linewidth',1,'color','w');
        hold off
    end
    
    
    contrast_Callback(hObject, eventdata, handles)
    set(hObject,'string','Stop','Foregroundcolor','r')  
    if camtype==1
        %triggerconfig(vid, 'hardware','risingEdge','externalTrigger')
        %set(vid,'FramesPerTrigger',1)
        %set(vid,'TriggerRepeat',Inf)
        triggerconfig(vid,'immediate','none','none')
        %triggerconfig(vid,'manual')
        if 1==1 %bit>300
            %16
            vid.TimerFcn={@cam_lineout, handles, vid, camtype};    
            start(vid)
        else
            %8
            vidRes = get(vid, 'VideoResolution');
            nBands = get(vid, 'NumberOfBands');
            handles.vidscr = image( zeros(vidRes(2), vidRes(1), nBands) );
            hImage=findobj(handles.vidscr,'Type','image');
            vid.TimerFcn={@cam_lineout, handles, vid, camtype};
            preview(vid,hImage);
            %axis(handles.vidscr,'ij')
            start(vid)
        end
        set(handles.blacklist,'enable','on')
    elseif camtype==2
        start(vid)
        %pause(0.1)
    end
    zoom reset
    axis on
    axis equal
    
    if camtype==1 && bit<300
        axis ij
    else
        axis xy
    end
    
    if strcmp(cmap,'jet')
        colormap(jet)
    elseif strcmp(cmap,'gray')
        colormap(gray)
    end
    
else
    set(hObject,'string','Start','Foregroundcolor','black')
    
    if camtype==1
        stoppreview(vid);
        stop(vid)
        flushdata(vid,'all')
    elseif camtype==2
        err = setRecStatePCO(pco.hCam, uint16(0));
        stop(vid)
        if err ~= 0
            errMess = [getTime(), ' ERROR: Could not stop recording.'];
            errMess2 = ['                    ', 'PLEASE RESTART THE CAMERA AND TRY AGAIN.']
        end    
    end
    set(handles.format,'Enable','on')
    frate=get(handles.frate,'string');
    if strcmp(frate,'Fixed')
    else
        set(handles.frate,'Enable','on')
    end
    set(handles.snshot,'Enable','on')
    try
    src.Timebase;
    set(handles.shuttermulti,'Enable','on')
    end
    set(handles.load,'enable','on')
    set(handles.blacklist,'enable','off')
end
set(handles.vidscreen,'ylim',yl);
set(handles.vidscreen,'xlim',xl);
zoom off
pan off
set(handles.zoomin,'string','Zoom in','foregroundcolor','black')
set(handles.zoomout,'string','Zoom out','foregroundcolor','black')
set(handles.panimage,'string','Pan','foregroundcolor','black')
guidata(hObject, handles);

% --- Executes on button press in snshot.
function snshot_Callback(hObject, eventdata, handles)
global vid frameavg init answer camtype pco
yl=get(handles.vidscreen,'ylim'); %old axis limits
xl=get(handles.vidscreen,'xlim');
set(hObject,'Enable','off')
try
prompt = {'Number of images:'};
dlg_title = 'Average iamges';
num_lines = 1;
if exist('lastsnap.txt','file')
    fid = fopen('lastsnap.txt','r');
    lastsnap=(fread(fid,'*char'))';
    fclose(fid);
else
    lastsnap='1';
end
def = {lastsnap};
answer = inputdlg(prompt,dlg_title,num_lines,def);
%answer = {'1'};


if ~isempty(answer)
a=0;
b=str2double(cell2mat(answer))

fid = fopen('lastsnap.txt', 'wt');
fprintf(fid, '%s', num2str(b));
fclose(fid);

hw = waitbar(0,'Please wait...','Name','Accumulating images...',...
            'CreateCancelBtn',...
            'setappdata(gcbf,''canceling'',1)');
setappdata(hw,'canceling',0)

if camtype==1
    flushdata(vid,'all')
    pause(.01)
    %frame = getsnapshot(vid);
    init=1;
    format_Callback(hObject,eventdata,handles)
    src.gain=get(handles.cgain,'Value');
    src.shutter=get(handles.Shutter,'Value');
    vid.TimerFcn=[];
    start(vid);
else
	err   = setCLIP_PCO(pco.hCam, pco.xSize, pco.ySize);
        if err ~= 0
        	errMess = [getTime(), ' ERROR: ', getErrPCO(int32(err))]
        end
        % set trigger mode (software)
        err = setTrigModePCO(pco.hCam, uint16(1));
        if err ~= 0
        	errMess = [getTime(), ' ERROR: ', getErrPCO(int32(err))]
        end
        % arm camera
        err = armCameraPCO(pco.hCam);
        if err ~= 0
        	errMess = [getTime(), ' ERROR: ', getErrPCO(int32(err))]
        end
        % set recState on
        err = setRecStatePCO(pco.hCam, uint16(1));
        if err ~= 0
        	errMess = [getTime(), ' ERROR: Could not begin recording.']
            errMess2 = ['                    ', 'PLEASE RESTART THE CAMERA AND TRY AGAIN.']
        end
end

while a<b
    try
        pause(0.1)
        if camtype==1
            frame = swapbytes(getdata(vid,1,'native'));
        else
            [fr, err] = getSingleFrameBasic(pco.hCam, pco.xSize, pco.ySize, pco.fp1, pco.sbn1, pco.hbuf1);
            frame = reshape(fr, 2560, [])';
           
        end
        
    catch exception
        %exception
        frame=[];
        if camtype==1
        stop(vid)
        pause(0.1)
        start(vid)
        end
    end
    %clc
    if a==0
        if isempty(frame)
        else
            frameavg=uint32(0);
            if camtype==1
                flushdata(vid,'all')
            end
        end
    end
    if isempty(frame)
            if camtype==1
                flushdata(vid,'all')
            end
        %a=a+1;
    else
        a=a+1;
        frameavg=frameavg+uint32(frame);
        %imagesc(frameavg);
        m=mean(mean(frameavg));
        try
            waitbar(a/b,hw,['Image ',num2str(a),' of ',num2str(b),' (total/mean ',num2str(round(m)),'/',num2str(round(m/a)),')']);
        catch exception
            exception
            exception.stack(1,1)
        end
        if getappdata(hw,'canceling')
        break
        end
    end
end

try
    delete(hw)
end

init=0;
if camtype==1
    stop(vid);
    format_Callback(hObject,eventdata,handles)
else
    err = setRecStatePCO(pco.hCam, uint16(0));
    if err ~= 0
        errMess = [getTime(), ' ERROR: Could not stop recording.'];
        errMess2 = ['                    ', 'PLEASE RESTART THE CAMERA AND TRY AGAIN.']
    end
end

frameavg=uint16(frameavg/a);
imageavg=mean(mean(frameavg))
imagesc(frameavg)
axis equal xy
set(handles.vidscreen,'ylim',yl);
set(handles.vidscreen,'xlim',xl);
pause(.1)
end
catch exception
    exception
    delete(hw)
end
set(hObject,'Enable','on')



% --- Executes on button press in initcam.
function initcam_Callback(hObject, eventdata, handles)
global camtype status
mode=get(hObject,'string');

if strcmp(mode,'Initialize')
    try iminfo=imaqhwinfo;
    end
    choice = {'Accquisition ToolBox','PCO.Edge'};
    [s,v] = listdlg('PromptString','Select a Type:',...
                    'SelectionMode','single',...
                      'ListString',choice);
    %try
    if s==1 %Use image accquisition toolbox
        iat_Callback(hObject, eventdata, handles)
        if status==1
        camtype=1;
        else
            errordlg('Check Camera!','Camera Error');
            return
        end
        set(handles.insp,'Enable','On')
        set(handles.format,'Enable','On')
    elseif s==2
        pco_Callback(hObject, eventdata, handles)
        if status==1
        camtype=2;
        else
            errordlg('Check Camera!','Camera Error');
            return
        end
    end

    set(handles.snshot,'Enable','On')
    set(handles.startpreview,'Enable','On')
    set(handles.saveimage,'Enable','On')
    set(handles.lout,'Enable','On')
    set(handles.marker,'Enable','On')
    set(handles.showmarker,'Enable','On')
    set(hObject,'string','Disable Camera');
else
    global vid pco
    if camtype==1
        delete(vid)
    elseif camtype==2
        cam_closePCO(pco)
        clear pco
    else
        
    end
    camtype=0;
    set(hObject,'string','Initialize');
    set(handles.snshot,'Enable','Off')
    set(handles.startpreview,'Enable','Off')
    set(handles.saveimage,'Enable','Off')
    set(handles.lout,'Enable','Off')
    set(handles.marker,'Enable','Off')
    set(handles.showmarker,'Enable','Off')
    set(handles.cgain,'Enable','Off')
    set(handles.frate,'string','Frame Rate');
    set(handles.frate,'Enable','Off')
    set(handles.shuttermulti,'string','1');
    set(handles.shuttermulti,'Value',1);
    set(handles.shuttermulti,'Enable','Off')
    set(handles.insp,'Enable','Off')
    set(handles.format,'String','Video Format')
    set(handles.format,'Enable','Off')
    
end
           
% --- Executes on button press in insp.
function insp_Callback(hObject, eventdata, handles)
global src
inspect(src)

% --- Executes on selection change in format.
function format_Callback(hObject, eventdata, handles)
global vid src adaptor dev vidobj
delete(vid)
val=get(handles.format,'Value');
formats=get(handles.format,'string');
task=get(hObject,'Tag');
if strcmp(task,'snshot')
    global init
    if init==1
        vid=cam_init(adaptor,dev,cell2mat(formats(12)));
        bitdepth=16
    else
        vid=cam_init(adaptor,dev,cell2mat(formats(13)));
        bitdepth=8
    end
else
    vid=cam_init(adaptor,dev,cell2mat(formats(val)));
    %vidobj = imaq.VideoDevice(adaptor, dev, cell2mat(formats(val)))
end
src=getselectedsource(vid);
try 
    src.FrameRate;
    new=length(set(src,'FrameRate'));
    frate_val=get(handles.frate,'value');
    if new<frate_val
        set(handles.frate,'value',new);
        frate_val=new;
    else
    end
    set(handles.frate,'string',set(src,'FrameRate'));
    frate=set(src,'FrameRate');
    src.FrameRate=cell2mat(frate(frate_val));
    set(handles.frate,'Enable','on')
catch
    set(handles.frate,'value',1);
    set(handles.frate,'string','Fixed');
    set(handles.frate,'Enable','off')
end
vidRes = get(vid, 'VideoResolution');
set(handles.vidscreen,'xlim',[0 vidRes(1)])
set(handles.vidscreen,'ylim',[0 vidRes(2)])
set(handles.vidscreen,'xtickmode','auto')
set(handles.vidscreen,'ytickmode','auto')



% --- Executes during object creation, after setting all properties.
function format_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in frate.
function frate_Callback(hObject, eventdata, handles)
global src
val=get(hObject,'Value');
frate=get(hObject,'string');
src.FrameRate=cell2mat(frate(val));

% --- Executes during object creation, after setting all properties.
function frate_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in saveimage.
function saveimage_Callback(hObject, eventdata, handles)
global frameavg data camtype
if ~isempty(frameavg)
    data=frameavg;
else
    data = getimage(handles.vidscreen);
end
if camtype==2
    data=uint16(data);
end

standardfilename=[datestr(now,30),'.tiff'];
if exist('lastpath.txt','file')
    fid = fopen('lastpath.txt','r');
    path=(fread(fid,'*char'))';
    fclose(fid);
else
    path='c:\';
end

[file,path] = uiputfile([path,standardfilename],'Save file name');
if file==0;
else
    filename=[path,file];
    imwrite(data,filename,'tif','Compression','none')%;,'ColorSpace','icclab')
    fid = fopen('lastpath.txt', 'wt');
    fprintf(fid, '%s', path);
    fclose(fid);
    % Construct a questdlg with three options
    choice = questdlg('Save values?', ...
    'Value saving', ...
    'Yes','No','No');
    % Handle response
    switch choice
        case 'Yes'
            if exist([path,'focus_values.txt'],'file')
                fid=fopen([path,'focus_values.txt'], 'r+');
                fseek(fid,0,'eof');
            else      
                fid = fopen([path,'focus_values.txt'], 'w+');
                fseek(fid,0,'eof');
                fprintf(fid, '%s', 'Filename');
                fseek(fid,0,'eof');        
                fprintf(fid, '\t%s', 'FWHM(last/avg)');
                fseek(fid,0,'eof');
                fprintf(fid, '\t%s', 'Strehl(last/avg)');
                fseek(fid,0,'eof');
            end
            strehl=get(handles.strehl,'string');
            fwhm=get(handles.fwhm,'string');
            if isempty(strehl)
                strehl='N/A';
            end
            if isempty(fwhm)
                fwhm='N/A';
            end
            fprintf(fid, '\n%s', file(1:length(file)-5));
            fseek(fid,0,'eof');
            fprintf(fid, '\t%s', fwhm);
            fseek(fid,0,'eof');        
            fprintf(fid, '\t%s', strehl);    
            fclose(fid);
    end
end
% --- Executes on selection change in lut.
function lut_Callback(hObject, eventdata, handles)
global cmap
val = get(hObject,'Value');
str=get(hObject,'string');
cmap=str(val);
if strcmp(cmap,'jet')
	colormap(jet)
elseif strcmp(cmap,'gray')
	colormap(gray)
end

% --- Executes on button press in load.
function load_Callback(hObject, eventdata, handles)
global frameavg
[file,path]=uigetfile('*.tiff','Load focus file');
fullfile=[path, file];
imfinfo(fullfile)
focus=(imread(fullfile,'tiff'));

%bg=(imread([path, 'bg.tiff'],'tiff'));

%[X, map] = gray2ind(focus,2^8);
X=focus./2^4;
%X=double(X);


%bg=bg./2^4;
%bg=double(bg);
imagesc(X)
frameavg=(X);
axis equal
axis xy

% --- Executes during object creation, after setting all properties.
function lut_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in lout.
function lout_Callback(hObject, eventdata, handles)
global vid loutx louty loutplot loutstatus peak chase camtype
status=get(hObject,'string');
if strcmp(status,'Lineout')
    % Construct a questdlg with three options
    choice = questdlg('Reset position?', ...
	'Lineoutposition', ...
	'Yes','No','Chase','Chase');
    % Handle response
    pause(0.1)
    switch choice	
        case 'Yes'
            [x,y] = ginput(1);
            loutx=round(x);
            louty=round(y);
            chase=0;
            pause(.1)
        case 'No'
        case 'Chase'
            [x,y] = ginput(1);
            loutx=round(x);
            louty=round(y);
            chase=1;
            loutstatus=1;
            pause(.1)
        case ''
            chase=0;
            loutstatus=0;
            return
    end
    
    set(handles.lout_text,'string',[num2str(loutx),'/',num2str(louty)],'Foregroundcolor','black')
    save('cam_last_lineout.txt','loutx','louty','-ascii')

    zoom off
    pan off
    set(handles.zoomin,'string','Zoom in','foregroundcolor','black')
    set(handles.zoomout,'string','Zoom out','foregroundcolor','black')
    set(handles.panimage,'string','Pan','foregroundcolor','black')

    %plot lineout
    if camtype==1
        vidRes = get(vid, 'VideoResolution');
    elseif camtype==2
            vidRes(1)= 2160;
            vidRes(2)= 2560;
    end
    delete(loutplot(ishandle(loutplot)))
	hold on
    xleft=[1:(loutx-50)/10:loutx-51,loutx-50];
    xright=[loutx+50,loutx+51:(vidRes(1)-loutx+50)/10:vidRes(1)+1];
    yleft=[1:(louty-50)/100:louty-51,louty-50];
    yright=[louty+50,louty+51:(louty-50)/100:vidRes(2)+1];
	loutplot(1)=plot(handles.vidscreen,xleft,louty+0*xleft,'--','linewidth',1,'color','w');
	loutplot(2)=plot(handles.vidscreen,xright,louty+0*xright,'--','linewidth',1,'color','w');
	loutplot(3)=plot(handles.vidscreen,loutx+0*yleft,yleft,'--','linewidth',1,'color','w');
	loutplot(4)=plot(handles.vidscreen,loutx+0*yright,yright,'--','linewidth',1,'color','w');
	hold off
   
    try
        data = getimage(handles.vidscreen);
        if isempty(data) 
            return
        elseif data==0
            return
        else
            bit=cam_getbit(class(data));
            maxy=max(data(:,loutx));
            maxx=max(data(louty,:));
            
            if maxy>=bit-1
                vc=[1 0 0];
            else
                vc=[0 0 1];
            end
            [yim,xim]=size(data);
            plot(handles.vlineout,data(:,loutx),1:yim,'linewidth',2,'color',vc)
            set(handles.vlineout,'YDir','reverse')
            xlim(handles.vlineout,[0 bit])
            ylim(handles.vlineout,get(handles.vidscreen,'ylim'))
            set(handles.vlineout,'XTick',[])
            set(handles.vlineout,'YTick',[])
            %set(handles.maxy,'string',['Max(y):',num2str(maxy)]);
            
            if maxx>=bit-1
                hc=[1 0 0];
            else
                hc=[0 0 1];
            end
            plot(handles.hlineout,data(louty,:),'linewidth',2,'color',hc)
            xlim(handles.hlineout,get(handles.vidscreen,'xlim'))
            ylim(handles.hlineout,[0 bit])
            set(handles.hlineout,'XTick',[])
            set(handles.hlineout,'YTick',[])
            %set(handles.maxx,'string',['Max(x):',num2str(maxx)]);
        end
    catch exception
        exception
    end
	set(hObject,'string','Lineout on','foregroundcolor','r'); 
	loutstatus=1;
else
    delete(peak(ishandle(peak)))
    delete(loutplot(ishandle(loutplot)))
	set(hObject,'string','Lineout','foregroundcolor','black');  
	loutstatus=0;
end
guidata(hObject,handles)


% --- Executes on button press in marker.
function marker_Callback(hObject, eventdata, handles)
global marker xmarker ymarker
[xmarker,ymarker] = ginput(1);
[xrange]=get(handles.vidscreen,'Xlim');
[yrange]=get(handles.vidscreen,'ylim');
delete(marker(ishandle(marker)))
hold on
xvals=round(xrange(1)):round(xrange(2));
marker(1)=plot(xvals,ymarker+0*xvals,'linewidth',2,'color','w');

yvals=round(yrange(1)):round(yrange(2));
marker(2)=plot(xmarker+0*yvals,yvals,'linewidth',2,'color','w');
hold off

save('cam_last_marker.txt','xmarker','ymarker','-ascii')

% --- Executes on button press in showmarker.
function showmarker_Callback(hObject, eventdata, handles)
global marker xmarker ymarker
str=get(hObject,'string');
if strcmp(str,'Show M.')
    if isempty(xmarker)
        mark=load('cam_last_marker.txt');
        xmarker=mark(1);
        ymarker=mark(2);
    end
    
    [xrange]=get(handles.vidscreen,'Xlim');
    [yrange]=get(handles.vidscreen,'ylim');
    delete(marker(ishandle(marker)))
    hold on
    xvals=round(xrange(1)):round(xrange(2));
    marker(1)=plot(xvals,ymarker+0*xvals,'linewidth',2,'color','w');

    yvals=round(yrange(1)):round(yrange(2));
    marker(2)=plot(xmarker+0*yvals,yvals,'linewidth',2,'color','w');
    hold off
    set(hObject,'string','Remove M.','foregroundcolor','r')
else
    delete(marker(ishandle(marker)))
    set(hObject,'string','Show M.','foregroundcolor','black')
end


% --- Executes on slider movement.
function Shutter_Callback(hObject, eventdata, handles)
global camtype src shutterfactor
shutter=round(get(hObject,'Value'));
set(handles.Shutter,'Enable','Off')
if camtype==1
    try
    set(src,'Shutter',shutter)
    catch exception
        'Trying gentl'
        try
            set(src,'ExposureTime',shutter)
        catch exception
            exception
        end
    end
    pause(.1)
    set(handles.shutter_text,'String',num2str(shutter))
elseif camtype==2
    global pco
    pco.expTime=shutter;
    if shutter==1
        pco.expTime=1000;
        pco.expBase=1;
        set(handles.Shutter,'Max',1000)
        set(handles.Shutter,'SliderStep',[1/991 0.1])
        set(handles.Shutter,'value',pco.expTime)
        pause(0.001)
        set(handles.Shutter,'Min',10)
        shutterfactor=0.001;
    elseif shutter==1000
        pco.expTime=1;
        pco.expBase=2;
        set(handles.Shutter,'Min',1)
        set(handles.Shutter,'SliderStep',[1/101 0.1])
        set(handles.Shutter,'value',pco.expTime)
        pause(0.001)
        set(handles.Shutter,'Max',100)
        shutterfactor=1;
    end
        
    if shutterfactor==1;
        set(handles.shutter_text,'String',[num2str(pco.expTime),'ms'])
    elseif shutterfactor==0.001;
        set(handles.shutter_text,'string',[num2str(pco.expTime),'us'])
    end
    err = setDelExpPCO(pco.hCam, uint32(pco.delTime), uint32(pco.expTime), uint16(pco.delBase), uint16(pco.expBase));
    if err ~=0
        errMess = [getTime(), ' ERROR: ', getErrPCO(int32(err))]
        %set(handles.outputWindow, 'String', [errMess; get(handles.outputWindow, 'String')]);
    else
        errMess = [getTime(), ' Exposure and delay time set.'];
        %set(handles.outputWindow, 'String', [errMess; get(handles.outputWindow, 'String')]);
    end
end
set(handles.Shutter,'Enable','On')
% --- Executes during object creation, after setting all properties.
function Shutter_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on selection change in shuttermulti.
function shuttermulti_Callback(hObject, eventdata, handles)
global src shutterfactor
val = get(hObject,'Value');
str=get(hObject,'string');
shutter=round(get(handles.Shutter,'Value'));
try
    src.Timebase=val-1;
    basetable=load('cam_basetable.mat');
    shutterfactor=basetable.pike(val);
    src.timebase=val-1;
    src.Shutter=shutter;
    set(handles.shutter_text,'String',num2str(shutter*shutterfactor))
    set(handles.shutter_text,'value',shutter*shutterfactor)
catch
    set(hObject,'enable','off')
end


function shuttermulti_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function cgain_Callback(hObject, eventdata, handles)
global src
set(handles.cgain,'Enable','Off') 
gain=round(get(hObject,'Value'));
set(src,'Gain',gain)
pause(.1)
set(handles.cgain_text,'String',gain)
set(handles.cgain,'Enable','On') 

% --- Executes during object creation, after setting all properties.
function cgain_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in regpike.
function regpike_Callback(hObject, eventdata, handles)
mode=get(hObject,'string');
if strcmp(mode,'Register')
    cam_registerAVTMatlabAdaptor;
    set(hObject,'string','Deregister')
else
    h=imaqregister;
    if ~isempty(h)
        for a=1:length(h)
            imaqregister(cell2mat(h(a)),'unregister');
        end
    end
    set(hObject,'string','Register')
end


% --- Executes on button press in zoomin.
function zoomin_Callback(hObject, eventdata, handles)
global hzoom
status=get(hObject,'String');
xold=get(handles.vidscreen,'XLim');
yold=get(handles.vidscreen,'YLim');
if strcmp(status,'Zoom in')
    zoom off
    hzoom=zoom;
    set(hzoom,'rightclickaction','inversezoom')
    zoom out
    axis (handles.vidscreen,'equal')
    axis (handles.vidscreen, [xold yold])
    %set(handles.vidscreen,'XLim',xold)
    %set(handles.vidscreen,'YLim',yold)
    set(hzoom,'direction', 'in','enable','on') 
    set(hObject,'String','Zooming','foregroundcolor','r');
    set(handles.zoomout,'String','Zoom out','foregroundcolor','black');
    set(handles.panimage,'String','Pan','foregroundcolor','black');
else
    zoom off
    set(hObject,'String','Zoom in','foregroundcolor','black');
end
set(handles.vidscreen,'XTickmode','auto')
set(handles.vidscreen,'YTickmode','auto')


% --- Executes on button press in zoomout.
function zoomout_Callback(hObject, eventdata, handles)
status=get(hObject,'String');
if strcmp(status,'Zoom out')
    zoom off
    %h=zoom;
    zoom out
    axis (handles.vidscreen,'equal')
    %set(h,'direction', 'out','enable','on') 
    %set(hObject,'String','Zooming','foregroundcolor','r');
    set(handles.zoomin,'String','Zoom in','foregroundcolor','black');
    set(handles.panimage,'String','Pan','foregroundcolor','black');
else
    zoom off
    set(hObject,'String','Zoom out','foregroundcolor','black');
end
set(handles.vidscreen,'XTickmode','auto')
set(handles.vidscreen,'YTickmode','auto')

% --- Executes on button press in panimage.
function panimage_Callback(hObject, eventdata, handles)
status=get(hObject,'String');
if strcmp(status,'Pan')
    zoom off
    pan on
    set(hObject,'String','Panning','foregroundcolor','r');
    set(handles.zoomin,'String','Zoom in','foregroundcolor','black');
    set(handles.zoomout,'String','Zoom out','foregroundcolor','black');
else
    zoom off
    set(hObject,'String','Pan','foregroundcolor','black');
end
set(handles.vidscreen,'XTickmode','auto')
set(handles.vidscreen,'YTickmode','auto')

% --- Executes on button press in calib.
function calib_Callback(hObject, eventdata, handles)
global calibration

prompt = {'Enter pixel size:'};
dlg_title = 'Input calibration';
num_lines = 1;
def = {num2str(calibration)};
answer = inputdlg(prompt,dlg_title,num_lines,def);
if isempty(answer)
   return
else
    answer=str2num(cell2mat(answer));
end
if isempty(answer)
    return
else
    set(handles.calib_text,'string',[num2str(round(answer*1000)/1000),' micron/px'])
    calibration=answer;
    save('cam_calibration.txt','calibration','-ascii')
end

% --- Executes on button press in circle.
function circle_Callback(hObject, eventdata, handles)
global calibration
data = getimage(handles.vidscreen);
laserE=str2double(get(handles.laserE,'string'));
laserT=str2double(get(handles.laserT,'string'));
if ~isempty(data) 
    if data==0
    else
        %status=cam_encircled(data,calibration,laserE,laserT);
    end
    
end

% --- Executes on slider movement.
function refresh_Callback(hObject, eventdata, handles)
refresh=(get(hObject,'value')*10)/10
set(hObject,'value',refresh)
set(handles.refresh_text,'string',[num2str(refresh),'s'])

% --- Executes during object creation, after setting all properties.
function refresh_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on slider movement.
function contrast_Callback(hObject, eventdata, handles)
c=round(get(handles.contrast,'Value'));
l=round(get(handles.contrast_low,'Value'));
bit=getappdata(handles.vidscreen,'bit');
if c>bit
    set(handles.contrast,'Value',bit);
end
set(handles.contrast,'Max',bit);
set(handles.contrast_text,'string',num2str(c))
caxis(handles.vidscreen,[l c]);


% --- Executes on slider movement.
function contrast_low_Callback(hObject, eventdata, handles)
l=round(get(hObject,'Value'));
c=round(get(handles.contrast,'Value'));
bit=getappdata(handles.vidscreen,'bit');
if c>bit
    set(hObject,'Value',bit);
end
set(hObject,'Max',bit);
set(handles.contrast_low_text,'string',num2str(l))
caxis(handles.vidscreen,[l c]);

% --- Executes during object creation, after setting all properties.
function contrast_low_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function contrast_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on button press in logging.
function logging_Callback(hObject, eventdata, handles)

function iat_Callback(hObject, eventdata, handles)
global info vid src adaptor shutterfactor status dev
status=1;
iminfo=imaqhwinfo;
str = char(iminfo.InstalledAdaptors);
[s,v] = listdlg('PromptString','Select Adaptor:',...
                'SelectionMode','single',...
                'ListString',str);
if isempty(s)
    status=0;
    return
end

adaptor=strtrim(str(s,:));

try
devices=cell2mat(imaqhwinfo(adaptor,'deviceid'));
global devname
if max(devices)>1
    for a=1:length(devices)
        out=imaqhwinfo(adaptor,a);
        if a==1
            devname=char(char(out.DeviceName));
        else
            devname=char((devname), char(out.DeviceName));
        end
    end
    
    [s,v] = listdlg('PromptString','Select Adaptor:',...
                'SelectionMode','single',...
                'ListString',devname);
    if isempty(s)
        status=0;
        return
    end
    dev=s;
    
else
    dev=1;
end
info=imaqhwinfo(adaptor,dev);

vid=cam_init(adaptor,dev,char(info.SupportedFormats(3)));

src=getselectedsource(vid);

%set sliders and button
if strcmp(adaptor,'gentl')
    set(handles.Shutter,'Min',src.ExposureAutoMin)
    set(handles.Shutter,'Max',src.ExposureAutoMax)
    src.ExposureAutoMax
    %if shutterinfo.ConstraintValue(1)==0
    %    set(handles.Shutter,'SliderStep',[1/(src.ExposureAutoMax+1) 0.1])
    %else
        set(handles.Shutter,'SliderStep',[1/src.ExposureAutoMax 0.1])
    %end
    src.ExposureTime
    set(handles.Shutter,'value',src.ExposureTime)
    set(handles.shutter_text,'string',num2str(src.Exposuretime))
    shutterfactor=1;
    set(handles.Shutter,'Enable','On')
    try 
        timeinfo=propinfo(src,'ExposureAutoTimebase');
        times=timeinfo.ConstraintValue;
        for a=2:length(times)
            s=regexp(cell2mat(times(a)),'[0123456789]');
            str=cell2mat(times(a));
            timetable_lookup(a-1)=str2double(str(s));
        end
        set(handles.shuttermulti,'string',times(2:a));
        set(handles.shuttermulti,'Value',1);
        set(handles.shuttermulti,'Enable','On')
        times(2)
        src.ExposureAutoTimebase=cell2mat(times(2));
        shutterfactor=1;
    catch excpetion
        excpetion
        excpetion.stack.line
    end
else
try 
    src.shutter;
    shutterinfo=propinfo(src,'Shutter');
    set(handles.Shutter,'Min',shutterinfo.ConstraintValue(1))
    set(handles.Shutter,'Max',shutterinfo.ConstraintValue(2))
    if shutterinfo.ConstraintValue(1)==0
        set(handles.Shutter,'SliderStep',[1/(shutterinfo.ConstraintValue(2)+1) 0.1])
    else
        set(handles.Shutter,'SliderStep',[shutterinfo.ConstraintValue(1)/shutterinfo.ConstraintValue(2) 0.1])
    end
    set(handles.Shutter,'value',shutterinfo.DefaultValue(1))
    set(handles.shutter_text,'string',num2str(shutterinfo.DefaultValue(1)))
    src.shutter=shutterinfo.DefaultValue(1);
    shutterfactor=1;
    set(handles.Shutter,'Enable','On')
    try 
        timeinfo=propinfo(src,'Timebase');
        basetable=load('cam_basetable.mat');
        set(handles.shuttermulti,'string',basetable.pike);
        set(handles.shuttermulti,'Value',1);
        set(handles.shuttermulti,'Enable','On')
        src.Timebase=0;
        shutterfactor=1;
    end
    
catch
    'Shutter parameters not loaded!'
    set(handles.Shutter,'Enable','Off')
end
try 
    src.gain;
    gaininfo=propinfo(src,'Gain');
    set(handles.cgain,'Min',gaininfo.ConstraintValue(1))
    set(handles.cgain,'Max',gaininfo.ConstraintValue(2))
    if gaininfo.ConstraintValue(1)==0
        set(handles.cgain,'SliderStep',[1/(gaininfo.ConstraintValue(2)+1) 0.1])
    else
        set(handles.cgain,'SliderStep',[gaininfo.ConstraintValue(1)/gaininfo.ConstraintValue(2) 0.1])
    end
    set(handles.cgain,'value',gaininfo.DefaultValue(1))
    set(handles.cgain_text,'string',num2str(gaininfo.DefaultValue(1)))
    src.gain=gaininfo.DefaultValue(1);
    set(handles.cgain,'Enable','On')
catch
    set(handles.cgain,'Enable','Off')
end

set(handles.format,'string',info.SupportedFormats);
try 
    src.framerate;
    set(handles.frate,'string',set(src,'FrameRate'));
    set(handles.frate,'Enable','On')
catch
    set(handles.frate,'value',1);
    set(handles.frate,'string','Fixed');
end
end
vidRes = get(vid, 'VideoResolution');

set(handles.vidscreen,'Xlim',[0.5 vidRes(1)])
set(handles.vidscreen,'Xtick',round([0.5:vidRes(1)/10:vidRes(1),vidRes(1)]))
set(handles.vidscreen,'Ylim',[0.5 vidRes(2)])
set(handles.vidscreen,'Ytick',round([0.5:vidRes(2)/10:vidRes(2),vidRes(2)]))

axis on
%axis equal
catch exception
    status=0;
    exception
end

function pco_Callback(hObject, eventdata, handles)
global pco shutterfactor status
status=1;
[pco.hCam, err] = openPCO();
% Timebase constants
    pco.NS_BASE = 0;
    pco.US_BASE = 1;
    pco.MS_BASE = 2;
    pco.expTime = 30;
    pco.expBase = pco.MS_BASE;
    pco.ebText  = 'ms';
    pco.delTime = 0;
    pco.delBase = pco.MS_BASE;
    pco.dbText  = 'ms';
    % Default Min, Max preview intensities
    pco.intMin = 0;
    pco.intMax = 65535;
    % Boolean for if user wants to record single frame
    pco.recFrame = false;
% IMPORTANT
    % number of images to allocate to largeBuff
    % if using the system with 8 GB, change the
    % 1500 to 500, if using the system with 24 GB
    % this is fine, and so is any value < 1500
    pco.maxImages = int32(375);
    %variable for video playback
    pco.playback = 1;

    % if success
    if err == 0
        errMess = [getTime(), ' Camera communication initialized.']
        %set(handles.outputWindow, 'String', [errMess; get(handles.outputWindow, 'String')]);
    % else fail
    else
        errMess  = [getTime(), ' ERROR: ', getErrPCO(int32(err))];
        errMess2 = ['                    ', 'PLEASE RESTART THE CAMERA AND TRY AGAIN.']
        %set(handles.outputWindow, 'String', [errMess; get(handles.outputWindow, 'String')]);
        status=0;
        return
    end
    % Get ROI (default is full: 2560x2160)
    [pco.x0, pco.y0, pco.x1, pco.y1, err] = getROI_PCO(pco.hCam);
    if err ~=0
        errMess = [getTime(), ' ERROR: ', getErrPCO(int32(err))]
        %set(handles.outputWindow, 'String', [errMess; get(handles.outputWindow, 'String')]);
    else
        errMess = [getTime(), ' Default FULL ROI set.']
        %set(handles.outputWindow, 'String', [errMess; get(handles.outputWindow, 'String')]);
    end
    
    % Resolution in x, y
    pco.xSize = uint16(pco.x1-pco.x0+1);
    pco.ySize = uint16(pco.y1-pco.y0+1);
    
    % Set Cam Link Image Parameters
    err = setCLIP_PCO(pco.hCam, pco.xSize, pco.ySize);
    if err ~=0
        errMess = [getTime(), ' ERROR: ', getErrPCO(int32(err))]
        %set(handles.outputWindow, 'String', [errMess; get(handles.outputWindow, 'String')]);
    else
        errMess = [getTime(), ' CamLink image parameters set.']
        %set(handles.outputWindow, 'String', [errMess; get(handles.outputWindow, 'String')]);
    end
    
    % Set Default Times
    err = setDelExpPCO(pco.hCam, uint32(pco.delTime), uint32(pco.expTime), uint16(pco.delBase), uint16(pco.expBase));
    if err ~=0
        errMess = [getTime(), ' ERROR: ', getErrPCO(int32(err))]
        %set(handles.outputWindow, 'String', [errMess; get(handles.outputWindow, 'String')]);
    else
        errMess = [getTime(), ' Default exposure and delay time set.']
        %set(handles.outputWindow, 'String', [errMess; get(handles.outputWindow, 'String')]);
    end
    
    % Get Camera Times
    [pco.delTime, pco.expTime, pco.delBase, pco.expBase, err] = getDelExpPCO(pco.hCam);
    if err ~=0
        errMess = [getTime(), ' ERROR: ', getErrPCO(int32(err))]
        %set(handles.outputWindow, 'String', [errMess; get(handles.outputWindow, 'String')]);
    else
        if pco.delBase == pco.NS_BASE
            pco.dbText = 'ns';
        elseif pco.delBase == pco.US_BASE
            pco.dbText = 'us';
        elseif pco.delBase == pco.MS_BASE
            pco.dbText = 'ms';
        end
        
        if pco.expBase == pco.NS_BASE
            pco.ebText = 'ns';
        elseif pco.expBase == pco.US_BASE
            pco.ebText = 'us';
        elseif pco.expBase == pco.MS_BASE
            pco.ebText = 'ms';
        end
        
        set(handles.Shutter,'Min',1)
        set(handles.Shutter,'Max',100)
        set(handles.Shutter,'SliderStep',[1/101 0.1])
        set(handles.Shutter,'value',pco.expTime)
        set(handles.shutter_text,'string',[num2str(pco.expTime),'ms'])
        set(handles.Shutter,'Enable','On')
        shutterfactor=1;
        %set(delText, 'String', ['Delay Time: ', num2str(delTime), ' ', dbText]);
    end
    
    % allocate 2 frame buffers
    [pco.fp1, pco.sbn1, pco.hbuf1, err] = getSingleFramePointerPCO(pco.hCam, pco.xSize, pco.ySize);
    if err ~= 0
        errMess = [getTime(), ' ERROR: ', getErrPCO(int32(err))]
        %set(handles.outputWindow, 'String', [errMess; get(handles.outputWindow, 'String')]);
    end
    
    [pco.fp2, pco.sbn2, pco.hbuf2, err] = getSingleFramePointerPCO(pco.hCam, uint16(pco.x1-pco.x0+1), uint16(pco.y1-pco.y0+1));
    if err ~= 0
        errMess = [getTime(), ' ERROR: ', getErrPCO(int32(err))];
        %set(handles.outputWindow, 'String', [errMess; get(handles.outputWindow, 'String')]);
    end
    
    % allocate 1500 images worth of mem at full ROI
    % if cannot allocate, try reducing maxImages (above)
    [pco.largeBuff, err] = setupMemPCO(pco.maxImages);
    if err ~= 0
        errMess = [getTime(), ' ERROR: Unable to allocate memory, restart matlab and try again,']
        errMess2 = ['                    ', 'if this does not work, lower "maxImages" in code and try again.']
        %set(outputWindow, 'String', [errMess; errMess2; get(outputWindow, 'String')]);
    else
        errMess = [getTime(), ' Acquisition Memory allocated.']
        %set(handles.outputWindow, 'String', [errMess; get(handles.outputWindow, 'String')]);
    end
    
    
function [timeString] = getTime()
    time       = clock;
    timeString = [num2str(time(1,4),'%02d'), ':', num2str(time(1,5),'%02d'),...
        ':', num2str(round(time(1,6)),'%02d'), ' >> '];
    
    function camomatic_CloseRequestFcn(hObject, eventdata, handles)
global vid camtype pco
delete(vid)
if camtype==2
    cam_closePCO(pco)
end
delete(hObject);
clear all

function laser_params_Callback(hObject, eventdata, handles)
param=get(hObject,'tag');
value=str2double(get(hObject,'string'));
error=0;
if isnan(value)
    error=1;
else
    if value<0
    error=1;
    end
end

if error==1    
    if strcmp(param,'laserE')
        set(hObject,'string','80')
    elseif strcmp(param,'laserT')
        set(hObject,'string','550')
    end
end

% --- Executes during object creation, after setting all properties.
function laserE_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

    % --- Executes during object creation, after setting all properties.
function laserT_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in blacklist.
function blacklist_Callback(hObject, eventdata, handles)
bdata = getimage(handles.vidscreen);
blevel=str2double(get(handles.blacklevel,'string'))

bdata(bdata<blevel)=0;
setappdata(handles.vidscreen,'bdata',bdata)
figure
imagesc(bdata)


function blacklevel_Callback(hObject, eventdata, handles)
if isnan(str2double(get(hObject,'string')))
    set(hObject,'string',getappdata(handles.vidscreen,'bit')+1)
end


% --- Executes during object creation, after setting all properties.
function blacklevel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to blacklevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in blackstatus.
function blackstatus_Callback(hObject, eventdata, handles)
% hObject    handle to blackstatus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of blackstatus


% --- Executes on button press in fft_mode.
function fft_mode_Callback(hObject, eventdata, handles)
% hObject    handle to fft_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of fft_mode
