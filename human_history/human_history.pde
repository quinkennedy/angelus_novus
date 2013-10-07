import processing.pdf.*;

float marginInches = .25;
float inchWidth = 8.26 - marginInches*2;
float inchHeight = 11.69 - marginInches*2;
int pdfPPI = 300;
int textSize = pdfPPI/6;
int[] shuffledPixels;
int filledIndex = 0;
int numPixels;
int year = -750;
int numOverlap = 4;
int totalSteps;
KeyFrame[] keyFrames = new KeyFrame[]{
  new KeyFrame(-750, 0.0),
  new KeyFrame(-400, 0.0),
  new KeyFrame(-49, 0.3),
  new KeyFrame(-48, 0.15),  /* First burning of the Library of Alexandria. */
  new KeyFrame(405, 0.4),
  new KeyFrame(406, 0.35),   /* Crossing of the Rhine; beginning of end of Rome. */
  new KeyFrame(1000, 0.15),
  new KeyFrame(1142, 0.2),  /* Death of Abelard; early medieval renaissance. */
  new KeyFrame(1400, 0.3),  /* Death of Chaucer; Italian renaissance heating up. */
  new KeyFrame(1500, 0.5),
  new KeyFrame(1727, 0.55),   /* Death of Newton. */
  new KeyFrame(1947, 0.75),   /* ENIAC turned on; first modern computer. */
  new KeyFrame(2006, 1),   /* Commercial hard drive space falls below $1 per gigabyte. */
  new KeyFrame(3000, 1)
};
int currKeyFrame = 0;
int[] overlapStep;
PGraphics data;
boolean rotate = true;
int startYear = -1000;
int calcFilled = 0;

class KeyFrame {
  public int year;
  public float fill;
  public KeyFrame(int year, float fill){
    this.year = year;
    this.fill = fill;
  }
}

int textX, textY;
int textPixels;
boolean shuffledText = false;
int textPixelsShufflePoint;
boolean done = false;
int actualWidth, actualHeight;
PGraphicsPDF pdf;

void setup(){
  actualWidth = (int)(inchWidth * pdfPPI);
  actualHeight = (int)(inchHeight * pdfPPI);
  size(10, 10);
  data = createGraphics(actualWidth, actualHeight);
  data.beginDraw();
  data.background(255, 255, 255, 255);
  data.endDraw();
  pdf = createPDF();
  textX = actualWidth - (int)pdf.textWidth(" BCE") - (int)pdf.textDescent();
  textY = actualHeight - (int)pdf.textDescent();
  numPixels = actualWidth * actualHeight;
  totalSteps = numPixels * numOverlap;
  overlapStep = new int[numOverlap + 1];
  for(int i = 0; i <= numOverlap; i++){
    int max = 255;
    int curr = (int)(max*(float(i)/numOverlap));
    overlapStep[i] = (255 << 24) | (curr << 16) | (curr << 8) | (curr);
  }
  println(actualWidth + " x " + actualHeight);
  
  shuffledPixels = new int[totalSteps];
  int counter = 0;
  for(int i = (rotate ? numPixels - 1 : 0); counter < totalSteps; i = (rotate ? i-1 : i+1)){
    for(int j = 0; j < numOverlap; j++, counter++){    
      shuffledPixels[counter] = i;
    }
  }
  //shuffle upper section
  textPixels = ceil(pdf.textAscent()+pdf.textDescent())*actualWidth;
  textPixelsShufflePoint = totalSteps - textPixels * numOverlap * 10;
  shuffle(shuffledPixels, 0, totalSteps - textPixels * numOverlap);
  //pg.dispose();
}

PGraphics getPage(){
  pdf.nextPage();
  return pdf;
}

PGraphicsPDF createPDF(){
  PGraphicsPDF pg = (PGraphicsPDF)createGraphics(actualWidth, actualHeight, PDF, "oneFile/"+year+".pdf");
  pg.beginDraw();
  pg.textSize(textSize);
  pg.fill(0);
  return pg;
}

