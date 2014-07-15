

/**
  * MIDI Video Renderer
  * 
  * by Imanol Gómez 
  *    www.imanolgomez.net
  * 
  * 
*/

import arb.soundcipher.*;

import javax.sound.midi.Sequencer;
import javax.sound.midi.MidiDevice;
import javax.sound.midi.MidiSystem;
import javax.sound.midi.MidiEvent;
import javax.sound.midi.MidiMessage;
import javax.sound.midi.MidiUnavailableException;
import javax.sound.midi.InvalidMidiDataException;
import java.io.IOException;
import javax.sound.midi.Sequence;
import javax.sound.midi.Track;
import javax.sound.midi.ShortMessage;

import javax.swing.*; 
import javax.swing.filechooser.FileNameExtensionFilter;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;



import processing.video.*;
Movie myMovie;
int lastFrame = 0;
int fps = 10;

ArrayList Notes_;
ArrayList Steps;
float MidiDuration;
PFont fontA;
float tempo = 60;
int spm = 60; //seconds per minute
ArrayList m_Durations = new ArrayList();
ArrayList lines = new ArrayList();
String absolutePath;
String fileName;

//name of the file

class Step
{
  float m_fTime;
  String m_sNote;
  float m_fDuration;
}


void setup() {
  size(1920, 1080);
  frameRate(fps);
  
  loadMidiInfo();
  loadVideo();
  renderImages();
  
  noLoop(); // only draw once
}

void draw() {
  
  background(255);
  
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

void loadMidiInfo() {
    println("Load Info");
    loadNotes();
    loadSteps();
}

void loadVideo() {
   
    Notes_ = new ArrayList();  // Create an empty ArrayList
    String videoName = "video.MP4"; 
    String path = dataPath("") + "/" + videoName;
    
    println(path); 
    myMovie = new Movie(this, path);
    myMovie.play();
    
    println("Video Duration: "+ myMovie.duration() + "s");
}


void loadNotes() {
   
    Notes_ = new ArrayList();  // Create an empty ArrayList
    String midiFileName = "steps.mid"; 
    String path = dataPath("") + "/" + midiFileName;
    
    println(path); 
    
    if (midiFileName.endsWith("mid")) { 
      Notes_ = loadMidi(path ,tempo);
      MidiDuration = getMidiDuration(path);
      println("MidiDuration: "+ MidiDuration + "s");
    } else { 
      // just print the contents to the console 
      println("Not opened a midi file."); 
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
    newImage.save("p_steps_"+ nextFrame +".jpg");
    println("Step = " + step.m_sNote + ", time = " + nextFrame);
    
    //saveFile(i++,newImage);
  }
  
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

