

/**
  * Gait Sensing Video Renderer
  *    Berlin 16/09/14
  *    by Imanol Gómez 
  *    www.imanolgomez.net
  *    version 1.2 
  * 
*/

import javax.swing.*; 
import javax.swing.filechooser.FileNameExtensionFilter;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;
import java.io.InputStreamReader;

import processing.video.*;
Movie myMovie;
int lastFrame = 0;
int fps = 60;
PrintWriter createVideoScript;

ArrayList Notes_;
ArrayList Steps;
float MidiDuration;
PFont fontA;
float tempo = 60;
int spm = 60; //seconds per minute
ArrayList m_Durations = new ArrayList();
ArrayList lines = new ArrayList();

String InputVideoName;
String InputSoundName;

String scriptName = "createVideo.sh";

//name of the file

class Step
{
  float m_fTime;
  String m_sNote;
  float m_fDuration;
}


void setup() {
  size(400, 400);
  frameRate(fps);
  
  println("---------------------------------------------\n");
  println("Processing videos...\nPlease be patient, it will take some time...\n");
  
  loadMidiInfo();
  loadVideo();
  saveFramesToVideos();
  concatenateVideos();
  deleteJunkFiles();
  addSoundToVideo();
  
  println("END\n");
  println("---------------------------------------------\n");
  
  
  exit();
  noLoop(); // only draw once
}

void draw() {
  
  //image(myMovie, 0, 0);
}

void loadMidiInfo() {
    println("Load Midi Info");
    loadNotes();
    loadSteps();
}

void saveFramesToVideos() {
  
  PrintWriter mylist = createWriter("data/output/mylist.txt"); 
  mylist.println("# this is a comment"); 
  
  println("Save frames to images... ");
  
  runCommand("echo Creating images from frames ...");  // Echo images from frames
  runCommand("mkdir " + dataPath("") + "/images");
  runCommand("mkdir " + dataPath("") + "/output");
  
  String videoName = "data/output/excerpt.mp4" ; 
  String inputVideoPath = "data/" +  InputVideoName; 
  
  //for(int i=0; i<Steps.size();i++)
  int excerptNumber = 0;
  for(int i=0; i<Steps.size();i++)
  { 
    int frameNumber  = i + 1;
    println("Saving frame ( " + frameNumber +" / "+ Steps.size() + ")");
    
    Step step =(Step) Steps.get(i); 
    float nextFrame = step.m_fTime;
    String imageName = "data/images/p_steps_"+ nextFrame +".jpg";
    String ffmpegCommand = "/usr/local/bin/ffmpeg -i " + inputVideoPath + 
    " -ss " + timeToFormatted((int) (nextFrame*1000)) + 
    " -f image2 -vframes 1 " + imageName + " -n";
   
    runCommand(ffmpegCommand);  // create image from frame

    float duration = step.m_fTime + step.m_fDuration;
    if(i +1 < Steps.size()){ 
      Step nextStep =(Step) Steps.get(i+1); 
      duration = nextStep.m_fTime - step.m_fTime;
    }
    
    if(duration>0){
      
       videoName = "data/output/excerpt" + excerptNumber + ".mp4" ; 
       
       ffmpegCommand = "/usr/local/bin/ffmpeg -loop 1 -f image2 -i " + imageName + " -c:v libx264 -pix_fmt yuv420p" +
       " -r " + fps + " -t " + duration + " " + videoName + " -n";
       runCommand(ffmpegCommand);  // create a video from the image
       mylist.println("file 'excerpt" + excerptNumber + ".mp4'"); 
             
       excerptNumber++;
    }
  }
  
  mylist.flush(); // Writes the remaining data to the file
  mylist.close(); // Finishes the file
  
}

