clear; clc;

% --- CONFIGURAZIONE ---
input_folder  = 'frame-tagliati';   % Dove sono i PNG con solo i dadi
output_folder = 'mask2';            % Dove salvare le maschere binarie

% Crea la cartella di output se non esiste
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% Cerca i file PNG
files = dir(fullfile(input_folder, '*.png'));

if isempty(files)
    error('Nessun file PNG trovato in "%s".', input_folder);
end

fprintf('Trovati %d file PNG. Inizio binarizzazione (NO CART)...\n', length(files));

% --- CICLO DI ELABORAZIONE ---
for k = 1:length(files)
    nome_file = files(k).name;
    full_path_in = fullfile(input_folder, nome_file);
    full_path_out = fullfile(output_folder, nome_file);
    
    % 1. Leggi l'immagine e il canale Alpha (Trasparenza)
    [img_rgb, ~, alpha] = imread(full_path_in);
    
    % --- CREAZIONE MASCHERA BASE ---
    % Dobbiamo capire cosa è "dado" e cosa è "vuoto".
    
    if ~isempty(alpha)
        % CASO 1: Il PNG ha la trasparenza. È il metodo più affidabile.
        % La maschera è dove l'immagine NON è trasparente.
        % Usiamo una soglia bassa (es. 20 su 255) per evitare bordi semitrasparenti sporchi.
        mask = alpha > 10;
    else
        % CASO 2: Il PNG non ha trasparenza, ma lo sfondo è nero (0,0,0).
        % Convertiamo in grigio e prendiamo tutto ciò che non è quasi nero.
        img_gray = rgb2gray(img_rgb);
        
        % Metodo A: Soglia fissa (più sicuro se lo sfondo è davvero nero)
        mask = img_gray > 0; 
        
        % Metodo B (Alternativo): Soglia automatica di Otsu (se lo sfondo non è perfettamente nero)
        % mask = imbinarize(img_gray, 'global');
    end
    
    % --- POST-PROCESSING (Fondamentale per i dadi) ---
    
    % 2. Riempimento Buchi (imfill)
    % Serve per far diventare bianchi i puntini neri dentro il dado.
    mask = imfill(mask, 'holes');
    
    % 3. Pulizia (Opzionale ma consigliata)
    % Rimuove eventuale sporcizia piccolissima rimasta dal taglio (polvere)
    % Elimina oggetti più piccoli di 50 pixel.
    mask = bwareaopen(mask, 50);
    
    % 4. Salva la maschera binaria
    imwrite(mask, full_path_out);
    
    if mod(k, 50) == 0
        fprintf('Processati %d / %d\n', k, length(files));
    end
end

fprintf('Elaborazione completata. Maschere salvate in "%s".\n', output_folder);