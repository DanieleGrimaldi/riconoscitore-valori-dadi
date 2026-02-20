function features = calcola_features(mask_binaria)
    % Restituisce [Circolarità, Euler, Eccentricity, Solidity, Hu1_Log, Hu2_Log]
    
    if sum(mask_binaria(:)) == 0
        features = zeros(1, 6); 
        return;
    end

    % 1. Geometria
    stats = regionprops(mask_binaria, 'Area', 'EulerNumber', 'Eccentricity', 'Solidity', 'Perimeter');
    [~, idx] = max([stats.Area]);
    s = stats(idx);
    
    % 2. Hu Moments (con protezione errori)
    try
        hu = invmoments(mask_binaria);
    catch
        hu = zeros(1, 7); 
    end
    
    % --- NORMALIZZAZIONE E TRASFORMAZIONE ---
    
    % A. Circolarità (Invariante alla scala/zoom)
    % 1.0 = Cerchio perfetto. Più scende, più è allungato o frastagliato.
    if s.Perimeter > 0
        circularity = (4 * pi * s.Area) / (s.Perimeter ^ 2);
    else
        circularity = 0;
    end
    
    % B. Logaritmo sui Momenti di Hu (Per portarli su scala umana)
    % Usiamo -sign() * log10(abs()) per gestire numeri negativi e piccolissimi.
    hu_log = -sign(hu) .* log10(abs(hu) + 1e-10); 
    
    % --- ASSEMBLAGGIO ---
    
    f1 = circularity;          % Forma (Cerchio vs Linea)
    f2 = double(s.EulerNumber);% Buchi (Topologia)
    f3 = s.Eccentricity;       % Allungamento
    f4 = s.Solidity;           % Compattezza (Distingue 4 da 0)
    f5 = hu_log(1);            % Momento 1 (Massa sparpagliata)
    f6 = hu_log(2);            % Momento 2 (Massa sparpagliata)
    
    features = [f1, f2, f3, f4, f5, f6];
    
    % Pulizia NaN/Inf
    features(isnan(features)) = 0;
    features(isinf(features)) = 0;
end