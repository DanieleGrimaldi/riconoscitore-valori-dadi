function save_frame(img,frameNumber,videoName)
    % Verifica che la cartella esista (per sicurezza)
    if ~exist('frame', 'dir')
        mkdir('frame');
    end

    % 1. Costruzione nome file: frame/video_00123.jpg
    full_path = sprintf('frame/%s_%05d.jpg', videoName, frameNumber);
    
    % 2. Salvataggio fisico
    imwrite(img, full_path);
    

end