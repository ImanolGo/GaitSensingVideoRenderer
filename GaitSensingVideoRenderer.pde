

/**
  * Gait Sensing Video Renderer
  *    Berlin 27/08/14
  *    by Imanol Gómez 
  *    www.imanolgomez.net
  * 
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
int fps = 10;
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
  
  startBashScript();
  loadMidiInfo();
  createVideo();
  saveFramesToVideos();
  concatenateVideos();
  closeBashScript();
  runCommands();
  exit();
  noLoop(); // only draw once
}

void draw() {
  
  //background(255);
  
  //image(myMovie, 0, 0);
}

void startBashScript(){
  // Create a new file in the sketch directory
    createVideoScript = createWriter(scriptName); 
    createVideoScript.println("#!/bin/bash");  // Start the Bourne shell
    createVideoScript.print("\n");  // break code
    createVideoScript.println("echo Starting video creation script...");  // Echo starting script
    
    runCommand("echo Starting video creation script...");
}

void loadMidiInfo() {
    println("Load Midi Info");
    loadNotes();
    loadSteps();
}

void createVideo() {
   
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
        //createScriptBlankVideo();
    }
    else{
      println("Data folder has no mp4 format videos ");
    }
  
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
      Notes_ = loadMidi(path ,tempo);
      MidiDuration = getMidiDuration(path);
      println("MidiDuration: "+ MidiDuration + "s");
    }else { 
      println("Data folder has no midi format files ");
    } 
      
}

void loadSteps() {
 
    Steps = new ArrayList();  // Create an empty ArrayList
    Map<String,Integer> mpNumber=new HashMap<String, Integer>();
    Map<String,Step> mpSteps=new HashMap<String, Step>();
    
    for(int i=0; i<Notes_.size();i++)
    {  
       Note note =(Note) Notes_.get(i);
        if(!mpNumber.containsKey(note.m_sNote)){
            mpNumber.put(note.m_sNote, 1);
        }
        else{
          if(note.m_on)
          {
            mpNumber.put(note.m_sNote,mpNumber.get(note.m_sNote)+1);
          }
        }
        
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
          }
        }
        
    }
}

void saveFramesToVideos() {
  
  println("Save frames to images... ");
  
  createVideoScript.print("\n");  // break code
  createVideoScript.println("echo Creating images from frames ...");  // Echo images from frames
  createVideoScript.println("cd " + dataPath(""));  // create output folder
  createVideoScript.println("mkdir images");
  
  runCommand("echo Creating images from frames ...");  // Echo images from frames
  runCommand("cd " + dataPath(""));  // create output folder
  runCommand("mkdir images");
  
  
  String blankVideoName = "output/blankVideo.mp4" ; 
  String videoName = "output/excerpt.mp4" ; 
  
  //for(int i=0; i<Steps.size();i++)
  int excerptNumber = 0;
  for(int i=0; i<100;i++)
  { 
    Step step =(Step) Steps.get(i); 
    float nextFrame = step.m_fTime;
    String imageName = "images/p_steps_"+ nextFrame +".jpg";
    String ffmpegCommand = "/usr/local/bin/ffmpeg -i " + InputVideoName + 
    " -ss " + timeToFormatted((int) (nextFrame*1000)) + 
    " -f image2 -vframes 1 " + imageName + " -y";
   
    createVideoScript.println(ffmpegCommand);  // create image from frame
    runCommand(ffmpegCommand);  // create image from frame
    
//    ffmpegCommand = "ffmpeg -i " + blankVideoName + 
//    " -i " + imageName + " -filter_complex" + 
//    " \"[0:v][1:v]overlay=0:0:enable=between(t\\," + step.m_fTime + "\\," + str(step.m_fTime + step.m_fDuration) + ")\"" + 
//    " -codec:a copy " + blankVideoName + " -y";

    float duration = step.m_fTime + step.m_fDuration;
    if(i +1 < Steps.size()){
      Step nextStep =(Step) Steps.get(i+1); 
      duration = nextStep.m_fTime - step.m_fTime;
    }
    
    if(duration>0){
       videoName = "output/excerpt" + excerptNumber +".mp4" ; 
       ffmpegCommand = "/usr/local/bin/ffmpeg -loop 1 -f image2 -i " + imageName + " -c:v libx264 -pix_fmt yuv420p" +
       " -r " + fps + " -t " + duration + " " + videoName + " -y";
       createVideoScript.println(ffmpegCommand);  // create a video from the image
       runCommand(ffmpegCommand);  // create a video from the image
       excerptNumber++;
    }
  }
  
}

void concatenateVideos() {
    createConcatenatingList();
    createVideoScript.println("echo Concatenate videos ...");  // Echo Create concating videos list 
    createVideoScript.print("\n");  // break code
    createVideoScript.println("cd " + dataPath("") + "/output");  // break code
    createVideoScript.println("/usr/local/bin/ffmpeg -f concat -i mylist.txt -c copy output.mp4");  // generate a list file containing every *.mp4 in the working directory
    
    runCommand("echo Concatenate videos ...");  // Echo Create concating videos list 
    runCommand("cd " + dataPath("") + "/output");  // break code
    runCommand("/usr/local/bin/ffmpeg -f concat -i mylist.txt -c copy output.mp4");  // generate a list file containing every *.mp4 in the working directory
}

void createConcatenatingList() {
  
    createVideoScript.println("cd " + dataPath("") + "/output");  // break code
    createVideoScript.println("echo Create concatenating videos list ...");  // Echo Create concating videos list 
    createVideoScript.print("\n");  // break code
    createVideoScript.println("printf \"file \'%s\'\\n\" ./*.mp4 > mylist.txt");  // generate a list file containing every *.mp4 in the working directory
    
    runCommand("cd " + dataPath("") + "/output");  // break code
    runCommand("echo Create concatenating videos list ...");  // Echo Create concating videos list 
    runCommand("printf \"file \'%s\'\\n\" ./*.mp4 > mylist.txt");  // generate a list file containing every *.mp4 in the working directory
}

void runCommand(String commandToRun) {

  // what command to run
  //String commandToRun = "bash -x " + scriptName;

  File workingDir = new File(sketchPath(""));   // where to do it - should be full path
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


void createScriptBlankVideo()
{
   String videoName = "blankVideo.mp4" ; 
   println("Create script blank video ");
   
   myMovie.read();
   PImage newImage = (PImage) myMovie;
   
   float duration =  myMovie.duration();
   duration = 10;
   int frame_rate =  25;
    
   //String ffmpegCommand = "ffmpeg -t 10 -s 640x480 -f lavfi -pix_fmt rgb24 -r 25 -i " + path;
   String ffmpegCommand = "ffmpeg -t " + duration + 
   " -s " + newImage.width + "x" + newImage.height + 
   " -f rawvideo -pix_fmt rgb24 -r " + frame_rate +
   " -i /dev/zero " + videoName;
   
   createVideoScript.print("\n");  // break code
   createVideoScript.println("echo Creating blank video: size-> " + newImage.width + "x" + newImage.height
   + ", duration-> " + duration + "s, frame rate -> " + frame_rate + "fps" );  // Echo creating blank video
   createVideoScript.println("cd " + dataPath(""));  // create output folder
   createVideoScript.println("mkdir output");
   createVideoScript.println("cd output");  
   createVideoScript.print("\n");  // break code 
   createVideoScript.println(ffmpegCommand);  //  creating blank video 
   
   println("Creating blank video: size-> " + newImage.width + "x" + newImage.height
   + ", duration-> " + duration + "s, frame rate -> " + frame_rate + "fps" );
}


// Called every time a new frame is available to read
void movieEvent(Movie m) {
  m.read();
}

void stop() { //it is called whenever a sketch is closed. 
   closeBashScript();
   println("App stopped");
} 

void keyPressed() {
  if (key == ESC) {
    closeBashScript();
    println("App exit");
    exit(); // Stops the program
  }
}

void closeBashScript() { 
   deleteJunkFiles();
   createVideoScript.flush(); // Writes the remaining data to the file
   createVideoScript.close(); // Finishes the file
   println("Close Video Bash Script");
} 

void deleteJunkFiles() { 
   createVideoScript.print("\n");  // break code
   createVideoScript.println("echo Deleting junk files ...");  // Deleting junk files ... 
   createVideoScript.println("cd " + dataPath(""));  // enter data path 
   createVideoScript.println("rm images/*.jpg"); //remove all images
   createVideoScript.println("rm output/excerpt*"); //remove all videos starting with excerpt
   
   runCommand("echo Deleting junk files ...");  // Deleting junk files ... 
   runCommand("cd " + dataPath(""));  // enter data path 
   runCommand("rm images/*.jpg"); //remove all images
   runCommand("rm output/excerpt*"); //remove all videos starting with excerpt
   
   println("Delete Junk Files");
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
 
  String formattedTime = hours + ":" + minutes + ":" + seconds + "." + milliseconds ;
  return formattedTime;
}
