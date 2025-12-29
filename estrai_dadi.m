function somma_dadi = estrai_dadi(frame_originale,namev,numf)

    mask = cart_dadi(frame_originale);

    mask_no_border = imclearborder(mask);


    mask_centri = imopen(mask_no_border, strel('disk', 17));
    mask_centri = imerode(mask_centri, strel('disk', 8));

    dadi_isolati = frame_originale;
    mask_3d = repmat(mask_centri, [1, 1, 3]);
    dadi_isolati(~mask_3d) = 0;

    % --- 4. VISUALIZZAZIONE ---
    figure('Name', 'Estrazione Centri Dadi');
    
    % Subplot 1: Immagine Originale + Contorni Centri
    subplot(1, 2, 1);
    imshow(frame_originale); 
    hold on;
    % Visboundaries disegna i contorni della maschera sull'immagine RGB
    visboundaries(mask_centri, 'Color', 'g', 'LineWidth', 2);
    title('Dadi Rilevati (Verde = Centro)');
    
    % Subplot 2: Maschera Finale (Bianco e Nero)
    subplot(1, 2, 2);
    imshow(dadi_isolati);
    title('Maschera Centri (Erosa & No Bordi)');
    
    % Feedback in console
    num_dadi = bwconncomp(mask_centri).NumObjects;
    fprintf('Dadi validi trovati (centri): %d\n', num_dadi);
    somma_dadi = 10;
end
