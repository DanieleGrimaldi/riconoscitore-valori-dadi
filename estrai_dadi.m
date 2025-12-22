function mask_finale = estrai_dadi(frame_originale, lab_frame_small, lab_sfondo_small)
    % --- 1. CANDIDATI (Differenza + ROI) ---
    % Maschera Grezza (Sottrazione)
    mask_diff = mask_grezza(frame_originale, lab_frame_small, lab_sfondo_small);
    
    % Maschera Vassoio (Geometrica)
    mask_roi = trova_maschera_vassoio(frame_originale);
    
    % La "Maschera Precedente" a cui ti riferisci:
    mask_candidati = mask_diff & mask_roi; 
    
    % --- 2. INPUT CART ---
    % Creiamo l'immagine nera, accesa solo dove c'è la mask_candidati
    img_per_cart = frame_originale;
    mask_3d = repmat(mask_candidati, [1 1 3]);
    img_per_cart(~mask_3d) = 0; 
    
    % --- 3. PREDIZIONE CART ---
    mask_cart_raw = cart_dadi(img_per_cart);
    
    % --- 4. LA CORREZIONE CHE CHIEDI ---
    % Qui applichiamo la logica di sicurezza.
    % Se il CART ha sbagliato e ha messo a 1 lo sfondo nero, questo passaggio lo taglia via.
    mask_finale = mask_cart_raw & mask_candidati;
    
    % --- 5. PULIZIA FINALE ---
    mask_finale = imfill(mask_finale, 'holes');
    mask_finale = imopen(mask_finale, strel('disk', 8));
    mask_finale = bwareaopen(mask_finale, 150);
    % --- VISUALIZZAZIONE ---
    img_masked = frame_originale;
    img_masked(repmat(~mask_finale, [1 1 3])) = 0;
    
    figure;
    subplot(1, 2, 1); imshow(frame_originale);
    subplot(1, 2, 2); imshow(img_masked);
    drawnow;
end


function mask_finale = mask_grezza(frame_originale, lab_frame_small, lab_sfondo_small)
    % 1. ESTRAZIONE DI TUTTI I CANALI (L, A, B)
    % L = Luminosità (0=Nero, 100=Bianco)
    % A = Verde-Rosso
    % B = Blu-Giallo
    
    L_curr = lab_frame_small(:,:,1);
    a_curr = lab_frame_small(:,:,2); 
    b_curr = lab_frame_small(:,:,3);
    
    L_bg   = lab_sfondo_small(:,:,1);
    a_bg   = lab_sfondo_small(:,:,2); 
    b_bg   = lab_sfondo_small(:,:,3);
    
    % 2. CALCOLO DISTANZA 3D COMPLETA (Luce + Colore)
    % Ora se un oggetto è dello stesso colore ma più chiaro/scuro, viene rilevato.
    % Usiamo un fattore di correzione per L: spesso le ombre cambiano L ma non vogliamo rilevarle.
    % Dividere L per 2 o 3 aiuta a dare priorità al colore ma sentire comunque il bianco/nero.
    
    peso_Luce = 0.5; % Se metti 1.0 conta la luce al 100%, se metti 0.5 ignora un po' le ombre
    diff_L = (L_curr - L_bg) * peso_Luce;
    diff_A = (a_curr - a_bg);
    diff_B = (b_curr - b_bg);
    
    distanza = sqrt( diff_L.^2 + diff_A.^2 + diff_B.^2 );
    
    % 3. SOGLIA
    SOGLIA_GLOBALE = 3; 
    
    mask_small = distanza > SOGLIA_GLOBALE;
    
    % 4. PULIZIA
    mask_small = bwareaopen(mask_small, 5);     % Via i puntini
    mask_small = imfill(mask_small, 'holes');   % Chiudi i buchi (es. numeri sui dadi)
    mask_small = imdilate(mask_small, strel('disk', 2));
    
    % 5. REINGRANDIMENTO
    mask_finale = imresize(mask_small, [size(frame_originale,1), size(frame_originale,2)], 'nearest');
    
end