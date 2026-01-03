function somma_dadi = estrai_dadi(frame_originale, namev, numf)
    % Rilevamento Macro-Aree
    mask = cart_dadi(frame_originale);
    mask = imclearborder(mask);
    maschera_macro = trova_picchi_watershed(frame_originale, mask);
    
    raggio_bollino = 20; 
    if size(frame_originale, 3) == 3
        img_gray = rgb2gray(frame_originale);
    else
        img_gray = frame_originale;
    end
    
    somma_dadi = 0; 
    [L, num_oggetti] = bwlabel(maschera_macro);
    
    % --- 1. FASE DI CALCOLO (Nessun disegno qui) ---
    
    % Creiamo una struttura per salvare i risultati di questo frame
    dadi_rilevati = struct('bbox', {}, 'centro', {}, 'valore', {});
    conteggio = 0;

    for i = 1:num_oggetti
        dado_mask = (L == i);
        
        % Logica Baricentro
        dado_core = imerode(dado_mask, strel('disk', 5, 0));
        if sum(dado_core(:)) == 0, dado_core = dado_mask; end 
        
        props = regionprops(dado_core, img_gray, 'WeightedCentroid');
        
        if ~isempty(props)
            centro = props.WeightedCentroid;
            c_x = round(centro(1));
            c_y = round(centro(2));
            
            % Crop
            mask_punto = false(size(maschera_macro));
            mask_punto(c_y, c_x) = true;
            mask_cerchio = imdilate(mask_punto, strel('disk', raggio_bollino, 0));
            
            props_box = regionprops(mask_cerchio, 'BoundingBox');
            if isempty(props_box), continue; end
            bbox = props_box(1).BoundingBox;
            
            img_crop = imcrop(frame_originale, bbox);
            alpha_crop = imcrop(mask_cerchio, bbox);
            
            % Estrazione Maschera Numero
            mask_numero = estrai_cifra(img_crop, alpha_crop);
            
            % Se la maschera è valida, chiama il KNN
            if sum(mask_numero(:)) > 5 
                valore = decodifica_cifra(mask_numero);
                
                % SALVIAMO IL RISULTATO IN MEMORIA
                conteggio = conteggio + 1;
                dadi_rilevati(conteggio).bbox = bbox;
                dadi_rilevati(conteggio).centro = [c_x, c_y];
                dadi_rilevati(conteggio).valore = valore;
                
                somma_dadi = somma_dadi + valore;
            end
        end
    end
    
    % --- 2. FASE DI VISUALIZZAZIONE (Disegno unico finale) ---
    
    % Usa figure(100) per mantenere sempre la stessa finestra e non aprirne 1000
    figure; 
    clf; % Pulisce la finestra dal frame precedente
    
    % SINISTRA: Immagine Originale Pulita
    subplot(1, 2, 1);
    imshow(frame_originale);
    title(['Frame ' num2str(numf) ' - Originale']);
    
    % DESTRA: Immagine con Sovraimpressioni
    subplot(1, 2, 2);
    imshow(frame_originale);
    hold on;
    title(['Rilevamento - Somma: ' num2str(somma_dadi)]);
    
    % Disegniamo tutti i dadi trovati
    for k = 1:length(dadi_rilevati)
        d = dadi_rilevati(k);
        
        % Rettangolo Blu
        rectangle('Position', d.bbox, 'EdgeColor', 'b', 'LineWidth', 2);
        
        % Numero Giallo
        text(d.centro(1), d.centro(2), num2str(d.valore), ...
            'Color', 'y', 'FontSize', 22, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center');
    end
    hold off;
    
    % Forza l'aggiornamento grafico
    drawnow;
end

% =========================================================
%  FUNZIONE ESTRAI_CIFRA (Logica "Recupero Totale")
% =========================================================
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