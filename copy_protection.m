if exist('caml.mat','file')
    dexpire = datenum('31-Jan-2011', 'dd-mmm-yyyy');
    cdate=datenum(date);
    checkold = load('caml.mat');
    try
        checksum=hex2num(checkold.check)/732979;
    catch
        checksum=0;
    end
    if checksum<dexpire && checksum>=cdate
        check=num2hex(cdate*732979);
        save('caml','check');
	elseif checksum<dexpire && checksum<cdate
        check=num2hex(dexpire*732979);
        save('caml','check');
        h = errordlg('Changed date, expired');
        close all
        return
    else
        h = errordlg('Expiration date reached, expired');
        close all
        return
	end
else
    h = errordlg('License not found, expired');
    close all
    return
end