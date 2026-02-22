function crea_modello_knn()

    X_train = []; % Conterrà le features (108 righe x 6 colonne)
    Y_train = []; % Conterrà le etichette (108 righe x 1 colonna)
    
    cartella_base = 'dataset';
    
    fprintf('Inizio estrazione features dal dataset...\n');
    
    % Cicliamo sulle 6 cartelle (le facce del dado da 1 a 6)
    for cifra = 1:6
        % Costruiamo il percorso (es. 'dataset\1', 'dataset\2')
        cartella_cifra = fullfile(cartella_base, num2str(cifra));
        
        if ~exist(cartella_cifra, 'dir')
            warning('Cartella non trovata: %s. Salto...', cartella_cifra);
            continue;
        end
        
        % Troviamo tutte le immagini (png, jpg, o bmp) nella cartella
        file_immagini = dir(fullfile(cartella_cifra, '*.png')); 
        
        for f = 1:length(file_immagini)
            percorso_img = fullfile(cartella_cifra, file_immagini(f).name);
            
            % 1. Lettura Immagine
            img = imread(percorso_img);
            

            mask_binaria = img > 0;
            
            % 3. Estrazione delle 6 features con la tua funzione
            features = calcola_features(mask_binaria);
            
            % 4. Accodiamo i risultati nella matrice grande
            X_train = [X_train; features];
            
            % Accodiamo l'etichetta (il numero della cartella corrente)
            Y_train = [Y_train; cifra]; 
        end
        fprintf('Elaborata cartella %d: caricati %d esempi.\n', cifra, length(file_immagini));
    end
    
    % --- ADDESTRAMENTO DEL MODELLO ---
    fprintf('\nAddestramento del classificatore KNN in corso...\n');
    
    % Il parametro 'Standardize' fa la magia: normalizza (Z-Score) i dati 
    % e memorizza i parametri di normalizzazione dentro l'oggetto modello.
    % Usiamo K=3, che di solito è il numero perfetto per dataset piccoli ed evita pareggi.
    modello_knn = fitcknn(X_train, Y_train, 'NumNeighbors', 3, 'Standardize', true);
    
    % --- SALVATAGGIO ---
    nome_salvataggio = 'modello_dado.mat';
    save(nome_salvataggio, 'modello_knn');
    
    fprintf('Addestramento completato con successo!\nModello pronto e salvato in "%s".\n', nome_salvataggio);
end

function features = calcola_features(mask_binaria)
    % Restituisce [Circularity, EulerNumber, Eccentricity, Solidity, Hu1_Log, Hu2_Log]
    
    if sum(mask_binaria(:)) == 0
        features = zeros(1, 6); 
        return;
    end
    
    % 1. Estrazione Geometria Base (1 sola forma garantita)
    stats = regionprops(mask_binaria, 'Area', 'EulerNumber', 'Eccentricity', 'Solidity', 'Perimeter');
    
    % 2. Calcolo NATIVO e matematico dei Momenti di Hu (Hu1 e Hu2)
    [y, x] = find(mask_binaria);
    
    % Baricentro e Area (m00)
    x_bar = mean(x);
    y_bar = mean(y);
    m00 = length(x);
    
    % Momenti centrali
    mu20 = sum((x - x_bar).^2);
    mu02 = sum((y - y_bar).^2);
    mu11 = sum((x - x_bar) .* (y - y_bar));
    
    % Momenti normalizzati al quadrato
    eta20 = mu20 / (m00^2);
    eta02 = mu02 / (m00^2);
    eta11 = mu11 / (m00^2);
    
    % Formule dei primi due invarianti di Hu
    hu1 = eta20 + eta02;
    hu2 = (eta20 - eta02)^2 + 4 * (eta11^2);
    
    % --- TRASFORMAZIONI MATEMATICHE ---
    
    % Circolarità
    if stats.Perimeter > 0
        circularity = (4 * pi * stats.Area) / (stats.Perimeter ^ 2);
    else
        circularity = 0;
    end
    
    % Logaritmo sui Momenti di Hu 1 e 2
    hu_log1 = -sign(hu1) * log10(abs(hu1) + 1e-10);
    hu_log2 = -sign(hu2) * log10(abs(hu2) + 1e-10);
    
    % --- ASSEMBLAGGIO FINALE ---
    features = [circularity, double(stats.EulerNumber), stats.Eccentricity, stats.Solidity, hu_log1, hu_log2];
    
    % Protezione finale da valori non validi (NaN/Inf)
    features(isnan(features)) = 0;
    features(isinf(features)) = 0;
end