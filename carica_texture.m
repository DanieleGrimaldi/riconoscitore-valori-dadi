clc;
fprintf('=== INIZIO CREAZIONE DATASET PULITO ===\n');

% 1. Processa i Dadi
processa_dadi();

fprintf('\n---------------------------------------\n');

% 2. Processa gli Sfondi
processa_sfondi();

fprintf('\n=== TUTTO COMPLETATO ===\n');
fprintf('Ora puoi usare "dati_dadi_clean.mat" e "dati_sfondo_clean.mat" per il training.\n');


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