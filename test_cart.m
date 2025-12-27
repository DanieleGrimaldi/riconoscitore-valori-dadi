clear all; close all; clc;

% --- 1. CARICAMENTO DATI DI TRAINING ---
fprintf('Caricamento dataset training (Esclusi video 08 e 10)...\n');

if ~isfile('dati_sfondo_clean.mat') || ~isfile('dati_dadi_clean.mat')
    error('File dati mancanti!');
end

load('dati_sfondo_clean.mat', 'pixel_sfondo'); % Classe 0
load('dati_dadi_clean.mat', 'pixel_dadi');     % Classe 1

% --- 2. UNIONE DI TUTTO ---
% Non dividiamo niente, usiamo tutto il blocco.
X = [pixel_sfondo; pixel_dadi];
Y = [zeros(size(pixel_sfondo, 1), 1); ones(size(pixel_dadi, 1), 1)];

fprintf('Totale Pixel Training: %d\n', length(Y));

% --- 3. ADDESTRAMENTO ---
fprintf('Addestramento modello su tutti i dati...\n');
% Usiamo l'albero decisionale standard
treeModel = fitctree(X, Y, 'PredictorNames', {'L', 'A', 'B'});

% --- 4. VERIFICA (Resubstitution) ---
fprintf('Verifica in corso (Riclassificazione dati training)...\n');
Y_predicted = predict(treeModel, X);

% --- 5. TABELLA (MATRICE CONFUSIONE) ---
% 0 = Sfondo, 1 = Dado
C = confusionmat(Y, Y_predicted);

% Estraiamo i valori per la tabella
Sfondo_Giusto   = C(1,1); % TN
Sfondo_Sbagliato= C(1,2); % FP (Sfondo scambiato per Dado)
Dadi_Sbagliati  = C(2,1); % FN (Dado scambiato per Sfondo)
Dadi_Giusti     = C(2,2); % TP

% --- OUTPUT TABELLARE RICHIESTO ---
fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('                TABELLA RISULTATI (PIXEL)\n');
fprintf('------------------------------------------------------------\n');
fprintf('                  | PREDETTO: SFONDO | PREDETTO: DADO\n');
fprintf('------------------|------------------|------------------\n');
fprintf('REALE: SFONDO     | %12d     | %12d\n', Sfondo_Giusto, Sfondo_Sbagliato);
fprintf('                  | (Corretti)       | (Errori)\n');
fprintf('------------------|------------------|------------------\n');
fprintf('REALE: DADO       | %12d     | %12d\n', Dadi_Sbagliati, Dadi_Giusti);
fprintf('                  | (Errori)         | (Corretti)\n');
fprintf('------------------------------------------------------------\n\n');

% Percentuali per comodità
acc_sfondo = (Sfondo_Giusto / (Sfondo_Giusto + Sfondo_Sbagliato)) * 100;
acc_dadi   = (Dadi_Giusti / (Dadi_Giusti + Dadi_Sbagliati)) * 100;

fprintf('Il modello riconosce il %.2f%% dello sfondo correttamente.\n', acc_sfondo);
fprintf('Il modello riconosce il %.2f%% dei dadi correttamente.\n', acc_dadi);