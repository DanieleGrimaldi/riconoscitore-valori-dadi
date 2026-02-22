function mask_finale = estrai_cifra(img, mask)

    img = quantizzazione_colore(img);
    img = filtro_mediano_colori(img);
    %volevo usare isodata ma non ho capito come implementarlo
    dati_dbscan = prepara_dati_dbscan(img, mask);
    labels = mio_dbscan(dati_dbscan);

    mappa_label = zeros(size(mask));
    mappa_label(mask) = labels;
    mappa_label = separa_cluster_disconnessi(mappa_label);
    mask_finale = scegli_cluster(mappa_label);
    mask_finale = mask_finale > 0;
    %salva_maschera(mappa_label);
    %stampa_cluster(img, mappa_label);

end

function data_dbscan = prepara_dati_dbscan(img, mask)
    
    img_lab = rgb2lab(img);
    
    L = img_lab(:,:,1);
    A = img_lab(:,:,2);
    B = img_lab(:,:,3);
    
    % La funzione "find" ci dà la riga (Y) e la colonna (X) di ogni pixel bianco della mask
    [Y_val, X_val] = find(mask);
    
    % 3. Estraiamo i colori SOLO di quei pixel validi
    L_val = L(mask);
    A_val = A(mask);
    B_val = B(mask);
    
    L_norm = (L_val - min(L_val)) / (max(L_val) - min(L_val) + eps);
    A_norm = (A_val - min(A_val)) / (max(A_val) - min(A_val) + eps);
    B_norm = (B_val - min(B_val)) / (max(B_val) - min(B_val) + eps);
    X_norm = (double(X_val) - min(X_val)) / (max(X_val) - min(X_val) + eps);
    Y_norm = (double(Y_val) - min(Y_val)) / (max(Y_val) - min(Y_val) + eps);
    
    peso_L = 1;
    varianza_ab = var(A_val) + var(B_val);

    if varianza_ab < 20
        peso_L = 2;
    end 

    data_dbscan = [L_norm * peso_L , A_norm, B_norm, X_norm*2, Y_norm*2];
    
end

function mappa_filtrata = scegli_cluster(mappa_label)
    
    mappa_filtrata = mappa_label;
    
    % --- 1. FILTRO DIMENSIONALE (Invariato) ---
    cluster_unici = unique(mappa_label(mappa_label > 0));
    
    for i = 1:length(cluster_unici)
        id_c = cluster_unici(i);
        area_c = sum(mappa_label(:) == id_c);
        
        if area_c < 70 || area_c > 500
            mappa_filtrata(mappa_filtrata == id_c) = 0;
        end
    end
    
    % --- 2. FILTRO DI CENTRALITÀ E COMPATTEZZA ---
    cluster_rimasti = unique(mappa_filtrata(mappa_filtrata > 0));
    
    if length(cluster_rimasti) > 1
        
        [h, w] = size(mappa_label);
        centro_img = [w/2, h/2];
        
        best_score = Inf;
        vincitore = -1;
        
        for i = 1:length(cluster_rimasti)
            id_c = cluster_rimasti(i);
            
            [y_p, x_p] = find(mappa_filtrata == id_c);
            
            % 1. Calcolo del Baricentro
            baricentro = [mean(x_p), mean(y_p)];
            
            % 2. Distanza dal centro dell'immagine (Centralità)
            distanza_centro = norm(baricentro - centro_img);
            
            % 3. Calcolo della DISPERSIONE INTERNA (Compattezza)
            % Distanza euclidea di ogni pixel del cluster dal suo stesso baricentro
            distanze_interne = sqrt((x_p - baricentro(1)).^2 + (y_p - baricentro(2)).^2);
            dispersione = mean(distanze_interne);
            
            % 4. SCORE FINALE (Vogliamo minimizzarlo)
            % Moltiplichiamo la dispersione per 2 per "punire" severamente il rumore sparpagliato
            score = distanza_centro + (dispersione * 2.0);
            
            % fprintf('Cluster %d -> Dist: %.1f | Disp: %.1f | SCORE: %.1f\n', id_c, distanza_centro, dispersione, score);
            
            if score < best_score
                best_score = score;
                vincitore = id_c;
            end
        end
        
        % Isoliamo il vincitore
        for i = 1:length(cluster_rimasti)
            id_c = cluster_rimasti(i);
            if id_c ~= vincitore
                mappa_filtrata(mappa_filtrata == id_c) = 0;
            end
        end
    end
end

function img_quantizzata = quantizzazione_colore(img)

    numero_colori = 8;
    
    [img_ind, mappa_colori] = rgb2ind(img, numero_colori, 'nodither');

    img_quantizzata = uint8(ind2rgb(img_ind, mappa_colori) * 255);
end

function salva_maschera(mask_finale)
    cartella_destinazione = 'Maschere_Cifre';
    
    if ~exist(cartella_destinazione, 'dir')
        mkdir(cartella_destinazione);
    end
    
    file_presenti = dir(fullfile(cartella_destinazione, 'cifra_*.png'));
    

    prossimo_indice = length(file_presenti) + 1;
    
    nome_file = sprintf('cifra_%03d.png', prossimo_indice);
    percorso_completo = fullfile(cartella_destinazione, nome_file);
    
    mask_finale = mask_finale > 0;
    imwrite(mask_finale, percorso_completo);
    
end

function nuova_mappa = separa_cluster_disconnessi(mappa_label)

    nuova_mappa = zeros(size(mappa_label));
    
    cluster_unici = unique(mappa_label(mappa_label > 0));
    
    nuovo_id = 1;
    
    for i = 1:length(cluster_unici)
        id_corrente = cluster_unici(i);
        
        mask_cluster = (mappa_label == id_corrente);
        
        [etichette_locali, num_sotto_forme] = bwlabel(mask_cluster, 8);

        for j = 1:num_sotto_forme

            nuova_mappa(etichette_locali == j) = nuovo_id;

            nuovo_id = nuovo_id + 1;
        end
    end
   
end

function img_filtrata = filtro_mediano_colori(img)
    % Applica il filtro mediano a ciascun canale dell'immagine RGB
    img_filtrata = img;
    
    % Finestra 5x5: pialla il rumore senza sfocare i bordi della cifra
    finestra = [3 3]; 
    
    % Eseguiamo il filtraggio separatamente su Red, Green e Blue
    for c = 1:3
        img_filtrata(:,:,c) = medfilt2(img(:,:,c), finestra);
    end
end