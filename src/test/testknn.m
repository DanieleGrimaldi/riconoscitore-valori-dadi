%% TEST REALE PERFORMANCE
% Questo script testa l'intera pipeline usando le tue funzioni:
% 1. estrai_cifra (Segmentazione)
% 2. decodifica_cifra (Classificazione con modello persistente)

clc; clear; close all;

basePath = 'test/numeri'; % Cartella contenente 1, 2, 3, 4, 5, 6
numClasses = 6;

% Contatori per le statistiche
confMat = zeros(numClasses, numClasses); % Matrice di confusione
totalImages = 0;
correctPredictions = 0;

fprintf('--- AVVIO TEST SU DATASET "%s" ---\n', basePath);

%% Ciclo sulle cartelle (Classi 1..6)
for trueLabel = 1:numClasses
    folderPath = fullfile(basePath, num2str(trueLabel));
    files = dir(fullfile(folderPath, '*.png'));
    
    if isempty(files)
        fprintf('Avviso: Cartella %d vuota o non trovata.\n', trueLabel);
        continue;
    end
    
    fprintf('Testando il numero %d (%d immagini)...\n', trueLabel, length(files));
    
    %% Ciclo sulle immagini
    for i = 1:length(files)
        filename = fullfile(folderPath, files(i).name);
        
        try
            % 1. Caricamento (Gestione Alpha)
            [img_rgb, ~, alpha] = imread(filename);
            
            % Fix rapido se manca alpha nel file
            if isempty(alpha)
                [h, w, ~] = size(img_rgb);
                alpha = 255 * ones(h, w, 'uint8');
            end
            
            % -----------------------------------------------------
            % STEP 1: SEGMENTAZIONE
            % Chiama la tua funzione di estrazione maschera
            mask_binaria = estrai_cifra(img_rgb, alpha);
            
            % -----------------------------------------------------
            % STEP 2: DECODIFICA / PREDIZIONE
            % Chiama la tua funzione che gestisce il KNN internamente
            pred = decodifica_cifra(mask_binaria);
            
            % -----------------------------------------------------
            % Verifica Risultato
            % Nota: decodifica_cifra potrebbe ritornare 0 se la maschera è vuota
            if pred >= 1 && pred <= 6
                confMat(trueLabel, pred) = confMat(trueLabel, pred) + 1;
                
                if pred == trueLabel
                    correctPredictions = correctPredictions + 1;
                end
            else
                % Se pred è 0 o altro (errore segmentazione), contiamo come errore generico
                % (Opzionale: puoi stampare il nome del file per debug)
                % fprintf('Fallimento su file: %s (Pred: %d)\n', files(i).name, pred);
            end
            
            totalImages = totalImages + 1;
            
        catch ME
            fprintf('Errore critico su %s: %s\n', files(i).name, ME.message);
        end
    end
end

%% Calcolo e Stampa Risultati
if totalImages > 0
    accuracy = (correctPredictions / totalImages) * 100;
    
    fprintf('\n========================================\n');
    fprintf(' RISULTATI FINALI TEST REALE\n');
    fprintf('========================================\n');
    fprintf('Totale Immagini:    %d\n', totalImages);
    fprintf('Corrette:           %d\n', correctPredictions);
    fprintf('ACCURACY:           %.2f%%\n', accuracy);
    fprintf('----------------------------------------\n');
    
    % Visualizza la Matrice di Confusione
    figure;
    confusionchart(confMat, 1:6);
    title(['Performance Reali (Acc: ' num2str(accuracy, '%.1f') '%)']);
else
    fprintf('\nNessuna immagine processata. Controlla il percorso "numeri".\n');
end