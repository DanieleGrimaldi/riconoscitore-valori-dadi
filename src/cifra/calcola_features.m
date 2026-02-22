function features = calcola_features(mask_binaria)
    % Restituisce [Circularity, EulerNumber, Eccentricity, Solidity, Hu1_Log, Hu2_Log]
    
    % 1. Estrazione Geometria Base (1 sola forma garantita)
    stats = regionprops(mask_binaria, 'Area', 'EulerNumber', 'Eccentricity', 'Solidity', 'Perimeter');
    
    % 2. Calcolo NATIVO e matematico dei Momenti di Hu (Hu1 e Hu2)
    [y, x] = find(mask_binaria);
    
    % Baricentro e Area (m00)
    x_bar = mean(x);
    y_bar = mean(y);
    m00 = length(x);
    
    % Momenti centrali
    mu20 = sum((x - x_bar).^2);
    mu02 = sum((y - y_bar).^2);
    mu11 = sum((x - x_bar) .* (y - y_bar));
    
    % Momenti normalizzati al quadrato
    eta20 = mu20 / (m00^2);
    eta02 = mu02 / (m00^2);
    eta11 = mu11 / (m00^2);
    
    % Formule dei primi due invarianti di Hu
    hu1 = eta20 + eta02;
    hu2 = (eta20 - eta02)^2 + 4 * (eta11^2);
    
    % --- TRASFORMAZIONI MATEMATICHE ---
    
    % Circolarità
    if stats.Perimeter > 0
        circularity = (4 * pi * stats.Area) / (stats.Perimeter ^ 2);
    else
        circularity = 0;
    end
    
    % Logaritmo sui Momenti di Hu 1 e 2
    hu_log1 = -sign(hu1) * log10(abs(hu1) + 1e-10);
    hu_log2 = -sign(hu2) * log10(abs(hu2) + 1e-10);
    
    % --- ASSEMBLAGGIO FINALE ---
    features = [circularity, double(stats.EulerNumber), stats.Eccentricity, stats.Solidity, hu_log1, hu_log2];
    
    % Protezione finale da valori non validi (NaN/Inf)
    features(isnan(features)) = 0;
    features(isinf(features)) = 0;
end