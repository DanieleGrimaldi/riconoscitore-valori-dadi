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
            
            salva_dump(img_crop, alpha_crop, namev, numf, i);

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

function salva_dump(img_rgb, alpha_mask, video_name, frame_idx, dado_idx)
    % SALVA_DUMP
    % Salva il ritaglio come PNG usando il parametro 'Alpha' di imwrite
    
    output_dir = fullfile('test', 'numeri');
    
    % Crea la cartella se non esiste
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    % 1. Preparazione Alpha (deve essere uint8 o double)
    if islogical(alpha_mask)
        alpha_channel = uint8(alpha_mask) * 255;
    else
        alpha_channel = im2uint8(alpha_mask);
    end

    % 2. Preparazione Immagine RGB
    % Se è in scala di grigi, la convertiamo in RGB per sicurezza
    if size(img_rgb, 3) == 1
        img_to_save = cat(3, img_rgb, img_rgb, img_rgb);
    else
        img_to_save = img_rgb; % È già RGB (MxNx3)
    end

    % 3. Nome file univoco
    [~, v_name, ~] = fileparts(video_name);
    fname = sprintf('%s_f%d_d%d.png', v_name, frame_idx, dado_idx);
    full_path = fullfile(output_dir, fname);
    
    % 4. Scrittura su disco (CORRETTA)
    % Passiamo l'immagine RGB come primo argomento
    % Passiamo il canale Alpha separatamente con il tag 'Alpha'
    try
        imwrite(img_to_save, full_path, 'Alpha', alpha_channel);
    catch ME
        fprintf('Errore salvataggio dump: %s\n', ME.message);
    end
end