clear all; close all; clc;

% --- CONFIGURAZIONE ---
file_dadi   = 'dati_dadi_training.mat';   % Creato da impacchetta_pixel.m
file_sfondo = 'dati_sfondo_training.mat'; % Creato da impacchetta_sfondo.m
file_output = 'Modello_Pixel_Finale.mat'; % Il cervello addestrato

fprintf('--- TRAINING FINALE CART ---\n');

% 1. CARICAMENTO DATI
if ~isfile(file_dadi) || ~isfile(file_sfondo)
    error('Mancano i file .mat! Esegui prima gli script di impacchettamento.');
end

load(file_dadi, 'pixel_dadi');     % Carica la variabile 'pixel_dadi'
load(file_sfondo, 'pixel_sfondo'); % Carica la variabile 'pixel_sfondo'

num_dadi   = size(pixel_dadi, 1);
num_sfondo = size(pixel_sfondo, 1);

fprintf('1. Dati Caricati:\n');
fprintf('   - Pixel DADI:   %d\n', num_dadi);
fprintf('   - Pixel SFONDO: %d\n', num_sfondo);

% 2. BILANCIAMENTO (Undersampling)
% L'albero impara meglio se vede 50% dadi e 50% sfondo.
% Di solito lo sfondo ha molti più pixel. Ne prendiamo un numero uguale ai dadi.

n_train = min(num_dadi, num_sfondo);
fprintf('2. Bilanciamento Dataset su %d campioni per classe.\n', n_train);

% Mischiamo e selezioniamo i pixel dello sfondo
idx_bg = randperm(num_sfondo, n_train);
pixel_sfondo_bilanciati = pixel_sfondo(idx_bg, :);

% Se avessimo meno pixel di dadi (raro), prenderemmo tutti i dadi
idx_dadi = randperm(num_dadi, n_train); 
pixel_dadi_bilanciati = pixel_dadi(idx_dadi, :);

% 3. CREAZIONE DATASET (X e Y)
% X = Features (L, A, B)
% Y = Etichette (1=Dado, 0=Sfondo)

X = [pixel_dadi_bilanciati; pixel_sfondo_bilanciati];
Y = [ones(n_train, 1); zeros(n_train, 1)];

% 4. ADDESTRAMENTO
fprintf('3. Addestramento in corso... ');
tic;
% MinLeafSize = 50: Evita l'overfitting su singoli pixel rumorosi
TreeModel = fitctree(X, Y, ...
    'MinLeafSize', 50, ... 
    'PredictorNames', {'L', 'A', 'B'}, ...
    'ClassNames', [0, 1]); 
t = toc;
fprintf('Fatto in %.2f secondi.\n', t);

% 5. SALVATAGGIO
save(file_output, 'TreeModel');
fprintf('\n>>> MODELLO SALVATO: %s <<<\n', file_output);

% --- VERIFICA RAPIDA (Test visivo sullo Sfondo) ---
% Proviamo il modello sull'immagine di sfondo originale.
% Dovrebbe venire QUASI TUTTA NERA (perché è sfondo).
if isfile('SFONDO_ROI.jpg')
    img_test = imread('SFONDO_ROI.jpg');
else
    img_test = imread('SFONDO.jpg');
end

fprintf('Verifica modello sullo sfondo...\n');
lab_test = rgb2lab(img_test);
[h, w, ~] = size(img_test);
X_test = reshape(lab_test, h*w, 3);

pred = predict(TreeModel, X_test);
mask_pred = reshape(pred, h, w);

figure('Name', 'Test Qualità Modello', 'NumberTitle', 'off');
subplot(1,2,1); imshow(img_test); title('Immagine Sfondo');
subplot(1,2,2); imshow(mask_pred); title('Classificazione (Dovrebbe essere NERO)');

fprintf('Controlla la finestra: se l''immagine a destra è nera (o con pochi puntini bianchi), il modello è PERFETTO.\n');