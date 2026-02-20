function lista_separata = dividi_dadi(mask_complessa,img)
    punti_vertici = trova_centri_dadi(mask_complessa);
    
    % Se per qualche motivo (es. rumore anomalo) non trova centri validi, 
    % restituisce la maschera così com'è per non bloccare il programma.
    if isempty(punti_vertici)
        lista_separata = {mask_complessa};
        return;
    end
    

    %lista_metodo_A = separa_per_distanza(mask_complessa, punti_vertici);

    lista_metodo_B = separa_geometrico(mask_complessa,punti_vertici);
    
    %stampa_overlay(img, mask_complessa, punti_vertici, lista_metodo_A, lista_metodo_B);

    lista_separata = lista_metodo_B;
end


function punti_vertici = trova_centri_dadi(mask)
    punti_vertici = [];
    mask_temp = mask;
    SOGLIA_ALTEZZA = 20; 
    % Mettila prima di calcolare i centri e prima di calcolare i vettori
    
    while true
        D = bwdist(~mask_temp);

        picco_max = max(max(D));

        if picco_max < SOGLIA_ALTEZZA
            break;
        end
        
        [riga, colonna] = find(D == picco_max, 1);
        
        punti_vertici = [punti_vertici; colonna, riga]; 
        

        mask_buco = true(size(mask_temp));
        
        mask_buco(riga, colonna) = false;
        
        SE = strel('disk', 15);
        mask_buco = imerode(mask_buco, SE);
        
        mask_temp = mask_temp & mask_buco;
    end
end

function lista_separata = separa_per_distanza(mask_complessa, punti_vertici)
    % Taglia la maschera assegnando ogni pixel al centro più vicino (Voronoi)
    % e reintroduce la soglia creando un "fiume" nero sul confine.
    
    lista_separata = {};
    num_centri = size(punti_vertici, 1);
    
    if num_centri < 2
        lista_separata{1} = mask_complessa;
        return;
    end
    
    % 1. Voronoi di base
    mask_centri = false(size(mask_complessa));
    for k = 1:num_centri
        mask_centri(punti_vertici(k, 2), punti_vertici(k, 1)) = true;
    end
    [~, L_voronoi] = bwdist(mask_centri);
    
    % --- 2. LA MAGIA DELLA SOGLIA RITROVATA ---
    SOGLIA_AMBIGUITA = 2; % Raggio dello spessore del taglio (modificalo a piacere)
    
    % Troviamo i confini esatti: se in un quadratino 3x3 il valore massimo (dilate) 
    % è diverso dal minimo (erode), significa che lì c'è un salto tra due dadi!
    confini_voronoi = imdilate(L_voronoi, ones(3)) ~= imerode(L_voronoi, ones(3));
    
    % "Ingrassiamo" questo confine per creare il nostro margine di separazione
    SE_taglio = strel('disk', SOGLIA_AMBIGUITA);
    linea_di_taglio = imdilate(confini_voronoi, SE_taglio);
    % -----------------------------------------
    
    % 3. Estrazione finale
    for k = 1:num_centri
        idx = sub2ind(size(mask_complessa), punti_vertici(k, 2), punti_vertici(k, 1));
        
        % La regola d'oro: prendi Voronoi, tienilo dentro la maschera originale,
        % e SOTTRAI (~) la spessa linea di taglio appena calcolata.
        mask_singolo = (L_voronoi == idx) & mask_complessa & ~linea_di_taglio;
        
        % Puliamo i detriti
        mask_singolo = bwareaopen(mask_singolo, 50); 
        
        if any(mask_singolo(:))
            lista_separata{end+1} = mask_singolo;
        end
    end
end
    
function lista_separata = separa_geometrico(mask_complessa, punti_vertici)


    % Usa il centro, la distanza l/2 e l'orientamento per ritagliare i dadi uniti.
    lista_separata = {};
    num_centri = size(punti_vertici, 1);
    [h, w] = size(mask_complessa);
    
    % bwdist con due output: 
    % D = la distanza (l/2)
    % IDX = l'indice del pixel nero più vicino!
    [D, IDX] = bwdist(~mask_complessa);
    
    for k = 1:num_centri
        c_centro = punti_vertici(k, 1); % X
        r_centro = punti_vertici(k, 2); % Y
        
        % 1. Troviamo l/2 (la distanza dal bordo)
        l_mezzi = D(r_centro, c_centro);
        
        % 2. Troviamo le coordinate del pixel nero più vicino
        indice_nero = IDX(r_centro, c_centro);
        [r_nero, c_nero] = ind2sub([h, w], indice_nero);
        
        % 3. Calcoliamo il vettore normale dal centro al bordo
        % Questo vettore contiene già l'inclinazione del dado!
        dx = c_nero - c_centro;
        dy = r_nero - r_centro;
        
        v_normale = [dx, dy]; % Vettore perpendicolare al lato
        v_parallelo = [-dy, dx]; % Vettore parallelo al lato (ruotato di 90 gradi)
        
        % 4. Troviamo i 4 vertici del quadrato ruotato
        % Partiamo dal centro e ci spostiamo lungo i due vettori
        V1 = [c_centro, r_centro] + v_normale + v_parallelo;
        V2 = [c_centro, r_centro] + v_normale - v_parallelo;
        V3 = [c_centro, r_centro] - v_normale - v_parallelo;
        V4 = [c_centro, r_centro] - v_normale + v_parallelo;
        
        % 5. Disegniamo una maschera a forma di quadrato ruotato (poligono)
        % poly2mask è una funzione base di MATLAB per riempire un poligono
        mask_quadrato = poly2mask([V1(1) V2(1) V3(1) V4(1)], ...
                                  [V1(2) V2(2) V3(2) V4(2)], h, w);
        
        % 6. Intersezione: prendiamo solo i pixel della maschera originale 
        % che cadono dentro il nostro quadrato perfetto
        mask_singolo = mask_complessa & mask_quadrato;
        
        % Pulizia finale per sicurezza
        mask_singolo = imfill(mask_singolo, 'holes');
        
        lista_separata{end+1} = mask_singolo;
    end
