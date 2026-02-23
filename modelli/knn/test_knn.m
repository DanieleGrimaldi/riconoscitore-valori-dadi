function test_knn()
    % VALUTA_PERFORMANCE_KNN: Testa il modello salvato sulle immagini classificate.
    
    % --- 1. CARICAMENTO DEL MODELLO ---
    fprintf('Caricamento del modello in corso...\n');
    try
        % Carica il file .mat. Se lo hai chiamato "modello_knn.mat", questo è corretto.
        dati_caricati = load('modello_knn.mat'); 
        
        % Estraiamo dinamicamente il modello indipendentemente da come 
        % si chiamava la variabile salvata all'interno del file.
        campi = fieldnames(dati_caricati);
        modello_knn = dati_caricati.(campi{1}); 
    catch
        error('Errore: impossibile caricare il file "modello_knn.mat". Assicurati che sia nella cartella corrente.');
    end
    
    % Cartella principale che contiene le sottocartelle 1, 2, 3...
    cartella_base = 'Maschere_Cifre';
    
    % Variabili per le statistiche globali
    totale_immagini = 0;
    previsioni_corrette = 0;
    
    % Questi vettori ci serviranno per disegnare la matrice di confusione finale
    etichette_vere = [];
    etichette_predette = [];
    
    fprintf('Inizio valutazione sulle immagini in "%s"...\n\n', cartella_base);
    
    % --- 2. CICLO DI TEST SULLE CARTELLE ---
    for cifra_reale = 1:6
        cartella_cifra = fullfile(cartella_base, num2str(cifra_reale));
        
        % Se la cartella per questa cifra non esiste, passiamo alla successiva
        if ~exist(cartella_cifra, 'dir')
            continue;
        end
        
        % Leggiamo tutti i file PNG presenti nella sottocartella
        file_immagini = dir(fullfile(cartella_cifra, '*.png'));
        corrette_per_cifra = 0;
        
        for f = 1:length(file_immagini)
            percorso_img = fullfile(cartella_cifra, file_immagini(f).name);
            
            % Lettura e forzatura dell'immagine a Maschera Binaria Pura
            img = imread(percorso_img);
            if size(img, 3) == 3
                img = rgb2gray(img);
            end
            mask_binaria = img > 0;
            
            % --- ESTRAZIONE FEATURES E PREDIZIONE ---
            % Usiamo la tua funzione snella e priva di bug
            features = calcola_features(mask_binaria);
            
            % Protezione: se l'immagine è completamente nera, saltiamola
            if sum(features) == 0
                continue;
            end
            
            % La magia avviene qui: passiamo i dati grezzi e lui predice!
            % (La normalizzazione avviene di nascosto grazie al modello nativo)
            cifra_predetta = predict(modello_knn, features);
            
            % Registriamo i risultati per i calcoli
            etichette_vere = [etichette_vere; cifra_reale];
            etichette_predette = [etichette_predette; cifra_predetta];
            totale_immagini = totale_immagini + 1;
            
            if cifra_predetta == cifra_reale
                previsioni_corrette = previsioni_corrette + 1;
                corrette_per_cifra = corrette_per_cifra + 1;
            else
                % Se vuoi vedere esattamente QUALI immagini sbaglia, decommenta la riga sotto:
                % fprintf('  [!] ERRORE su %s: previsto %d, ma era %d\n', file_immagini(f).name, cifra_predetta, cifra_reale);
            end
        end
        
        % Stampa il report parziale per questa singola cifra
        if ~isempty(file_immagini)
            accuratezza_cifra = (corrette_per_cifra / length(file_immagini)) * 100;
            fprintf('Cifra %d: %d/%d corrette (%.1f%%)\n', cifra_reale, corrette_per_cifra, length(file_immagini), accuratezza_cifra);
        end
    end
    
    % --- 3. REPORT FINALE ---
    if totale_immagini > 0
        accuratezza_totale = (previsioni_corrette / totale_immagini) * 100;
        fprintf('\n--- RISULTATO FINALE ---\n');
        fprintf('Immagini totali analizzate: %d\n', totale_immagini);
        fprintf('Previsioni azzeccate: %d\n', previsioni_corrette);
        fprintf('ACCURATEZZA GLOBALE: %.2f%%\n', accuratezza_totale);
        
        % Disegna la Matrice di Confusione
        try
            figure('Name', 'Matrice di Confusione', 'NumberTitle', 'off');
            confusionchart(etichette_vere, etichette_predette, ...
                'Title', sprintf('Performance Modello KNN (Accuratezza: %.1f%%)', accuratezza_totale), ...
                'RowSummary', 'row-normalized', ...
                'ColumnSummary', 'column-normalized');
        catch
            % Se la versione di MATLAB non ha la funzione confusionchart, andiamo oltre silenziosamente
        end
    else
        fprintf('Nessuna immagine testabile trovata nella cartella.\n');
    end
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