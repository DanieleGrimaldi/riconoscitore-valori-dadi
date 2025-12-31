function [maschera_separata] = trova_picchi_watershed(immagine_originale, maschera_binaria)
    % TROVA_PICCHI_WATERSHED
    % Input: 
    %   - immagine_originale: l'immagine a colori (RGB) o scala di grigi
    %   - maschera_binaria: la maschera in bianco e nero (es. uscita dal CART)
    % Output:
    %   - maschera_separata: la maschera con i tagli applicati (binaria)
    %
    % Effetto: Apre una figura che mostra il risultato della separazione.

    %% 1. Preparazione Dati
    % Assicuriamoci che la maschera sia logica (0 e 1)
    bw = logical(maschera_binaria);
    
    % Pulizia preliminare opzionale (rimuove rumore piccolissimo)
    bw = bwareaopen(bw, 10); 

    %% 2. Algoritmo Watershed (H-Minima Transform)
    % Calcola la mappa di distanza invertita (topografia)
    D = -bwdist(~bw);

    % PARAMETRO CRITICO 'h':
    % Rappresenta la profondità della "valle" necessaria per separare due picchi.
    % h = 1 o 2: Separa bene dadi molto vicini (consigliato per il tuo caso).
    % h > 3: Separa meno (solo se la valle è profonda).
    h = 1; 
    
    % Trova i minimi estesi (i centri dei dadi)
    mask_markers = imextendedmin(D, h);

    % Modifica la distanza per forzare i minimi solo sui marker trovati
    D_modificata = imimposemin(D, mask_markers);

    % Calcola il Watershed
    L = watershed(D_modificata);

    % Applica i tagli alla maschera originale
    % Dove L == 0 ci sono le "dighe" (i confini tra i dadi)
    maschera_separata = bw;
    maschera_separata(L == 0) = 0;
    %visualizza_dadi(immagine_originale, bw, maschera_separata)
    
end

function visualizza_dadi(immagine_originale, maschera_iniziale, maschera_separata)
    % VISUALIZZA_DADI - Versione "ANTI-OMBRA" (Weighted Centroid)
    
    % 1. Prepara l'immagine in scala di grigi per l'analisi della luce
    if size(immagine_originale, 3) == 3
        img_gray = rgb2gray(immagine_originale);
    else
        img_gray = immagine_originale;
    end
    
    % Etichettiamo i dadi separati
    [L, num_oggetti] = bwlabel(maschera_separata);
    
    % Maschera vuota per i punti
    maschera_punti = false(size(maschera_separata));
    
    % 2. CICLO SU OGNI DADO
    for i = 1:num_oggetti
        % Isola il singolo dado
        dado_mask = (L == i);
        
        % --- STEP A: SBUCCIATURA (Peeling) ---
        % Erodiamo il singolo dado per togliere lo strato esterno (dove vive l'ombra).
        % Raggio 5 è abbastanza per togliere l'ombra ma lasciare il dado.
        dado_core = imerode(dado_mask, strel('disk', 5));
        
        % Sicurezza: Se il dado era piccolissimo e l'abbiamo cancellato, torniamo indietro
        if sum(dado_core(:)) == 0
            dado_core = dado_mask;
        end
        
        % --- STEP B: BARICENTRO PESATO (Weighted Centroid) ---
        % Chiediamo a regionprops di calcolare il centro basandosi sull'intensità
        % dei pixel dell'immagine originale (img_gray).
        % I pixel scuri (ombra) varranno poco, i chiari (dado/numero) attrarranno il centro.
        props = regionprops(dado_core, img_gray, 'WeightedCentroid');
        
        if ~isempty(props)
            centro = props.WeightedCentroid; % Restituisce [x, y]
            c_x = round(centro(1));
            c_y = round(centro(2));
            
            % Controlli di sicurezza bordi
            c_x = max(1, min(c_x, size(maschera_separata, 2)));
            c_y = max(1, min(c_y, size(maschera_separata, 1)));
            
            maschera_punti(c_y, c_x) = true;
        end
    end
    
    % 3. DILATAZIONE (Creazione del Bollino)
    raggio = 20; 
    se = strel('disk', raggio);
    maschera_cerchi = imdilate(maschera_punti, se);
    
    % 4. Visualizzazione
    [L_rgb, ~] = bwlabel(maschera_cerchi);
    
    if size(immagine_originale, 3) == 1
        img_vis = cat(3, immagine_originale, immagine_originale, immagine_originale);
    else
        img_vis = immagine_originale;
    end
    
    overlay_img = labeloverlay(img_vis, L_rgb, 'Colormap', 'spring', 'Transparency', 0.4);
    
    figure('Name', 'Analisi Anti-Ombra', 'NumberTitle', 'off');
    
    subplot(1, 2, 1);
    imshow(maschera_iniziale);
    title('Input (Uniti)');
    
    subplot(1, 2, 2);
    imshow(overlay_img);
    title(['Risultato: ' num2str(num_oggetti) ' Centri Pesati sulla Luce']);
    
    drawnow;
end

