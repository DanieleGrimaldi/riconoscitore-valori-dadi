function process_frame( filename, frameNumber, videoFrame)

    persistent lastFrameResize stableCount background lastVideoName
    
    SOGLIA_MOVIMENTO = 0;  % Sotto questo valore, consideriamo che è fermo
    FRAME_ATTESA     = 17;   % Quanti frame fermi aspettare prima di scattare

    videoFrameResize= rgb2lab(imresize(videoFrame, 0.0625));

    %% Inizializzazione (solo al primo giro)
    if isempty(lastFrameResize) || ~strcmp(filename, lastVideoName)
        lastFrameResize = videoFrameResize;
        background  = videoFrameResize;
        stableCount = 0;
        lastVideoName = filename;
        return; 
    end

    movimento = calcola_movimento(videoFrameResize, lastFrameResize);

    %{
    fprintf('\n');
    fprintf(num2str(frameNumber));
    fprintf(' ');
    fprintf(num2str(movimento));
    %}

    lastFrameResize = videoFrameResize; 
    %%
    if movimento == SOGLIA_MOVIMENTO
        stableCount = stableCount + 1;

        if stableCount == FRAME_ATTESA
            mov_background = calcola_movimento(videoFrameResize, background);
            if mov_background > SOGLIA_MOVIMENTO
                %save_frame(videoFrame,frameNumber,filename,"frame");
                dadi = estrai_dadi(videoFrame,videoFrameResize,background,filename,frameNumber);

            end
        end

    else
        stableCount = 0;
    end
end