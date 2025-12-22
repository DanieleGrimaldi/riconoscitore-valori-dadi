function maschera_roi = trova_maschera_vassoio(img_sfondo)
    % --- CONFIGURAZIONE ---
    SOGLIA_SATURAZIONE = 0.18; % Sotto = Grigio, Sopra = Legno
    MARGINE_EROSIONE   = 40;   % Pixel da togliere ai bordi
    
    % 1. Converti in HSV (Solo Saturazione)
    hsv = rgb2hsv(img_sfondo);
    sat = hsv(:,:,2);
    
    % 2. Filtro Colore Diretto
    % Crea la maschera binaria: 1 = Vassoio, 0 = Legno
    mask = sat < SOGLIA_SATURAZIONE;
    
    % 3. Pulizia Rumore 
    mask = imopen(mask, strel('disk', 5));
    
    % 4. Riempimento Solido
    % Usiamo 'imfill' invece di 'imclose'. 
    % Perché? Se c'è un dado nello sfondo, lascia un buco grande. 
    % 'imclose' richiederebbe un disco enorme (lento). 'imfill' è istantaneo.
    mask_solid = imfill(mask, 'holes');
    
    % 5. Erosione Finale (Safe Zone)
    maschera_roi = imerode(mask_solid, strel('disk', MARGINE_EROSIONE));
    
end