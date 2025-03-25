%Morsomme Gato 5 Video Processor
%---------------------------------------------------------------------
% You must have the computer vision toolbox installed
%
% Optionally to speed up this program, make sure you have the parallel
% Computing toolbox installed
%
% WARNING: MATLAB is supbar kinda for this and will not compress video
% if audio is also saved, so expect videos of 4min to have file
% sizes of around 12GB
%
% If you want to compress these videos, I recommend FFMPEG
%---------------------------------------------------------------------


%-------------------------------------------------------------------
% Uncomment this section if you specify the amount of threads in use
% 4 is set currently, but most computers can do 6
% MATLAB will automatically assign threads if this is commented
%-------------------------------------------------------------------
%delete(gcp('nocreate'));
%numberOfWorkers = 4;
%pool = parpool(numberOfWorkers);


%---------------------------------------------------------------------
% Specify What the Input Video is, and what the Output Title should be
% The output title must not be the same as the input
% Output format must be .avi (MATLAB is weird like this)
%---------------------------------------------------------------------
inFileName = 'shuttle.avi';
OutFileName = "Modified/XYLO.avi";

VideoOBJ = VideoReader(inFileName);
VideoOBJ.CurrentTime = 0.1;
s = struct("cdata",zeros(VideoOBJ.Height, VideoOBJ.Width, 3, "uint8"), colormap=[]);

%Grab the Audio
[Audio, SF] = audioread(inFileName);

%Save the Video
videoOutOBJ = vision.VideoFileWriter(OutFileName, "AudioInputPort", true, "FrameRate", VideoOBJ.FrameRate);
videoOutOBJ.VideoCompressor ="MJPEG Compressor";
audioPerFrame = int64(floor(size(Audio, 1)/ VideoOBJ.NumFrames));

%Process the Video using Multicore wizardry
disp(["PROCESSING VIDEO: " + inFileName])
k = 1;
kMul = 0;
%-------------------------------------------------------------------
% The batch size restricts memory usage as not to crash the Computer
% 750 is the maximum size, which takes about 2-3GB of ram, if you
% can handle more then feel free to up 750 to a larger number
%-------------------------------------------------------------------
batchSize = min(int32(VideoOBJ.NumFrames / 10), 750);
while(VideoOBJ.NumFrames > (kMul*batchSize+k))

    s(k).cdata = readFrame(VideoOBJ);
    k = k+1;
    
    if( mod(k, batchSize) == 0 || (k*kMul == VideoOBJ.NumFrames+1))
        %Process a Batch of Video

        %-----------------------------------------------------------------
        % Use 'parfor' if you have the Parallel Computing Toolbox
        % It will automatically assign threads unless specified on line 29
        %
        % If you do not have the toolbox then change 'parfor' into 'for'
        %
        % WARNING: Without parallel processing this program could
        % potentially run for hours
        %-----------------------------------------------------------------
        parfor C = 1:size(s, 2)

            %-------------------------------------------------------------
            % Here is where all image editing happends
            % Everything is processed in batches (noted above)
            %
            % s(C).cdata is the current image being processed
            %
            % C+kMul*k will give you the current frame number in the Video
            %
            % Below are various examples of what I have used
            %-------------------------------------------------------------


            %Histogram Equaliztion
            % s(C).cdata(:, :, 1) = histeq(s(C).cdata(:, :, 1));
            % s(C).cdata(:, :, 2) = histeq(s(C).cdata(:, :, 2));
            % s(C).cdata(:, :, 3) = histeq(s(C).cdata(:, :, 3));
            % s(C).cdata(:, :, :) = histeq(s(C).cdata(:, :, :));
            

            %Remove Red
            %s(C).cdata(:, :, 1) = 0;
        

            %Mess with RGB Values individually
            % for row = 1:size(s(C).cdata, 1)
            %     for col = 1:size(s(C).cdata, 2)
            %         %BGR
            %         if(s(C).cdata(row, col, 3) > s(C).cdata(row, col, 1) && s(C).cdata(row, col, 3) > s(C).cdata(row, col, 2))
            %             %s(C).cdata(row, col, 1) = 0;
            %             %s(C).cdata(row, col, 2) = 0;
            %             s(C).cdata(row, col, 3) = s(C).cdata(row, size(s(C).cdata, 2) - col + 1, 3);
            %         elseif(s(C).cdata(row, col, 2) > s(C).cdata(row, col, 1) && s(C).cdata(row, col, 2) > s(C).cdata(row, col, 3))
            %             %s(C).cdata(row, col, 1) = 0;
            %             s(C).cdata(row, col, 2) = s(C).cdata(row, size(s(C).cdata, 2) - col + 1, 2);
            %             %s(C).cdata(row, col, 3) = 0;
            %         else
            %             s(C).cdata(row, col, 1) = s(C).cdata(row, size(s(C).cdata, 2) - col + 1, 1);
            %             %s(C).cdata(row, col, 2) = 0;
            %             %s(C).cdata(row, col, 3) = 0;
            %         end
            %     end
            % end
            
        
            %Canny Edge Detection
            %s(C).cdata(:, :, 1) = edge(s(C).cdata(:, :, 1), 'canny') * 128;
            %s(C).cdata(:, :, 2) = edge(s(C).cdata(:, :, 2), 'canny') * 128;
            %s(C).cdata(:, :, 3) = edge(s(C).cdata(:, :, 3), 'canny') * 128;
        
            
            %Notify every 100th frame being processed
            if(mod(C+kMul*k, 100) == 0)
                disp(["Frame: " + num2str(C+(kMul*k))])
            end
            
        end
        
        %Write the Video batch
        disp(["WRITING VIDEO: Batch " + num2str(kMul)])
        for D = 1:(size(s, 2))
            step(videoOutOBJ, s(D).cdata, Audio(audioPerFrame*(D+kMul*k-1) + 1 : ...
                audioPerFrame*(D+kMul*k), :));
        end
    
        %Reset the counter for the next batch
        k=1;
        kMul = kMul + 1;
        clear s;
    end
end

release(videoOutOBJ)
disp(["Done!"])