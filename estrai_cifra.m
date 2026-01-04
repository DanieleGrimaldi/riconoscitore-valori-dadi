function mask_finale = estrai_cifra(img_rgb, alpha)
    % Questa funzione implementa K-Means + Logica Baricentro
    % (È la versione "Recupero Totale" che abbiamo perfezionato)

    min_area = 20; % Soglia minima area (più bassa qui perché l'img è piccola)

    % 1. Pulizia Input
    if size(img_rgb, 3) == 4, img_rgb = img_rgb(:,:,1:3); end
    
    % Gestione Alpha (se vuoto crea un dummy)
    if isempty(alpha)
        alpha = ones(size(img_rgb,1), size(img_rgb,2)); 
        alpha([1,end],:) = 0; alpha(:,[1,end]) = 0;
    end

    % 2. K-Means (LAB) su TUTTA l'immagine ritagliata
    % Nota: Usiamo try-catch o replicates 1 per velocità e sicurezza su img piccole
    try
        lab = rgb2lab(img_rgb);
        ab = double(lab);
        nrows = size(ab,1); ncols = size(ab,2);
        data = reshape(ab, nrows*ncols, 3);
        
        [idx, ~] = kmeans(data, 2, 'Distance', 'sqeuclidean', 'Replicates', 1);
        pixel_labels = reshape(idx, nrows, ncols);
    catch
        % Se K-means fallisce (img troppo piccola o uniforme), restituisci vuoto
        mask_finale = false(size(alpha));
        return;
    end
    
    % 3. Identificazione Sfondo (tramite Alpha del cerchio)
    mask_trasparente = (alpha == 0);
    
    pixel_nella_trasparenza = pixel_labels(mask_trasparente);
    bg_cluster = mode(pixel_nella_trasparenza);
    
    % 4. Maschera Grezza (TUTTO ciò che non è sfondo)
    mask_raw = (pixel_labels ~= bg_cluster);

    % 5. Selezione Baricentro (Conn 4)
    cc = bwconncomp(mask_raw, 4); 
    stats = regionprops(cc, 'Area', 'Centroid', 'PixelIdxList');
    valid_indices = find([stats.Area] >= min_area);
    
    if isempty(valid_indices)
        mask_finale = false(nrows, ncols);
        return;
    end
    
    % Trova l'oggetto più centrale nel ritaglio
    img_center = [ncols/2, nrows/2]; 
    best_idx = -1; 
    min_dist = Inf;
    
    for k = valid_indices
        dist = norm(stats(k).Centroid - img_center);
        if dist < min_dist
            min_dist = dist;
            best_idx = k;
        end
    end
    
    % 6. Ricostruzione Finale
    mask_finale = false(nrows, ncols);
    mask_finale(stats(best_idx).PixelIdxList) = true;

end