 -- Prerequisites --

1. Check if your Homebrew installation is up to date. Open the Terminal under Applications/Terminal and execute: brew doctor.

2. If brew is not install execute: ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"

3. Install ffmpeg: brew install ffmpeg


 -- Usage --

 1. The Application "GaitSensingVideoRenderer" should be under "Documents/Processing/"

 2. Under the subfolder "data", you should copy the midi file with the steps and the matching video file with mp4 format.

 3. Press the play button to run the processing sketch.

 4. The application will now read all the steps and will create single still images every for every step. It will temporary save it under the subfolder "images".

 5. From every image it will afterwards create a video with a still image and the length appropriate to every step time.

 6. Be patient. This process will take some time. 

 7. If this process is interrupted, when running again it will start from the latest point. 

 8. Once the process is finished, it will concatenate all the video excerpts to create the final output video. 

 9. Finally, the application will delete all the intermediate images and videos.
