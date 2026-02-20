fprintf('Configurazione percorsi in corso... ');

rootFolder = fileparts(mfilename('fullpath'));

addpath(fullfile(rootFolder, 'src'));

addpath(fullfile(rootFolder, 'src', 'cifra'));

fprintf('FATTO!\n');
fprintf('Ora process_frame può vedere estrai_dadi dentro src.\n');