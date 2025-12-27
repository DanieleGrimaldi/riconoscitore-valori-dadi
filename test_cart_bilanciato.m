clear all; close all; clc;

% --- 1. CARICAMENTO DATI ---
fprintf('Caricamento dataset...\n');
if ~isfile('dati_sfondo_clean.mat') || ~isfile('dati_dadi_clean.mat')
    error('File dati mancanti!');
end
load('dati_sfondo_clean.mat', 'pixel_sfondo'); % Classe 0
load('dati_dadi_clean.mat', 'pixel_dadi');     % Classe 1

% --- 2. BILANCIAMENTO DATI (Random Under-Sampling) ---
fprintf('Bilanciamento dati in corso...\n');

% Contiamo quanti sono i pixel dei dadi (la classe minoritaria)
n_dadi = size(pixel_dadi, 1);
n_sfondo_totali = size(pixel_sfondo, 1);

% Generiamo indici casuali per lo sfondo
% randperm(N, K) restituisce K valori unici casuali tra 1 e N
indices_sfondo_random = randperm(n_sfondo_totali, n_dadi);

% Selezioniamo i pixel di sfondo usando questi indici casuali
pixel_sfondo_bilanciato = pixel_sfondo(indices_sfondo_random, :);

fprintf('Pixel Dadi originali: %d\n', n_dadi);
fprintf('Pixel Sfondo selezionati (Random): %d (su %d totali)\n', length(pixel_sfondo_bilanciato), n_sfondo_totali);

% Creiamo il dataset X e Y bilanciato (50% Dadi, 50% Sfondo)
X = [pixel_sfondo_bilanciato; pixel_dadi];
Y = [zeros(n_dadi, 1); ones(n_dadi, 1)]; % Ora sono uguali: n_dadi per entrambi

fprintf('Totale Pixel Training (Bilanciato): %d\n', length(Y));

% --- 3. ADDESTRAMENTO ---
fprintf('Addestramento modello sui dati bilanciati...\n');
% Nota: Non serve più 'Prior' perché i dati sono fisicamente bilanciati ora
treeModel = fitctree(X, Y, 'PredictorNames', {'L', 'A', 'B'});

% --- 4. VERIFICA (Resubstitution su dati bilanciati) ---
fprintf('Verifica in corso...\n');
Y_predicted = predict(treeModel, X);

% --- 5. TABELLA (MATRICE CONFUSIONE) ---
% 0 = Sfondo, 1 = Dado
C = confusionmat(Y, Y_predicted);

% Estraiamo i valori per la tabella
Sfondo_Giusto   = C(1,1); % TN
Sfondo_Sbagliato= C(1,2); % FP
Dadi_Sbagliati  = C(2,1); % FN
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

% Percentuali
acc_sfondo = (Sfondo_Giusto / (Sfondo_Giusto + Sfondo_Sbagliato)) * 100;
acc_dadi   = (Dadi_Giusti / (Dadi_Giusti + Dadi_Sbagliati)) * 100;

fprintf('Il modello riconosce il %.2f%% dello sfondo correttamente.\n', acc_sfondo);
fprintf('Il modello riconosce il %.2f%% dei dadi correttamente.\n', acc_dadi);