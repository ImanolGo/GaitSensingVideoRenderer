

/**
  * Gait Sensing Video Renderer
  *    Berlin 18/09/14
  *    by Imanol Gómez 
  *    www.imanolgomez.net
  *    version 3.0
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
import controlP5.*;

ControlP5 controlP5;
Textlabel textlabelInfo;
Textlabel textlabelProcess;

Movie myMovie;
int fps = 10;

ArrayList Notes_;
ArrayList Steps;
float MidiDuration;
PFont fontA;
float tempo = 60;

public int numberOfSteps = 5;
public float durationOfEachStep = 2;
int excerptNumber = 0;

String InputVideoName;
String InputSoundName;
PrintWriter outputVideos;

class Step
{
  float m_fTime;
  String m_sNote;
  float m_fDuration;
}


void setup() {
  
  setupGui();
  
  //startRendering();
}

void draw() {
  background(100);
  //image(myMovie, 0, 0);
}

void startRendering()
{
  println("---------------------------------------------\n");
  println("Processing videos...\nPlease be patient, it will take some time...\n");
  
  loadMidiInfo();
  initializeVideo();
  saveFramesToVideos();
  deleteJunkFiles();
  addSoundToVideo();
  
  println("END\n");
  println("---------------------------------------------\n");
  
}

void loadMidiInfo() {
    println("Load Midi Info");
    loadNotes();
    loadSteps();
}

void initializeVideo(){
    if(loadVideo()){
      createBlankVideo();
    }
}

void saveFramesToVideos() {
  
  outputVideos = createWriter("data/logFiles/outputVideos.txt"); 
  
  println("Save frames to images... ");
  
  runCommand("echo Creating images from frames ...");  // Echo images from frames
  runCommand("mkdir " + dataPath("") + "/images");
  runCommand("mkdir " + dataPath("") + "/output");
  
  String inputVideoPath = "data/" +  InputVideoName; 
  String outputVideoPath = "data/output/output.mp4";
  
  //Create first frame
  excerptNumber = 0;
  int frameNumber  = 0;
  int elapsedSteps  = 0;  
  for(int i=0; i<Steps.size();i++)
  { 
    if(elapsedSteps==0){
       extractImage(i);
       insertImage(i);
       excerptNumber++; 
    }    
     elapsedSteps = (elapsedSteps+1)%numberOfSteps;
  }

  outputVideos.flush(); // Writes the remaining data to the file
  outputVideos.close(); // Finishes the file
  
}


void extractImage(float time)
{
    String inputVideoPath = "data/" +  InputVideoName;
    String imageName = "data/images/p_steps_" + time + ".jpg";
    String ffmpegCommand = "/usr/local/bin/ffmpeg -i " + inputVideoPath + 
        " -ss " + timeToFormatted((int) (time*1000)) + 
        " -f image2 -vframes 1 " + imageName + " -n";
   
    runCommand(ffmpegCommand);  // create image from frame
}
void setupGui() {
  size(380,230);
  frameRate(25);
  controlP5 = new ControlP5(this);
  controlP5.setControlFont(new ControlFont(createFont("Georgia",15), 15));
  
  controlP5.addNumberbox("Number",numberOfSteps,50,50,80,30).setId(1);
  controlP5.addNumberbox("Duration",durationOfEachStep,200,50,80,30).setId(2);
  controlP5.addButton("buttonStart",0,50,250,80,30);
  
  String textInfo = "Number of steps: " + numberOfSteps + "\n\n" +
                    "Duration of each step: " + durationOfEachStep + "s";
                    
  textlabelInfo = controlP5.addTextlabel("info",textInfo,50,120);
  
  textlabelProcess = controlP5.addTextlabel("process","SET PARAMETERS",50,170);
   
  controlP5.controller("Number").setMax(25);
  controlP5.controller("Number").setMin(0);
  
  controlP5.controller("Duration").setMax(100);
  controlP5.controller("Duration").setMin(0);
}

void extractImage(int stepIndex)
{
    String inputVideoPath = "data/" +  InputVideoName;
    
    int stepNumber  = stepIndex + 1;
    println("Saving step ( " + stepNumber +" / "+ Steps.size() + ")");
    
    Step newStep =(Step) Steps.get(stepIndex); 
    float newStepTime = newStep.m_fTime;
    String imageName = "data/images/p_steps_"+ newStepTime +".jpg";
    String ffmpegCommand = "/usr/local/bin/ffmpeg -i " + inputVideoPath + 
      " -ss " + timeToFormatted((int) (newStepTime*1000)) + 
      " -f image2 -vframes 1 " + imageName + " -n";
   
    runCommand(ffmpegCommand);  // create image from frame
}

void insertImage(float startTime, float endTime)
{     
      String imageName = "data/images/p_steps_"+ startTime +".jpg";
      String creatingExcerptText = "Excerpt" + excerptNumber + ".mp4 -> Start:  " + timeToFormatted((int)(1000*startTime)) + ", End: " + timeToFormatted((int)(1000*(endTime)));
      outputVideos.println(creatingExcerptText);
      println(creatingExcerptText);
      runInsertImageCommand(imageName, startTime, endTime);    
}


void insertImage(int stepIndex)
{
    Step currentStep =(Step) Steps.get(stepIndex);
    int stepNumber  = stepIndex + 1; 
    float duration = 0.0;
    if(stepNumber + numberOfSteps > Steps.size()){
        duration = myMovie.duration() - currentStep.m_fTime;
        if(duration>durationOfEachStep){
          duration = durationOfEachStep;
        }
    }
    else{
      Step nextStep =(Step) Steps.get(stepIndex+numberOfSteps);
      duration = nextStep.m_fTime - currentStep.m_fTime;
      if(duration>durationOfEachStep){
          duration = durationOfEachStep;
       }
    }
    
    if(duration>0){
      String imageName = "data/images/p_steps_"+ currentStep.m_fTime +".jpg";
      String creatingExcerptText = "Excerpt" + excerptNumber + ".mp4 -> Start:  " + timeToFormatted((int)(1000*currentStep.m_fTime)) + ", End: " + timeToFormatted((int)(1000*(currentStep.m_fTime+duration)));
      outputVideos.println(creatingExcerptText);
      println(creatingExcerptText);
      runInsertImageCommand( imageName, currentStep.m_fTime, currentStep.m_fTime+duration);  
    }  
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
   
   println("Renaming to output.mp4 ...");  // Deleting junk files ... 
   excerptNumber--;
   String command = "mv data/output/output" + excerptNumber + ".mp4" + " data/output/output.mp4";
   runCommand(command);  // run rename command
      
   //runCommand("mv -f " +  outputPath + "/output.mp4 " + dataPath("")); //move output file
   
   runCommand("echo Deleting junk files ...");  // Deleting junk files ... 
   runCommand("rm -r " +  dataPath("") + "/images"); //remove all images
   runCommand("rm -r " +  dataPath("") + "/scripts"); //remove all scripts
   //runCommand("rm -r " +  dataPath("") + "/output"); //remove all starting with excerpt
   
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
 
    PrintWriter outputSteps = createWriter("data/logFiles/steps.txt");
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
   loadSound();
   joinSoundAndVideo();
  
}

void joinSoundAndVideo()
{
    String audioPath = dataPath("") + "/" + InputSoundName;
    String outputVideoPath = dataPath("") + "/output/output.mp4";
    String outputAudioVideoPath = dataPath("") + "/output/outputAudio.mp4";
    
    runCommand("echo add sound to video ...");  // Add sound to videos
      
    String command =  "/usr/local/bin/ffmpeg -y -i " +  outputVideoPath + " -i " + audioPath + " -c:v copy -c:a aac -strict experimental " + outputAudioVideoPath;
    runCommand(command);  
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


boolean loadVideo() {
   
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
        return true;
    }
    else{
      println("Data folder has no mp4 format videos ");
      return false;
    }
}

void loadSound() {
   
    java.io.File folder = new java.io.File(dataPath(""));             
    java.io.FilenameFilter audioFilter = new java.io.FilenameFilter() {  
      public boolean accept(File dir, String name) {
        return (name.toLowerCase().endsWith(".aif") ||
                name.toLowerCase().endsWith(".aiff") ||
                name.toLowerCase().endsWith(".mp3"));
      }
    };
  
    String[] filenames = folder.list(audioFilter);
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

void runInsertImageCommand( String imagePath, float startTime, float endTime) {
    
     String outputVideoPath = "data/output/output" + excerptNumber + ".mp4";
     String inputVideoPath = "data/output/output" + (excerptNumber-1) + ".mp4";
     if(excerptNumber==0){
        inputVideoPath = "data/output/output.mp4" ;
     }
 
     //outputVideoPath = "data/output/output.mp4";
     //inputVideoPath = outputVideoPath;
     
     String ffmpegCommand = "/usr/local/bin/ffmpeg -y -i " + inputVideoPath +
        " -i " + imagePath + " -filter_complex " + 
        "\"[0:v][1:v] overlay=0:0:enable=\'between(t,"+ startTime + "," + endTime + ")\'\"" + 
        " " + outputVideoPath;
       
       PrintWriter outputScript = createWriter("data/scripts/insertImageScript.sh");
       String creatingExcerptText = "Creating excerpt, start->  " + startTime + "s, end-> " + endTime;
       //println(creatingExcerptText);
       
       String command = "cd " + sketchPath("");
       outputScript.println(command);
       outputScript.println(ffmpegCommand); 
       outputScript.flush(); // Writes the remaining data to the file
       outputScript.close(); // Finishes the file
       
       command = "rm " + inputVideoPath;
       runCommand("sh data/scripts/insertImageScript.sh");
       runCommand(command);    
}

void createBlankVideo()
{
    PImage img = createImage(myMovie.width, myMovie.height, RGB);
    String imageName = "data/images/blackImage.jpg";
    String videoName = "data/output/output.mp4";
    
    img.loadPixels();
    for (int i = 0; i < img.pixels.length; i++) {
      img.pixels[i] = color(0, 0, 0); 
    }
    img.updatePixels();
    img.save(imageName);
    
    runCommand("mkdir " + dataPath("") + "/output");
    runCommand("echo create blank video ...");  // Add sound to videos
    
    String ffmpegCommand = "/usr/local/bin/ffmpeg -loop 1 -f image2 -i " + imageName + " -c:v libx264 -pix_fmt yuv420p" +
     " -r " + fps + " -t " + myMovie.duration() + " " + videoName + " -y";
    
    runCommand(ffmpegCommand);  // create a blank video
}


void runCommand(String commandToRun) {
      runCommand(commandToRun,sketchPath(""));
}

void runCommand(String commandToRun, String path) {
  
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

public void controlEvent(ControlEvent theEvent) {
  switch(theEvent.controller().id()) {
    case(1):  // number of steps
      numberOfSteps = (int)(theEvent.controller().value());
      String textInfo = "Number of steps: " + numberOfSteps + "\n\n" +
                      "Duration of each step: " + durationOfEachStep + "s";
      textlabelInfo.setValueLabel(textInfo);             
      break;  
    
    case(2):  // Duration of each step
      durationOfEachStep = (float)(theEvent.controller().value()) / 10.00;
      String textInfo2 = "Number of steps: " + numberOfSteps + "\n\n" +
                      "Duration of each step: " + durationOfEachStep + "s";
      textlabelInfo.setValueLabel(textInfo2);
      break;  
  }
}


public void buttonStart(int theValue) {
  startRendering();
}
