close all;
clear all;

tic;

cartella = 'train';
files = dir(fullfile(cartella, '*.mp4')); % Cambia *.mp4 se sono .avi o .mov

fprintf('Trovati %d video da elaborare.\n', length(files));

% 2. Cicla su ogni file trovato
for k = 1:length(files)
    nome_file = files(k).name;                 % Es: "VIDEO-01.mp4"
    percorso_completo = fullfile(cartella, nome_file); % Es: "dati/VIDEO-01.mp4"
    
    fprintf('\n--------------------------------------\n');
    fprintf('VIDEO %d/%d: %s\n', k, length(files), nome_file);
    fprintf('--------------------------------------\n');
    
    % Chiama la tua funzione principale
    process_video(percorso_completo);
end

t = toc;

fprintf('\n--- TUTTI I VIDEO ELABORATI! ---\n');
