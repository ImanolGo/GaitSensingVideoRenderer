

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

import processing.video.*;
Movie myMovie;
int lastFrame = 0;
int fps = 5;
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
  saveFramesToImages();
 
  //noLoop(); // only draw once
}

void draw() {
  
  //background(255);
  
  image(myMovie, 0, 0);
}

void startBashScript(){
  // Create a new file in the sketch directory
    createVideoScript = createWriter("createVideo.sh"); 
    createVideoScript.println("#!/bin/bash");  // Start the Bourne shell
    createVideoScript.print("\n");  // break code
    createVideoScript.println("echo Starting video creation script...");  // Echo starting script
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
        createScriptBlankVideo();
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

void saveFramesToImages() {
  
  println("Save frames to images... ");
  
  createVideoScript.print("\n");  // break code
  createVideoScript.println("echo Creating images from frames ...");  // Echo images from frames 
  createVideoScript.println("cd " + dataPath(""));  // create output folder
  createVideoScript.println("mkdir images");
  
  //for(int i=0; i<Steps.size();i++)
  for(int i=0; i<10;i++)
  { 
    Step step =(Step) Steps.get(i); 
    float nextFrame = step.m_fTime;
    String imageName = "images/p_steps_"+ nextFrame +".jpg";
    String ffmpegCommand = "ffmpeg -i " + InputVideoName + 
    " -ss " + timeToFormatted((int) (nextFrame*1000)) + 
    " -f image2 -vframes 1 " + imageName;
   
    createVideoScript.println(ffmpegCommand);  // create image from frame
    //PImage newImage = (PImage) myMovie;
    //newImage.save("data/images/p_steps_"+ nextFrame +".jpg");
    println("Step = " + step.m_sNote + ", time = " + nextFrame);
    
    if(i +1 < Steps.size()){
      Step nextStep =(Step) Steps.get(i+1); 
    }
    
    //saveFile(i++,newImage);
  }
  
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
// export filenames w/leading zeros
void saveFile(int i, PImage image) {
  String istr = i+"";
  if (i < 10) { istr = "00000" + i; }
  else if (i < 100) { istr = "0000" + i; }
  else if (i < 1000) { istr = "000" + i; }
  else if (i < 10000) { istr = "00" + i; }
  else if (i < 100000) { istr = "0" + i; }
  
  image.save("p_steps_"+ istr +".jpg");
  //save("p_"+ istr +".jpg");
}

// Called every time a new frame is available to read
void movieEvent(Movie m) {
  m.read();
}

void stop() { //it is called whenever a sketch is closed. 
   createVideoScript.flush(); // Writes the remaining data to the file
   createVideoScript.close(); // Finishes the file
   println("App stopped");
} 

void keyPressed() {
  if (key == ESC) {
    createVideoScript.flush(); // Writes the remaining data to the file
    createVideoScript.close(); // Finishes the file
    println("App exit");
    exit(); // Stops the program
  }
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
