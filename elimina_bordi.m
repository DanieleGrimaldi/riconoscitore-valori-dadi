function mask_pulita = elimina_bordi(mask_input)
    % ELIMINA_BORDI: Rimuove dalla maschera binaria tutti gli oggetti 
    % che toccano anche solo con un pixel il bordo dell'immagine.
    
    % 1. Etichetta tutti gli oggetti connessi (Labeling)
    % L è una matrice dove ogni oggetto ha un numero diverso (1, 2, 3...)
    [L, num_objects] = bwlabel(mask_input);
    
    [h, w] = size(mask_input);
    
    % 2. Estrai i pixel dei 4 bordi
    bordo_top    = L(1, :);       % Prima riga
    bordo_bottom = L(h, :);       % Ultima riga
    bordo_left   = L(:, 1)';      % Prima colonna (trasposta)
    bordo_right  = L(:, w)';      % Ultima colonna (trasposta)
    
    % 3. Metti insieme tutti i valori trovati sui bordi
    tutti_i_bordi = [bordo_top, bordo_bottom, bordo_left, bordo_right];
    
    % 4. Trova le etichette uniche da rimuovere
    % 'unique' ci dà la lista degli oggetti (ID) che toccano il bordo.
    labels_da_rimuovere = unique(tutti_i_bordi);
    
    % Rimuoviamo lo 0 dalla lista (perché lo 0 è lo sfondo nero, non va rimosso)
    labels_da_rimuovere(labels_da_rimuovere == 0) = [];
    
    % 5. Genera la maschera pulita
    if isempty(labels_da_rimuovere)
        % Se nessun oggetto tocca il bordo, la maschera resta uguale
        mask_pulita = mask_input;
    else
        % 'ismember(L, labels)' crea una maschera degli oggetti da cancellare
        % Noi vogliamo tenere tutto ciò che NON è in quella lista.
        mask_pulita = mask_input;
        mask_pulita(ismember(L, labels_da_rimuovere)) = 0;
    end
end