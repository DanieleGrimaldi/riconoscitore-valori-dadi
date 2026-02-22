function numero_predetto = decodifica_cifra(mask_binaria)

    persistent Mdl_Internal; 
    
    if isempty(Mdl_Internal)
        if exist('modello_knn.mat', 'file')
            loaded_data = load('modello_knn.mat');
            campi = fieldnames(loaded_data);
            Mdl_Internal = loaded_data.(campi{1});
        else
            error('Errore: File modello_knn.mat non trovato!');
        end
    end

    features = calcola_features(mask_binaria);
    
    numero_predetto = predict(Mdl_Internal, features);

end