% Se avete problemi a decodificare il video, avete bisogno dei codec.
% Per Windows: https://codecguide.com/download_kl.htm
%
function process_video(filename)
    close all;

    vidObj = VideoReader(filename);
    [~, videoName, ~] = fileparts(filename);

    stopVideo = false;


    frameNumber = 0;

    while hasFrame(vidObj) && not(stopVideo)
        vidFrame = readFrame(vidObj);
        frameNumber = frameNumber + 1;
        process_frame(videoName, frameNumber, vidFrame);
    end

    
    fprintf('\n>>> Fine video.\n');
end