void concatenateVideos() 
{
    String outputPath = dataPath("") + "/output/";
    
    runCommand("echo Concatenate videos ...");  // Echo Create concating videos list 
    
//    String command =  "for f in ./*.mp4; do echo \"file \'$f\'\" >> mylist.txt; done";
//    runCommand(command,outputPath);
    
    String command =  "/usr/local/bin/ffmpeg -f concat -i mylist.txt -c copy output.mp4 -y";
    runCommand(command,outputPath);
    
//    command =  "/usr/local/bin/ffmpeg -i output.mp4  -c copy -bsf:v h264_mp4toannexb -f mpegts intermediate1.ts -n";
//    runCommand(command,outputPath);
//    
//    command =  "/usr/local/bin/ffmpeg -i excerpt.mp4  -c copy -bsf:v h264_mp4toannexb -f mpegts intermediate2.ts";
//    runCommand(command,outputPath);
//    
//    command =  "/usr/local/bin/ffmpeg -i \"concat:intermediate1.ts|intermediate2.ts\" -c copy -bsf:a aac_adtstoasc output.mp4";
//    runCommand(command,outputPath);
  
    
//    runCommand("mkfifo data/output/temp1 data/output/temp2");  // 
//    String commannd = "/usr/local/bin/ffmpeg -i data/output/excerpt.mp4 -c copy -bsf:v h264_mp4toannexb -f mpegts data/output/temp1 2> /dev/null & \\"+
//    "/usr/local/bin/ffmpeg -i data/output/output.mp4 -c copy -bsf:v h264_mp4toannexb -f mpegts data/output/temp2 2> /dev/null & \\" +
//    "/usr/local/bin/ffmpeg -f mpegts -i \"concat:data/output/temp1|data/output/temp2\" -c copy -bsf:a aac_adtstoasc data/output/output.mp4";
   
}

void runCommand(String commandToRun) {
      runCommand(commandToRun,sketchPath(""));
}

void runCommand(String commandToRun, String path) {
  
 
  // what command to run
  //String commandToRun = "bash -x " + scriptName;

  File workingDir = new File(path);   // where to do it - should be full path
  String returnedValues;                        // value to return any results

  // give us some info:
  println("Running command: " + commandToRun);
  //println("Location:        " + workingDir);
  //println("---------------------------------------------\n");
  //println("Processing videos...\nPlease be patient, it will take some time...");

  // run the command!
  try {

    // complicated!  basically, we have to load the exec command within Java's Runtime
    // exec asks for 1. command to run, 2. null which essentially tells Processing to 
    // inherit the environment settings from the current setup (I am a bit confused on
    // this so it seems best to leave it), and 3. location to work (full path is best)
    Process p = Runtime.getRuntime().exec(commandToRun, null, workingDir);

    // variable to check if we've received confirmation of the command
    int i = p.waitFor();

    // if we have an output, print to screen
    if (i == 0) {

      // BufferedReader used to get values back from the command
      BufferedReader stdInput = new BufferedReader(new InputStreamReader(p.getInputStream()));

      // read the output from the command
      while ( (returnedValues = stdInput.readLine ()) != null) {
        println(returnedValues);
      }
    }

    // if there are any error messages but we can still get an output, they print here
    else {
      BufferedReader stdErr = new BufferedReader(new InputStreamReader(p.getErrorStream()));

      // if something is returned (ie: not null) print the result
      while ( (returnedValues = stdErr.readLine ()) != null) {
        println(returnedValues);
      }
    }
  }

  // if there is an error, let us know
  catch (Exception e) {
    println("Error running command!");  
    println(e);
  }

  // when done running command, quit
  //println("\n---------------------------------------------");
  //println("DONE!");
}


// Called every time a new frame is available to read
void movieEvent(Movie m) {
  m.read();
}

void keyPressed() {
  if (key == ESC) {
    println("App exit");
    exit(); // Stops the program
  }
}

void deleteJunkFiles() { 
   
   String outputPath = dataPath("") + "/output";
  
   println("Delete Junk Files");
   
   runCommand("echo Moving output ...");  // Deleting junk files ... 
   runCommand("mv -f " +  outputPath + "/output.mp4 " + dataPath("")); //move output file
   
   runCommand("echo Deleting junk files ...");  // Deleting junk files ... 
   runCommand("rm -r " +  dataPath("") + "/images"); //remove all images
   runCommand("rm -r " +  dataPath("") + "/output"); //remove all starting with excerpt
   
} 



void loadNotes() {
   
    java.io.File folder = new java.io.File(dataPath(""));             
    java.io.FilenameFilter midiFilter = new java.io.FilenameFilter() {  
      public boolean accept(File dir, String name) {
        return name.toLowerCase().endsWith(".mid");
      }
    };
  
    String[] filenames = folder.list(midiFilter);
    println("Midi files inside the data folder: ");
    println(filenames);
    
    if(filenames.length>0){
      Notes_ = new ArrayList();  // Create an empty ArrayList
      String midiFileName = filenames[0]; 
      String path = dataPath("") + "/" + midiFileName;
      println("Loading " + midiFileName + "...."); 
      println("Midi Duration: " + getMidiDuration(path) + "s" ); 
      Notes_ = loadMidi(path ,tempo);
      MidiDuration = getMidiDuration(path);
      println("MidiDuration: "+ MidiDuration + "s");
    }else { 
      println("Data folder has no midi format files ");
    } 
      
}

