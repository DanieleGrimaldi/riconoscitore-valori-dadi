function mask_final = cart_dadi(img_input)
    % CART_DADI Funzione principale.
    % Gestisce il flusso: Caricamento Modello -> Pre-Processing -> Predizione -> Post-Processing
    
    % --- 1. GESTIONE MEMORIA MODELLO (Persistent) ---
    persistent treeModel;
    
    if isempty(treeModel)
        nome_file = 'ModelloAlbero.mat';
        if ~isfile(nome_file)
            error('Modello "%s" non trovato!', nome_file);
        end
        
        % fprintf('--- Caricamento Modello in memoria... ---\n');
        dati = load(nome_file);
        if isfield(dati, 'tree'), treeModel = dati.tree;
        else, nomi = fieldnames(dati); treeModel = dati.(nomi{1});
        end
    end

    % --- 2. PRE-PROCESSING ---
    % Estrae le features (LAB) e identifica i pixel validi (non neri)
    [X_features, mask_validi] = pre_processing(img_input);
    
    % Inizializza maschera vuota
    [h, w, ~] = size(img_input);
    mask_raw = false(h, w);

    % Se non ci sono pixel validi, ritorna subito tutto nero
    if isempty(X_features)
        mask_final = mask_raw;
        return;
    end

    % --- 3. PREDIZIONE (CORE) ---
    % Predice solo sui pixel validi per velocità
    labels = predict(treeModel, X_features);
    
    % Ricostruisce l'immagine binaria grezza
    mask_raw(mask_validi) = labels;

    % --- 4. POST-PROCESSING ---
    % Pulisce la maschera grezza per alzare Precision e IoU
    mask_final = post_processing(mask_raw);
    
end


%%

function [X, mask_validi] = pre_processing(img)
    % PRE_PROCESSING: Prepara i dati per l'albero decisionale.
    % Deve essere IDENTICO alla logica usata nel training (LAB + filtro nero).
    
    % 1. Filtro Pixel Validi
    % Scarta lo sfondo nero puro (o quasi nero) per non confondere l'albero
    mask_vassoio = trova_maschera_vassoio(img);
    
    mask_validi = mask_vassoio & sum(img, 3) > 0;
    
    % Se non c'è nulla di valido, ritorna vuoto
    if ~any(mask_validi(:))
        X = [];
        return;
    end
    
    % 2. Conversione Spazio Colore (LAB)
    lab_img = rgb2lab(img);
    
    L = lab_img(:,:,1);
    A = lab_img(:,:,2);
    B = lab_img(:,:,3);
    
    % 3. Creazione Matrice Features (N x 3)
    % Estrae solo i valori dove mask_validi è true
    X = [L(mask_validi), A(mask_validi), B(mask_validi)];
end

%%
function mask_out = post_processing(mask_in)
    % POST_PROCESSING: Raffina la maschera binaria.
    % Obiettivo: Chiudere buchi (Recall) e rimuovere rumore (Precision).
    
    % 1. Riempimento Buchi (imfill)
    % Rende solidi i dadi che hanno puntini neri all'interno
    mask_out = imfill(mask_in, 'holes');
    
    % 2. Pulizia Rumore Fine (imopen)
    % Rimuove puntini isolati ("nebbia") e smussa i bordi frastagliati.
    % Un raggio (radius) di 2 è un buon compromesso.
    se = strel('disk', 8); 
    mask_out = imopen(mask_out, se);
    
    % 3. Filtro Area Minima (bwareaopen)
    % Rimuove grosse macchie che non sono dadi (es. riflessi sul bordo vassoio).
    % Elimina tutto ciò che è più piccolo di 200 pixel.
    mask_out = bwareaopen(mask_out, 800);
end