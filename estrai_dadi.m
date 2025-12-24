function mask_finale = estrai_dadi(frame_originale, lab_frame_small, lab_sfondo_small,namev,numf)
    
    % --- STEP 1: Maschera Grezza (Sottrazione) ---
    mask_diff = mask_grezza(frame_originale, lab_frame_small, lab_sfondo_small);
    %{
    figure; clf; 
    imshow(mask_diff); 
    title('Step 1: Maschera Grezza (Differenza Colore/Luce)');
    %}
    % --- STEP 2: Maschera Vassoio (ROI) ---
    mask_roi = trova_maschera_vassoio(frame_originale);

    %{
    figure; clf;
    imshow(mask_roi); 
    title('Step 2: Maschera Vassoio (ROI)');
    %}

    % --- STEP 3: Maschera Candidati (Intersezione) ---
    % Manteniamo solo ciò che si muove DENTRO il vassoio
    mask_candidati = mask_diff & mask_roi; 
    
    %{
    figure; clf;
    imshow(mask_candidati); 
    title('Step 3: Candidati (Diff & ROI)');
    %}
    % --- STEP 4: Input al CART ---
    % Oscuriamo tutto il resto per nutrire il modello
    img_per_cart = frame_originale;
    mask_3d = repmat(mask_candidati, [1 1 3]);
    img_per_cart(~mask_3d) = 0; 
    
    %{
    figure; clf;
    imshow(img_per_cart); 
    title('Step 4: Immagine passata al CART (Nero attorno)');
    %}
    % --- STEP 5: Output Grezzo del CART ---
    mask_cart_raw = cart_dadi(img_per_cart);
    %{
    figure; clf;
    imshow(mask_cart_raw); 
    title('Step 5: Output Grezzo CART (Classificazione)');
    %}
    % --- STEP 6: Sicurezza (Intersezione finale) ---
    mask_sicura = mask_cart_raw & mask_candidati;
    %{
    figure; clf;
    imshow(mask_sicura);
    title('Step 6: Maschera Sicura (CART & Candidati)');
    %}
    % --- STEP 7: Pulizia (Morfologia) ---
    % 7a. Fill
    mask_fill = imfill(mask_sicura, 'holes');
    
    % 7b. Open (Separazione dadi)
    % Nota: disk 8 è aggressivo, separerà molto bene i dadi
    mask_open = imopen(mask_fill, strel('disk', 8));
    
    % 7c. Area Filter (Rimozione rumore)
    mask_finale = bwareaopen(mask_open, 700);
    mask_finale = elimina_bordi(mask_finale);
    %{
    figure; clf;
    imshow(mask_finale);
    title('Step 7: Maschera Finale (Fill -> Open -> Area)');
    %}
    % --- VISUALIZZAZIONE FINALE RGB ---
    img_masked = frame_originale;
    img_masked(repmat(~mask_finale, [1 1 3])) = 0;
    save_frame(img_masked,numf,namev,"pixel_dadi");
    
    %{
    figure; clf;
    imshow(img_masked);
    title('Step 8: Risultato Finale RGB');
    %}
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