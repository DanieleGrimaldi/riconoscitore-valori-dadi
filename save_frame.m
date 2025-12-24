function save_frame(img,frameNumber,videoName,nomCart)
    % Verifica che la cartella esista (per sicurezza)
    if ~exist(nomCart, 'dir')
        mkdir(nomCart);
    end

    % 1. Costruzione nome file: frame/video_00123.jpg
    full_path = sprintf('%s/%s_%05d.jpg', nomCart, videoName, frameNumber);
    
    % 2. Salvataggio fisico
    imwrite(img, full_path);
    

end