void loadSteps() {
 
    PrintWriter outputSteps = createWriter("data/steps.txt");
    Steps = new ArrayList();  // Create an empty ArrayList
    Map<String,Step> mpSteps=new HashMap<String, Step>();
    
    for(int i=0; i<Notes_.size();i++)
    {  
       Note note =(Note) Notes_.get(i);
        
        if(!mpSteps.containsKey(note.m_sNote)){
           if(note.m_on){
              Step step = new Step();
              step.m_fTime = note.m_fTime;
              step.m_sNote = note.m_sNote;
              step.m_fDuration = 0.0;  
              mpSteps.put(note.m_sNote, step);
           }
            
        }
        else{
          if(note.m_on)
          {
             Step step = mpSteps.get(note.m_sNote);
             step.m_fTime = note.m_fTime;
             mpSteps.put(note.m_sNote,step);
          }
          else{
             Step step = mpSteps.get(note.m_sNote);
             step.m_fDuration += note.m_fTime - step.m_fTime;
             mpSteps.put(note.m_sNote,step);
             
             Step s = new Step();
             s.m_fTime = step.m_fTime;
             s.m_fDuration = step.m_fDuration;
             s.m_sNote = step.m_sNote;
             Steps.add(s);
             
             outputSteps.println("Step " + Steps.size() + ": Note-> " + 
             s.m_sNote + ", Sarting-> " + timeToFormatted((int)(s.m_fTime*1000)) + "s, Ending-> "
             + timeToFormatted((int)(1000*(step.m_fTime+s.m_fDuration))) + "s"); // Write steps to the file
          }
        }
        
    }
    
     outputSteps.flush(); // Writes the remaining data to the file
     outputSteps.close(); // Finishes the file
}

void addSoundToVideo()
{
   String dataPath = dataPath("");
   String path = dataPath("") + "/" + InputSoundName;
    
    runCommand("echo add sound to video ...");  // Add sound to videos
    
    String command =  "/usr/local/bin/ffmpeg -i output.mp4 -i " + path + " -c:v copy -c:a aac -strict experimental output.mp4";
    runCommand(command,dataPath);  
}

String timeToFormatted(int timeInMiliSeconds) {

  int iHours =  timeInMiliSeconds/3600000;
  String hours = nf(iHours,2);

  int iMinutes =  (timeInMiliSeconds%3600000)/60000;
  String minutes = nf(iMinutes,2);

  int iSeconds =  (timeInMiliSeconds%60000)/1000;
  String seconds = nf(iSeconds,2);
  
  int iMilliSeconds =  timeInMiliSeconds%1000;
  String milliseconds = nf(iMilliSeconds,3);
  
  String formattedTime = hours + ":" + minutes + ":" + seconds + "." + milliseconds;
  
  return formattedTime;
}


void loadVideo() {
   
    java.io.File folder = new java.io.File(dataPath(""));             
    java.io.FilenameFilter mp4Filter = new java.io.FilenameFilter() {  
      public boolean accept(File dir, String name) {
        return name.toLowerCase().endsWith(".mp4");
      }
    };
  
    String[] filenames = folder.list(mp4Filter);
    println("Videos inside the data folder: ");
    println(filenames);
    
    if(filenames.length>0){
        InputVideoName = filenames[0];
        String path = dataPath("") + "/" + InputVideoName;
        println("Loading " + InputVideoName + "....");
        myMovie = new Movie(this, path);   
        myMovie.play();
        myMovie.pause();
        myMovie.read();
        println("Video Duration: "+ myMovie.duration() + "s");
        createBlackImage();
    }
    else{
      println("Data folder has no mp4 format videos ");
    }
}

void loadSound() {
   
    java.io.File folder = new java.io.File(dataPath(""));             
    java.io.FilenameFilter mp4Filter = new java.io.FilenameFilter() {  
      public boolean accept(File dir, String name) {
        return name.toLowerCase().endsWith(".aiff");
      }
    };
  
    String[] filenames = folder.list(mp4Filter);
    println("Sound inside the data folder: ");
    println(filenames);
    
    if(filenames.length>0){
        InputSoundName = filenames[0];
        String path = dataPath("") + "/" + InputSoundName;
        println("Loading " + InputSoundName + "....");
        myMovie = new Movie(this, path);   
    }
    else{
      println("Data folder has no sound format files ");
    }
  
}

void createBlackImage()
{
    PImage img = createImage(myMovie.width, myMovie.height, RGB);
    img.loadPixels();
    for (int i = 0; i < img.pixels.length; i++) {
      img.pixels[i] = color(0, 0, 0); 
    }
    img.updatePixels();
    img.save("data/images/blackImage.jpg");
}
