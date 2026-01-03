clear all; close all; clc;

% --- CONFIGURAZIONE ---
dataset_folder = 'cifre_balanced'; % Assicurati che il nome della cartella sia giusto ('cifre' o 'numeri')
k_neighbors = 5;          

fprintf('--- CARICAMENTO DATI E ESTRAZIONE FEATURE ---\n');

TrainingFeatures = [];
TrainingLabels = [];

% 1. CICLO DI CARICAMENTO (Prima raccogliamo i dati)
for classe = 1:6
    subfolder = fullfile(dataset_folder, num2str(classe));
    
    if ~exist(subfolder, 'dir')
        fprintf('Attenzione: Cartella classe %d non trovata.\n', classe);
        continue; 
    end
    
    files = dir(fullfile(subfolder, '*.png'));
    num_files = length(files);
    fprintf('Classe %d: Sto elaborando %d immagini...\n', classe, num_files);
    
    for i = 1:num_files
        filename = fullfile(subfolder, files(i).name);
        
        % Leggi immagine
        img = imread(filename);
        mask = logical(img); 
        
        % CALCOLA FEATURE (Usa la nuova funzione con Circolarità e Logaritmi)
        feats = calcola_features(mask);
        
        % Aggiungi alla memoria
        TrainingFeatures = [TrainingFeatures; feats];
        TrainingLabels = [TrainingLabels; classe];
    end
end

if isempty(TrainingLabels)
    error('Nessun dato trovato! Controlla il nome della cartella.');
end

% 2. ADDESTRAMENTO (Ora che abbiamo i dati, creiamo il cervello)
fprintf('\nAddestramento KNN su %d campioni...\n', length(TrainingLabels));

% 'Standardize', 1 è il trucco che normalizza (z-score) tutte le feature automaticamente
Mdl_KNN = fitcknn(TrainingFeatures, TrainingLabels, ...
    'NumNeighbors', k_neighbors, ...
    'Standardize', 1, ...     
    'Distance', 'euclidean');

% Salvataggio
save('modello_knn.mat', 'Mdl_KNN');
fprintf('Modello salvato con successo.\n');

% 3. VERIFICA E DIAGNOSTICA
predizioni = predict(Mdl_KNN, TrainingFeatures);
accuratezza = sum(predizioni == TrainingLabels) / length(TrainingLabels) * 100;

fprintf('\n------------------------------------------------\n');
fprintf('ACCURATEZZA FINALE: %.2f%%\n', accuratezza);
fprintf('------------------------------------------------\n');

% 4. GRAFICO ERRORI (Fondamentale per capire)
figure('Name', 'Diagnosi Errori KNN');
confusionchart(TrainingLabels, predizioni);
title(['Matrice Confusione - Acc: ' num2str(accuratezza, '%.1f') '%']);