void draw(){
  try{
    if (done){
      pdf.dispose();
      exit();
      return;
    } 
    
    data.loadPixels();
    int numFilledLastFrame = getNumFilled(year-1);
    if (calcFilled != numFilledLastFrame){
      println("year: " + year);
      println("numFilledLastFrame: " + numFilledLastFrame);
      println("totalStep: " + totalSteps);
      println("pixels: " + numPixels);
      println("filledIndex: " + filledIndex);
      println("textPixelsShufflePoint: " + textPixelsShufflePoint);
      println("calcFilled: " + calcFilled);
      exit();
      return;
    }
    int numFilledCurrFrame = getNumFilled(year);
    int numFilledDiff = numFilledCurrFrame - numFilledLastFrame;
    calcFilled += numFilledDiff;
    if (year%10 == 0){
      println(year+ ": "+numFilledCurrFrame + " in " + millis());
    }
    while (numFilledDiff > 0){
      //add black
      try{
        int i = 0;
        for(; i <= numOverlap; i++){
          if (data.pixels[shuffledPixels[filledIndex]] == overlapStep[i]){
            data.pixels[shuffledPixels[filledIndex]] = overlapStep[i-1];
            break;
          }
        }
        if (i > numOverlap){
          println("ERROR! SHOULDN'T REACH HERE!");
        }
      } catch (ArrayIndexOutOfBoundsException aioobe){
        println("year: " + year);
        println("numFilledCurrFrame: " + numFilledCurrFrame);
        println("numFilledDiff: " + numFilledDiff);
        println("totalStep: " + totalSteps);
        println("pixels: " + numPixels);
        println("filledIndex: " + filledIndex);
        println("textPixelsShufflePoint: " + textPixelsShufflePoint);
        println("calcFilled: " + calcFilled);
        throw(aioobe);
      }
      //shuffle the pixel back
      shuffleOnce(shuffledPixels, filledIndex, filledIndex, -1);
      filledIndex++;
      numFilledDiff--;
    }
    while (numFilledDiff < 0){
      //add white
      filledIndex--;
      for(int i = 0; i <= numOverlap; i++){
        if (data.pixels[shuffledPixels[filledIndex]] == overlapStep[i]){
          data.pixels[shuffledPixels[filledIndex]] = overlapStep[i+1];
          break;
        }
      }
      shuffleOnce(shuffledPixels, filledIndex, totalSteps - filledIndex - textPixels * numOverlap, 1);
      numFilledDiff++;
    }
    if (!shuffledText && numFilledCurrFrame >= textPixelsShufflePoint){
      shuffle(shuffledPixels, numFilledCurrFrame, totalSteps - numFilledCurrFrame);
      shuffledText = true;
    }
    data.updatePixels();
    if (year >= startYear){
      PGraphics pg = getPage();
      pg.beginDraw();
      pg.image(data, 0, 0);
      if (rotate){
        pg.rotate(PI);
      }
      pg.text((year < 0 ? " BCE" : year == 0 ? "" : " CE")
        , (rotate ? 0 : actualWidth) - (pg.textWidth(" BCE") + pg.textDescent())
        , (rotate ? 0 : actualHeight) - pg.textDescent());
      pg.text(year
        , (rotate ? 0 : actualWidth) - (pg.textWidth(" BCE") + pg.textDescent() + pg.textWidth(""+year))
        , (rotate ? 0 : actualHeight) - pg.textDescent());
      //pg.dispose();
      pg.endDraw();
    }
    year++;
  } catch (Exception e){
    println("EXCEPTION!");
    println(e.getMessage());
  }
}

int getNumFilled(int currYear){
  try{
    if (keyFrames[currKeyFrame].year < currYear){
      currKeyFrame++;
    }
  
    KeyFrame currKF = keyFrames[currKeyFrame];
    KeyFrame lastKF = (currKeyFrame == 0 ? new KeyFrame(currYear - 1, 0) : keyFrames[currKeyFrame - 1]);
    float progress = ((float)(currYear - lastKF.year))/(currKF.year - lastKF.year);
    return (int)(pow(((currKF.fill - lastKF.fill)*progress + lastKF.fill),3)*totalSteps);
  } catch(IndexOutOfBoundsException ioobe){
    //assumen 1.0 fill after end of keyframes
    done = true;
    println("DONE");
    return totalSteps;
  }
}

void shuffle(int[] arr, int start, int length){
  int remaining = abs(length);
  int direction = (length > 0 ? 1 : -1);
  for(int i = 0; i != length - direction; i += direction, remaining--){
    shuffleOnce(arr, i+start, remaining, direction);
  }
}

void shuffleOnce(int[] arr, int toMove, int remaining, int direction){
  int switchWith = (int)(Math.random()*remaining);
  int destination = toMove + (direction * switchWith);
  int temp = arr[toMove];
  arr[toMove] = arr[destination];
  arr[destination] = temp;
}