end

function stampa(mask_complessa, punti_vertici, lista_A, lista_B)
    % Crea una figura per il confronto visivo
    figure('Name', 'Confronto Metodi Taglio', 'NumberTitle', 'off', 'Position', [100, 200, 1200, 400]);
    
    % --- 1. Maschera Originale + Centri ---
    subplot(1, 3, 1);
    imshow(mask_complessa);
    title('Originale e Centri');
    hold on;
    % Disegna i centri (X, Y) come stelle rosse
    if ~isempty(punti_vertici)
        plot(punti_vertici(:, 1), punti_vertici(:, 2), 'r*', 'MarkerSize', 8, 'LineWidth', 1.5);
    end
    hold off;
    
    % --- 2. Metodo A (Colori diversi per ogni pezzo) ---
    subplot(1, 3, 2);
    % Crea una tela nera
    mappa_A = zeros(size(mask_complessa)); 
    for i = 1:length(lista_A)
        % "Incolla" ogni maschera assegnandole un numero identificativo (1, 2, 3...)
        mappa_A(lista_A{i}) = i; 
    end
    % label2rgb colora ogni numero in modo diverso ('k' imposta lo sfondo nero)
    imshow(label2rgb(mappa_A, 'jet', 'k', 'shuffle'));
    title('Metodo A (Voronoi)');
    
    % --- 3. Metodo B (Colori diversi per ogni pezzo) ---
    subplot(1, 3, 3);
    mappa_B = zeros(size(mask_complessa));
    for i = 1:length(lista_B)
        mappa_B(lista_B{i}) = i;
    end
    imshow(label2rgb(mappa_B, 'jet', 'k', 'shuffle'));
    title('Metodo B (Geometrico)');
end




function stampa_overlay(img_orig, mask_complessa, punti_vertici, lista_A, lista_B)
    % Crea una figura mostrando i risultati in trasparenza sull'immagine reale.
    
    figure('Name', 'Confronto Tagli Overlay', 'NumberTitle', 'off', 'Position', [100, 200, 1200, 400]);
    
    % --- 1. Immagine Originale + Centri + Maschera Totale ---
    subplot(1, 3, 1);
    % Mostriamo l'immagine originale con la maschera complessa in giallo trasparente
    overlay_orig = labeloverlay(img_orig, mask_complessa, 'Colormap', [1 1 0], 'Transparency', 0.7);
    imshow(overlay_orig);
    title('Originale, Maschera e Centri');
    hold on;
    if ~isempty(punti_vertici)
        plot(punti_vertici(:, 1), punti_vertici(:, 2), 'r*', 'MarkerSize', 10, 'LineWidth', 2);
    end
    hold off;
    
    % --- 2. Metodo A (Voronoi) in Overlay ---
    subplot(1, 3, 2);
    mappa_A = zeros(size(mask_complessa)); 
    for i = 1:length(lista_A)
        mappa_A(lista_A{i}) = i; % Assegna un colore diverso a ogni dado
    end
    % labeloverlay sovrappone i colori all'immagine originale con trasparenza
    overlay_A = labeloverlay(img_orig, mappa_A, 'Colormap', 'jet', 'Transparency', 0.4);
    imshow(overlay_A);
    title('Metodo A (Voronoi - Taglio Netto)');
    
    % --- 3. Metodo B (Geometrico) in Overlay ---
    subplot(1, 3, 3);
    mappa_B = zeros(size(mask_complessa));
    for i = 1:length(lista_B)
        mappa_B(lista_B{i}) = i;
    end
    overlay_B = labeloverlay(img_orig, mappa_B, 'Colormap', 'jet', 'Transparency', 0.4);
    imshow(overlay_B);
    title('Metodo B (Quadrati Geometrici)');
end


