

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
  
  //renderImages();
  
  //noLoop(); // only draw once
}

void draw() {
  
  //background(255);
  
  image(myMovie, 0, 0);
  
//  int m = millis();
//  if(m-lastFrame>2000)
//  {
//    if (myMovie.available()) {
//      int nextFrame = m/1000;
//      myMovie.jump(nextFrame);
//      myMovie.read();
//    }
//    image(myMovie, 0, 0);
//    
//    lastFrame = m;  
//  }
  
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
        String videoName = filenames[0];
        String path = dataPath("") + "/" + videoName;
        println("Loading " + videoName + "....");
        myMovie = new Movie(this, path);   
        myMovie.play();
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

void renderImages() {
  
  for(int i=0; i<Steps.size();i++)
  {
    while (!myMovie.available()) {
    }
    Step step =(Step) Steps.get(i); 
    float nextFrame = step.m_fTime;
    myMovie.jump(nextFrame);
    myMovie.read();
    PImage newImage = (PImage) myMovie;
    newImage.save("data/images/p_steps_"+ nextFrame +".jpg");
    println("Step = " + step.m_sNote + ", time = " + nextFrame);
    
    if(i +1 < Steps.size()){
      Step nextStep =(Step) Steps.get(i+1); 
    }
    
    //saveFile(i++,newImage);
  }
  
}

void createScriptBlankVideo()
{
   String path = dataPath("") + "/blankVideo.mp4" ; 
   
   //String ffmpegCommand = "ffmpeg -t 10 -s 640x480 -f lavfi -pix_fmt rgb24 -r 25 -i " + path;
   String ffmpegCommand = "ffmpeg -t 10 -s 640x480 -f rawvideo -pix_fmt rgb24 -r 25 -i /dev/zero " + path;
   
   createVideoScript.print("\n");  // break code
   createVideoScript.println("echo Creating blank video...");  // Echo creating blank video
   createVideoScript.print("\n");  // break code 
   createVideoScript.println(ffmpegCommand);  //  creating blank video 
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
