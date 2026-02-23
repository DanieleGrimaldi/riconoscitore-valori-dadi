function process_video(filename)

    vidObj = VideoReader(filename);
    [~, videoName, ~] = fileparts(filename);

    stopVideo = false;


    frameNumber = 0;

    while hasFrame(vidObj) && not(stopVideo)
        vidFrame = readFrame(vidObj);
        frameNumber = frameNumber + 1;
        if mod(frameNumber, 2) ~= 0
            process_frame(videoName, vidFrame); 
        end
        
    end

    
    fprintf('\n>>> Fine video.\n');
end