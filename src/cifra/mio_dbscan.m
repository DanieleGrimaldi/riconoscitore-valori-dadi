function labels = mio_dbscan(features)

    min_pts = 5;
    epsilon_base = 0.10;

    varianze_singole = var(features);
    varianza_totale = sum(varianze_singole);
    
    epsilon = epsilon_base + (varianza_totale * 0.2);

    num_punti = size(features, 1);
    labels = zeros(num_punti, 1); 
    C = 0; 
    
    for i = 1:num_punti

        if labels(i) ~= 0
            continue;
        end
        
        vicini = trova_vicini(features, i, epsilon);
        
        if length(vicini) < min_pts
            labels(i) = -1; 
        else
            C = C + 1;
            labels(i) = C;
            
            k = 1;
            while k <= length(vicini)
                punto_corrente = vicini(k);
                
                if labels(punto_corrente) == -1
                    labels(punto_corrente) = C;
                end
                
                if labels(punto_corrente) == 0
                    labels(punto_corrente) = C;
                    nuovi_vicini = trova_vicini(features, punto_corrente, epsilon);
                    
                    if length(nuovi_vicini) >= min_pts
                        vicini = unique([vicini; nuovi_vicini]); 
                    end
                end
                k = k + 1;
            end
        end
    end
end


function indici_vicini = trova_vicini(features, idx, epsilon)

    punto_ref = features(idx, :);
    
    distanze = sqrt(sum((features - punto_ref).^2, 2));
    
    indici_vicini = find(distanze <= epsilon);
end