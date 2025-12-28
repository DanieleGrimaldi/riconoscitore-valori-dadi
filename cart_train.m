clc;
fprintf('=== INIZIO CREAZIONE DATASET PULITO ===\n');

% 1. Processa i Dadi
processa_dadi();

fprintf('\n---------------------------------------\n');

% 2. Processa gli Sfondi
processa_sfondi();
fprintf('\n---------------------------------------\n');


% FASE 3: Training del Modello
% (Legge i file precedenti, crea l albero e salva ModelloAlbero.mat)
fprintf('\n[3/3] Training Modello...\n');
train_cart_model();

fprintf('\n=== TUTTO COMPLETATO CON SUCCESSO ===\n');


%%addestro il modello
function train_cart_model()
    % TRAIN_CART_MODEL Carica le features, addestra l'albero e salva il modello.
    
    fprintf('--- Inizio fase di Training ---\n');

    % 1. Caricamento Dati
    % Usiamo struct per essere sicuri di prendere la variabile qualunque sia il suo nome
    try
        data_dadi = load('dati_dadi_clean.mat');
        data_sfondo = load('dati_sfondo_clean.mat');
    catch
        error('Errore: Non trovo i file .mat. Hai eseguito processa_dadi e processa_sfondi?');
    end

    % Estrae le matrici (prende il primo campo trovato nella struct)
    nomi_dadi = fieldnames(data_dadi);
    nomi_sfondo = fieldnames(data_sfondo);
    
    X_dadi = data_dadi.(nomi_dadi{1});
    X_sfondo = data_sfondo.(nomi_sfondo{1});

    fprintf('Caricati %d campioni Dadi e %d campioni Sfondo.\n', size(X_dadi,1), size(X_sfondo,1));

    % 2. Creazione Etichette (Labels)
    % 1 = Dado, 0 = Sfondo
    Y_dadi = ones(size(X_dadi, 1), 1);
    Y_sfondo = zeros(size(X_sfondo, 1), 1);

    % 3. Unione Dataset
    X = [X_dadi; X_sfondo]; % Features
    Y = [Y_dadi; Y_sfondo]; % Classi

    % 4. Addestramento Albero
    % MinLeafSize = 50 evita che l'albero diventi troppo complesso e lento
    fprintf('Addestramento in corso (fitctree)...\n');
    tree = fitctree(X, Y, 'MinLeafSize', 50);

    % 5. Salvataggio
    nome_file_modello = 'ModelloAlbero.mat';
    save(nome_file_modello, 'tree');
    
    fprintf('Training completato. Modello salvato in: %s\n', nome_file_modello);
end

%% --- FUNZIONE 1: DADI ---
function processa_dadi()
    cartella_in = 'frame-tagliati';
    file_out    = 'dati_dadi_clean.mat';
    
    fprintf('1. Elaborazione DADI (Cartella: %s)...\n', cartella_in);
    
    if ~exist(cartella_in, 'dir')
        error('Cartella %s non trovata!', cartella_in);
    end
    
    files = dir(fullfile(cartella_in, '*.png')); % Di solito i tagliati sono PNG
    if isempty(files), files = dir(fullfile(cartella_in, '*.jpg')); end
    
    if isempty(files)
        fprintf('   [ATTENZIONE] Nessuna immagine trovata in %s\n', cartella_in);
        return;
    end
    
    dati_temp = cell(length(files), 1);
    conta = 0;
    
    for k = 1:length(files)
        img = imread(fullfile(files(k).folder, files(k).name));
        
        % Logica Pulizia: Rimuoviamo lo sfondo nero (o trasparente)
        % Se somma RGB < 15 è nero sporco -> scartare
        mask = sum(img, 3) > 15; 
        
        if any(mask(:))
            lab = rgb2lab(img);
            
            % Estraiamo i canali vettorizzati
            L = lab(:,:,1); A = lab(:,:,2); B = lab(:,:,3);
            
            % Salviamo solo i pixel validi
            dati_temp{k} = [L(mask), A(mask), B(mask)];
            conta = conta + sum(mask(:));
        end
        if mod(k, 50) == 0, fprintf('.'); end
    end
    
    % Unione
    pixel_dadi = vertcat(dati_temp{:});
    
    % Salvataggio
    fprintf('\n   Salvataggio di %d pixel puliti in %s...', conta, file_out);
    save(file_out, 'pixel_dadi');
    fprintf(' Fatto.\n');
end

%% --- FUNZIONE 2: SFONDI ---
function processa_sfondi()
    cartella_in = 'sfondo';
    file_out    = 'dati_sfondo_clean.mat';
    
    fprintf('2. Elaborazione SFONDI (Cartella: %s)...\n', cartella_in);
    
    if ~exist(cartella_in, 'dir')
        error('Cartella %s non trovata!', cartella_in);
    end
    
    % Cerca sia jpg che png
    files = [dir(fullfile(cartella_in, '*.jpg')); dir(fullfile(cartella_in, '*.png'))];
    
    if isempty(files)
        fprintf('   [ATTENZIONE] Nessuna immagine trovata in %s\n', cartella_in);
        return;
    end
    
    dati_temp = cell(length(files), 1);
    conta = 0;
    
    for k = 1:length(files)
        img = imread(fullfile(files(k).folder, files(k).name));
        
        % Logica Pulizia:
        % Elimina il nero (bordi mascherati) e il rumore scuro
        mask = sum(img, 3) > 15;
        
        % Pulizia extra morfologica per rimuovere puntini isolati (rumore)
        mask = bwareaopen(mask, 10);
        
        if any(mask(:))
            lab = rgb2lab(img);
            
            L = lab(:,:,1); A = lab(:,:,2); B = lab(:,:,3);
            
            dati_temp{k} = [L(mask), A(mask), B(mask)];
            conta = conta + sum(mask(:));
        end
        if mod(k, 20) == 0, fprintf('.'); end
    end
    
    % Unione
    pixel_sfondo = vertcat(dati_temp{:});
    
    % Salvataggio (v7.3 per file grandi)
    fprintf('\n   Salvataggio di %d pixel puliti in %s...', conta, file_out);
    save(file_out, 'pixel_sfondo', '-v7.3');
    fprintf(' Fatto.\n');
end