function registerAVTMatlabAdaptor()
% -------------------------------
% register AVT Adaptor for Matlab
% -------------------------------
global exception
    [filename, pathname] = uigetfile('AVTMatlabAdaptor_R2010a.dll', 'Select adaptor file');
    AVTadaptor = strcat(pathname,filename)
    if isempty(AVTadaptor)
    else
        try
        h=imaqregister(AVTadaptor,'register');
        msgbox([cell2mat(h),' loaded successfully'])
        catch exception
             %errordlg(exception.message,'Uups, there is problem!');
             
             % Construct a questdlg with three options
             choice = questdlg([filename, ' could not be loaded.', exception.message,...
                 ' What do you wann do!'],'Error!',...
            'Fix it!','Give up!','Give up!');
            % Handle response
            switch choice
            case 'Fix it!'
                    h=imaqregister;
                    if ~isempty(h)
                        for a=1:length(h)
                        imaqregister(cell2mat(h(a)),'unregister');
                        end
                        msgbox(['Looks good. I unloaded ', cell2mat(h), ' Please, try again!'])
                    else
                        msgbox('Sorry, nothing to fix.') 
                    end
            end
            switch choice
            case 'Give up!'
            end
              
        end
    end

% ----------------
% refresh adaptorinfo
% ----------------
imaqreset

% ----------------
% cancel matlab 
% ----------------
end