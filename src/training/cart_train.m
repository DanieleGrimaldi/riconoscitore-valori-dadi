clc;
clear;
close all;

fprintf('=== PIPELINE DI ADDESTRAMENTO COMPLETA (Con Texture) ===\n');

%% 1. Processa i Dadi
% Prende i ritagli, calcola L,A,B + Texture e salva in dati_dadi_clean.mat
processa_dadi();
fprintf('\n---------------------------------------\n');

%% 2. Processa gli Sfondi
% Prende gli sfondi puliti (da sfondo2), calcola le features e salva in dati_sfondo_clean.mat
processa_sfondi();
fprintf('\n---------------------------------------\n');

%% 3. Training del Modello
% Carica i due file .mat, bilancia e addestra l'albero
fprintf('\n[3/3] Training Modello...\n');
train_cart_model();

fprintf('\n=== TUTTO COMPLETATO CON SUCCESSO ===\n');


%% ---------------------------------------------------------
%  FUNZIONI DELLA PIPELINE
%  ---------------------------------------------------------

function processa_dadi()
    cartella_in = 'frame-tagliati'; 
    file_out    = 'dati_dadi_clean.mat'; % NOME ORIGINALE
    
    fprintf('1. Elaborazione DADI (Cartella: %s)...', cartella_in);
    
    if ~exist(cartella_in, 'dir'), error('Cartella %s non trovata!', cartella_in); end
    files = dir(fullfile(cartella_in, '*.png'));
    
    dati_accumulo = {};
    
    for k = 1:length(files)
        img = imread(fullfile(files(k).folder, files(k).name));
        
        % Estrazione Features (L, A, B, Texture)
        [feats_all, mask] = estrai_features_texture(img);
        
        if ~isempty(feats_all)
            mask_vec = mask(:);
            % Salviamo solo i pixel validi (il dado)
            dati_accumulo{end+1} = feats_all(mask_vec, :); 
        end
        if mod(k, 50) == 0, fprintf('.'); end
    end
    
    % Unione
    if isempty(dati_accumulo)
        error('Nessun dato estratto dai dadi. Controlla le immagini.');
    end
    pixel_dadi = vertcat(dati_accumulo{:});
    
    % Salvataggio con il nome variabile che usavi tu
    save(file_out, 'pixel_dadi');
    fprintf(' Fatto. Salvati %d pixel in %s\n', size(pixel_dadi,1), file_out);
end


function processa_sfondi()
    cartella_in = 'sfondo'; 
    file_out    = 'dati_sfondo_clean.mat'; % NOME ORIGINALE
    
    fprintf('2. Elaborazione SFONDI (Cartella: %s)...', cartella_in);
    
    if ~exist(cartella_in, 'dir'), error('Cartella %s non trovata!', cartella_in); end
    files = dir(fullfile(cartella_in, '*.jpg'));
    if isempty(files), files = dir(fullfile(cartella_in, '*.png')); end
    
    dati_accumulo = {};
    MAX_PIXEL_PER_IMG = 100000; % Limite per RAM
    
    for k = 1:length(files)
        img = imread(fullfile(files(k).folder, files(k).name));
        
        % Estrazione Features
        [feats_all, mask] = estrai_features_texture(img);
        
        if ~isempty(feats_all)
            mask_vec = mask(:);
            feats_validi = feats_all(mask_vec, :);
            
            % Campionamento casuale
            if size(feats_validi, 1) > MAX_PIXEL_PER_IMG
                idx = randperm(size(feats_validi, 1), MAX_PIXEL_PER_IMG);
                dati_accumulo{end+1} = feats_validi(idx, :);
            else
                dati_accumulo{end+1} = feats_validi;
            end
        end
        if mod(k, 10) == 0, fprintf('.'); end
    end
    
    if isempty(dati_accumulo)
        error('Nessun dato estratto dagli sfondi. Controlla la cartella sfondo2.');
    end
    pixel_sfondo = vertcat(dati_accumulo{:});
    
    save(file_out, 'pixel_sfondo'); % Rimosso -v7.3 per velocità
    fprintf(' Fatto. Salvati %d pixel in %s\n', size(pixel_sfondo,1), file_out);
end


function train_cart_model()
    fprintf('--- Inizio fase di Training ---\n');
    
    % 1. Caricamento Dati
    try
        data_dadi = load('dati_dadi_clean.mat');
        data_sfondo = load('dati_sfondo_clean.mat');
    catch
        error('Errore: File .mat mancanti.');
    end
    
    % Estrazione variabili dalle struct
    % (Uso fieldnames così funziona qualunque sia il nome della variabile interna)
    nomi_dadi = fieldnames(data_dadi);
    nomi_sfondo = fieldnames(data_sfondo);
    
    X_dadi = data_dadi.(nomi_dadi{1});
    X_sfondo = data_sfondo.(nomi_sfondo{1});
    
    fprintf('Campioni caricati: Dadi %d, Sfondo %d\n', size(X_dadi,1), size(X_sfondo,1));
    
    % 2. Bilanciamento Classi
    % Tagliamo lo sfondo se supera il doppio dei dadi
    max_sfondo = size(X_dadi, 1) * 2; 
    if size(X_sfondo, 1) > max_sfondo
        fprintf('Bilanciamento: riduco sfondo a %d campioni...\n', max_sfondo);
        indici = randperm(size(X_sfondo, 1), max_sfondo);
        X_sfondo = X_sfondo(indici, :);
    end
    
    % 3. Creazione Etichette (1=Dado, 0=Sfondo)
    Y_dadi = ones(size(X_dadi, 1), 1);
    Y_sfondo = zeros(size(X_sfondo, 1), 1);
    
    X = [X_dadi; X_sfondo]; 
    Y = [Y_dadi; Y_sfondo];
    
    % 4. Addestramento Albero
    fprintf('Addestramento fitctree in corso (con Texture)...\n');
    
    % IMPORTANTE: Specifichiamo i 4 nomi per chiarezza futura
    tree = fitctree(X, Y, ...
        'MinLeafSize', 100, ...
        'PredictorNames', {'L', 'A', 'B', 'Texture'});
    
    % 5. Salvataggio
    nome_file_modello = 'ModelloAlbero.mat';
    save(nome_file_modello, 'tree');
    
    fprintf('Training completato. Modello salvato in: %s\n', nome_file_modello);
end


%% --- FUNZIONE MOTORE (HELPER) ---
function [features, mask_valid] = estrai_features_texture(img)
    % Calcola L, A, B e Texture (stdfilt)
    
    % Maschera validità: ignora pixel neri (0,0,0)
    mask_valid = sum(img, 3) > 0;
    
    if ~any(mask_valid(:))
        features = [];
        return;
    end

    % LAB
    lab = rgb2lab(img);
    L = lab(:,:,1); 
    A = lab(:,:,2); 
    B = lab(:,:,3);

    % Texture (Ruvidità sul canale L)
    L_norm = rescale(L); 
    Texture = stdfilt(L_norm, true(3));

    % Output 4 colonne
    features = [L(:), A(:), B(:), Texture(:)];
end