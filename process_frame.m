function process_frame( filename, frameNumber, videoFrame)

    persistent lastFrameResize stableCount  
    

    SOGLIA_MOVIMENTO = 0.65;  % Sotto questo valore, consideriamo che è fermo
    FRAME_ATTESA     = 35;   % Quanti frame fermi aspettare prima di scattare

    videoFrameResize= rgb2lab(imresize(videoFrame, 0.25));

    %% Inizializzazione (solo al primo giro)
    if isempty(lastFrameResize)
        lastFrameResize = videoFrameResize;
        stableCount = 0;
        return; 
    end

    movimento = calcola_movimento(videoFrameResize, lastFrameResize);
    
    lastFrameResize = videoFrameResize; 
    
    %%
    if movimento < SOGLIA_MOVIMENTO
        stableCount = stableCount + 1;

        if stableCount == FRAME_ATTESA
            %analizza_dadi(videoFrame,frameNumber,filename);
            save_frame(videoFrame,frameNumber,filename);
        end

    else
        stableCount = 0;
    end

end



