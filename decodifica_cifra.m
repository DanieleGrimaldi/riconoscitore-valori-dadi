function numero_predetto = decodifica_cifra(mask_binaria)
    % DECODIFICA_CIFRA
    % 1. Gestisce il modello KNN in modo persistente (caricato 1 sola volta)
    % 2. Estrae le feature dalla maschera
    % 3. Restituisce il numero predetto

    % --- GESTIONE MEMORIA PERSISTENTE ---
    persistent Mdl_Internal; % Variabile che "ricorda" il valore tra una chiamata e l'altra
    
    % Se è la prima volta che chiami la funzione (o se è vuota), carica il file
    if isempty(Mdl_Internal)
        if exist('modello_knn.mat', 'file')
            loaded_data = load('modello_knn.mat', 'Mdl_KNN');
            Mdl_Internal = loaded_data.Mdl_KNN;
            % fprintf(' [SISTEMA] Modello KNN caricato in memoria persistente.\n');
        else
            error('Errore: File modello_knn.mat non trovato!');
        end
    end

    % --- ESECUZIONE ---
    
    % 1. Controllo sicurezza (se maschera vuota)
    if sum(mask_binaria(:)) < 5
        numero_predetto = 0;
        return;
    end

    % 2. Calcolo Feature (chiama la tua funzione calcola_features.m)
    features = calcola_features(mask_binaria);
    
    % 3. Predizione
    numero_predetto = predict(Mdl_Internal, features);

end