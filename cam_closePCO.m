function cam_closepco(pco)
        
        % make sure preview is off
        %if get(previewBox, 'Value') == 1
        %    waitfor(warndlg('Please turn off Live Preview before exiting.'));
        %    return;
        %end
        % free buffer 1
        err = setRecStatePCO(pco.hCam, uint16(0))
        err = freeBufferPCO(pco.hCam, pco.sbn1);
        if err ~=0
            try
                getErrPCO(int32(err))
            end
        end
        
        % free buffer 2
        err = freeBufferPCO(pco.hCam, pco.sbn2);
        if err ~=0
            try
                getErrPCO(int32(err))
            end
        end
        
        % free acquisition memory
        freeMem_pco(pco.largeBuff, pco.maxImages);
        'Acquisition memory deallocated.'
        
        err = closePCO(pco.hCam);
        if err ~=0
            try
                getErrPCO(int32(err))
            end
        else
        'Camera communication terminated.'
        end
        'Please wait for system to shutdown.'
    end