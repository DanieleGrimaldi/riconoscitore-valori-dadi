function somma_dadi = estrai_dadi(frame_originale,namev,numf)

    mask = cart_dadi(frame_originale);

    mask = imclearborder(mask);

    maschera_pulita = trova_picchi_watershed(frame_originale, mask);

    salva_dadi(frame_originale, maschera_pulita, namev, numf);

    dadi_isolati = frame_originale;
    mask_3d = repmat(mask, [1, 1, 3]);
    dadi_isolati(~mask_3d) = 0;

    %{
    % --- 4. VISUALIZZAZIONE ---
    figure('Name', 'Estrazione Centri Dadi');
    
    % Subplot 1: Immagine Originale + Contorni Centri
    subplot(1, 2, 1);
    imshow(frame_originale); 
    hold on;
    % Visboundaries disegna i contorni della maschera sull'immagine RGB
    visboundaries(mask, 'Color', 'g', 'LineWidth', 2);
    title('Dadi Rilevati (Verde = Centro)');
    
    % Subplot 2: Maschera Finale (Bianco e Nero)
    subplot(1, 2, 2);
    imshow(dadi_isolati);
    title('Maschera Centri (Erosa & No Bordi)');
    
    % Feedback in console
    num_dadi = bwconncomp(mask).NumObjects;
    fprintf('Dadi validi trovati (centri): %d\n', num_dadi);
    %}
    somma_dadi = 10;
end

function salva_dadi(immagine_originale, maschera_separata, namev, numf)
    % SALVA_DADI - Versione "ANTI-OMBRA" con Salvataggio Trasparente
    % Salva solo i pixel del cerchio centrale ("bollino"), rendendo trasparente il resto.
    
    % --- CONFIGURAZIONE ---
    cartella_out = 'numeri';
    if ~exist(cartella_out, 'dir'), mkdir(cartella_out); end
    
    raggio_bollino = 15; % Raggio del cerchio da salvare
    
    % 1. Prepara immagine grigia per calcolo luce
    if size(immagine_originale, 3) == 3
        img_gray = rgb2gray(immagine_originale);
    else
        img_gray = immagine_originale;
    end
    
    % 2. Etichettatura dadi
    [L, num_oggetti] = bwlabel(maschera_separata);
    
    % 3. CICLO SU OGNI DADO
    for i = 1:num_oggetti
        dado_mask = (L == i);
        
        % --- STEP A: SBUCCIATURA (Peeling) ---
        % Rimuove l'ombra esterna per non falsare il centro
        dado_core = imerode(dado_mask, strel('disk', 5, 0));
        
        % Sicurezza: se il dado scompare, annulla l'erosione
        if sum(dado_core(:)) == 0
            dado_core = dado_mask;
        end
        
        % --- STEP B: BARICENTRO PESATO (Weighted Centroid) ---
        % Trova il centro della luce (il numero)
        props = regionprops(dado_core, img_gray, 'WeightedCentroid');
        
        if ~isempty(props)
            centro = props.WeightedCentroid;
            c_x = round(centro(1));
            c_y = round(centro(2));
            
            % Controlli bordi
            c_x = max(1, min(c_x, size(maschera_separata, 2)));
            c_y = max(1, min(c_y, size(maschera_separata, 1)));
            
            % --- STEP C: SALVATAGGIO DEI SOLI PIXEL DEL CERCHIO ---
            
            % 1. Creiamo la maschera del "bollino" su tutta l'immagine
            mask_punto = false(size(maschera_separata));
            mask_punto(c_y, c_x) = true;
            mask_cerchio = imdilate(mask_punto, strel('disk', raggio_bollino, 0));
            
            % 2. Troviamo il rettangolo minimo per ritagliare il file piccolo
            props_box = regionprops(mask_cerchio, 'BoundingBox');
            
            if ~isempty(props_box)
                bbox = props_box(1).BoundingBox;
                
                % 3. Ritagliamo l'Immagine (Colori)
                img_crop = imcrop(immagine_originale, bbox);
                
                % 4. Ritagliamo la Maschera (Trasparenza)
                % Questa maschera dice al PNG quali pixel mostrare e quali nascondere
                alpha_crop = imcrop(mask_cerchio, bbox);
                
                % 5. Salvataggio con Canale Alpha
                nome_file = sprintf('%s_f%04d_d%d.png', namev, numf, i);
                path_completo = fullfile(cartella_out, nome_file);
                
                % Scriviamo il file: 'Alpha' rende trasparente tutto ciò che è nero nella maschera
                imwrite(img_crop, path_completo, 'Alpha', double(alpha_crop));
            end
        end
    end
end