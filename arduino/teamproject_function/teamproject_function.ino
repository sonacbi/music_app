#include <LiquidCrystal_I2C.h>
#include <SoftwareSerial.h>
#include <avr/pgmspace.h>

//하드웨어 정의
LiquidCrystal_I2C lcd(0x27, 16, 2);
const int buzzerPin = 8;
SoftwareSerial BT(10, 11);

//음정(Pitch) 정의
#define C4 262
#define CS4 277
#define D4 294
#define DS4 311
#define E4 330
#define F4 349
#define FS4 370
#define G4 392
#define GS4 415
#define A4 440
#define AS4 466
#define B4 494

#define C5 523
#define D5 587
#define E5 659
#define F5 698
#define FS5 740
#define G5 784
#define A5 880
#define B5 988

//박자(Duration) 정의
int currentTempo = 120;
int defaultLength = 4;
int currentOctave = 4;

int mmlIndex = 0;
unsigned long noteStart = 0;
unsigned long noteDuration = 0;
bool notePlaying = false;

struct Note {
  int pitch;
  int duration;
};

//악보 데이터
// const Note schoolBell[] PROGMEM = {
//   { G4, QUARTER }, { E4, QUARTER }, { E4, HALF }, { F4, QUARTER }, { D4, QUARTER }, { D4, HALF }, { C4, QUARTER }, { D4, QUARTER }, { E4, QUARTER }, { F4, QUARTER }, { G4, QUARTER }, { G4, QUARTER }, { G4, HALF }, { G4, QUARTER }, { E4, QUARTER }, { E4, HALF }, { F4, QUARTER }, { D4, QUARTER }, { D4, HALF }, { C4, QUARTER }, { E4, QUARTER }, { G4, QUARTER }, { G4, QUARTER }, { C5, HALF }
// };

// const Note happyBirthday[] PROGMEM = {
//   { C4, EIGHTH }, { C4, EIGHTH }, { D4, QUARTER }, { C4, QUARTER }, { F4, QUARTER }, { E4, HALF }, { C4, EIGHTH }, { C4, EIGHTH }, { D4, QUARTER }, { C4, QUARTER }, { G4, QUARTER }, { F4, HALF }, { C4, EIGHTH }, { C4, EIGHTH }, { C5, QUARTER }, { A4, QUARTER }, { F4, QUARTER }, { E4, QUARTER }, { D4, HALF }, { A4, EIGHTH }, { A4, EIGHTH }, { A4, QUARTER }, { F4, QUARTER }, { G4, QUARTER }, { F4, HALF }
// };

// const Note jingleBell[] PROGMEM = {
//   { E4, QUARTER }, { E4, QUARTER }, { E4, HALF }, { E4, QUARTER }, { E4, QUARTER }, { E4, HALF }, { E4, QUARTER }, { G4, QUARTER }, { C4, QUARTER }, { D4, QUARTER }, { E4, HALF }, { F4, QUARTER }, { F4, QUARTER }, { F4, QUARTER }, { F4, QUARTER }, { F4, QUARTER }, { E4, QUARTER }, { E4, QUARTER }, { E4, QUARTER }, { D4, QUARTER }, { D4, QUARTER }, { E4, QUARTER }, { D4, HALF }, { G4, HALF }
// };

// const Note jungle[] PROGMEM = {
//   { C4, QUARTER }, { E4, QUARTER }, { G4, QUARTER }, { E4, QUARTER }, { C4, QUARTER }, { E4, QUARTER }, { G4, HALF }, { A4, QUARTER }, { G4, QUARTER }, { E4, QUARTER }, { C4, QUARTER }, { D4, QUARTER }, { E4, HALF }, { G4, QUARTER }, { A4, QUARTER }, { G4, QUARTER }, { E4, QUARTER }, { C4, HALF }
// };
const int SONG_COUNT = 5; // 곡 갯수
const char schoolBell[] PROGMEM =
"T150L8GED2FDD2CDEFGG2GED2FDD2CEGGC2";

const char happyBirthday[] PROGMEM =
"T140L16CCD4CFFE2CCD4CGF2CCC4AFED2AAAFGF2";

const char jingleBell[] PROGMEM =
"T210L8EEE2EEE2EGCDE2FFFFFEEEDDED2G2";

const char jungle[] PROGMEM =
"T150L8CEGECEG2AGECDE2GAGEC2";

const char adreaminn[] PROGMEM =
"T117L8ABCEG2ABCEG2FG+CEG2FG+CEG2EGBCE2EGBCE2EGBCE2EGBCE2";
// "T97L16DR8DR8DR8DRE8DDR8DDR8DDR8DDB8DDR8DDR8DDR8DDB8DDR8DDR8DDR8DDB8DDA8DDB8DDA8DDD8DDA8DDB8DDA8DDA8DDA8DDB8DDA8DDD8DDA8DDA8DDB8DC8D4D4B8GBFAFADADADADADADADADAEBEBEBEBEBEBABGADADADADADADADADADAEBEBEBEBEBEBEBEBDFDFDDCCDEDEDCCDFDFDDCCDADADDCCA4D4B4D4RFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFEBEBDEEBDEFCDEEBEBEDEEBEBEBEBDADADADADABDREBEBEBEBEBECERERDGDGDGDGDGDGDGDGDGDADADADADADADADADABADADDDADADDDADADDDADADDDADADDDADADDCBAG";
//곡 이름 및 곡 길이 정의
const char* const songs[] PROGMEM = {
  schoolBell,
  happyBirthday,
  jingleBell,
  jungle,
  adreaminn
};
const char* songNames[] = {
  "School Bell",
  "Happy Birthday",
  "Jingle Bell",
  "Jungle Song",
  "a dream inn"
};
// const int songLengths[] = {
//   sizeof(schoolBell) / sizeof(Note),
//   sizeof(happyBirthday) / sizeof(Note),
//   sizeof(jingleBell) / sizeof(Note),
//   sizeof(jungle) / sizeof(Note)
// };
int songTotalSeconds[SONG_COUNT];
// char currentSongBuffer[300];

//mp3 플레이어 상태
enum PlayerState { STOPPED,
                   PLAYING,
                   PAUSED };
PlayerState currentState = STOPPED;
PlayerState lastState = STOPPED;

int SongNumber = 0;
int lastSongNumber = -1;
// int NoteIndex = 0; // 삭제

//타이머 변수
unsigned long previousMillis = 0;
unsigned long totalPlayTime = 0;
unsigned long startTime = 0;
unsigned long lastSeconds = 999;  //LCD화면의 불필요한 깜빡임을 방지하기 위한 변수

void calculateMMLTotalTime() {

  for(int s=0;s<SONG_COUNT;s++){

      char buffer[400];

      strcpy_P(buffer,(char*)pgm_read_word(&songs[s]));

      int i=0;
      int tempo=120;
      int defaultLen=4;
      unsigned long totalMs=0;

      while(buffer[i]!='\0'){

          char c=buffer[i++];

          if(c=='T'){

              int num=0;

              while(isDigit(buffer[i])){
                  num=num*10+(buffer[i]-'0');
                  i++;
              }

              tempo=num;
          }

          else if(c=='L'){

              int num=0;

              while(isDigit(buffer[i])){
                  num=num*10+(buffer[i]-'0');
                  i++;
              }

              defaultLen=num;
          }

          else if(strchr("CDEFGABR",c)){

    // 샵 건너뛰기
    if(buffer[i]=='+'){
        i++;
    }

    int len=0;

    while(isDigit(buffer[i])){
        len=len*10+(buffer[i]-'0');
        i++;
    }

    if(len==0) len=defaultLen;

    int quarter=60000/tempo;

    totalMs += quarter*4/len;
}
      }

      songTotalSeconds[s]=totalMs/1000;
  }
}

//초기 설정
void setup() {
  pinMode(buzzerPin, OUTPUT);
  Serial.begin(9600);  // 시리얼 통신
  BT.begin(9600);      // HC-05/HC-06 Bluetooth

  // calculateTotalTimes();
  calculateMMLTotalTime();
  loadSong();

  lcd.init();
  lcd.backlight();
  lcd.clear();
  Serial.println("--- Arduino Music Player ---");
  Serial.println("명령어 목록을 보고 싶으면 help를 입력해주세요.");
}

void loop() {
  showLCD();
  // ===== pc serial monitor =====
  if (Serial.available() > 0) {

    // String command = Serial.readStringUntil('\n'); // 동적메모리 방식. 변경
    char command[20];
    int len = Serial.readBytesUntil('\n', command, sizeof(command) - 1);

    // command.trim(); // 동적메모리 방식. 변경
    command[len] = '\0';
    handleCommand(command);
  }

  // ===== Bluetooth raw byte =====
  if (BT.available() > 0) {

      byte cmd = BT.read();

      Serial.print("BT RAW: ");
      Serial.println(cmd);

      handleBluetooth(cmd);
  }

  if (currentState == PLAYING) {
    updatePlayer();
  }
}

void handleCommand(char* command) {  // 포인터 방식으로 변경

  if (strcmp(command, "help") == 0) {
    helpinstruction();
  }

  if (strcmp(command, "play") == 0) {
    playMusic();
  }

  else if (strcmp(command, "pause") == 0) {
    pauseMusic();
  }

  else if (strcmp(command, "reset") == 0) {
    resetMusic();
  }

  else if (strcmp(command, "next") == 0) {
    nextMusic();
  }

  else if (strcmp(command, "prev") == 0) {
    prevMusic();
  }

  else {
    Serial.println("Invalid Command");
  }
}

void handleBluetooth(byte cmd){

    switch(cmd){

        case 1:
            playMusic();
            break;

        case 2:
            pauseMusic();
            break;

        case 3:
            resetMusic();
            break;

        case 10:          // Arrow Left
            prevMusic();
            break;

        case 11:          // Arrow Right
            nextMusic();
            break;

        default:
            Serial.print("Unknown BT cmd = ");
            Serial.println(cmd);
            break;
    }
}

int getPitch(char note, bool sharp)
{
  switch(note){

    case 'C': return sharp ? CS4 : C4;
    case 'D': return sharp ? DS4 : D4;
    case 'E': return E4;
    case 'F': return sharp ? FS4 : F4;
    case 'G': return sharp ? GS4 : G4;
    case 'A': return sharp ? AS4 : A4;
    case 'B': return B4;
  }

  return 0;
}

int getDuration(int length){

   int quarter = 60000/currentTempo;

   return quarter*4/length;
}

// int readNumber(const char* song){

//     int value = 0;

//     while(isDigit(song[mmlIndex])){

//         value = value*10 + (song[mmlIndex]-'0');

//         mmlIndex++;
//     }

//     return value;
// }

int readNumber(){

    const char* songPtr =
        (const char*)pgm_read_word(&songs[SongNumber]);

    int value = 0;

    while(isDigit(pgm_read_byte(songPtr + mmlIndex))){

        value = value*10 +
               (pgm_read_byte(songPtr + mmlIndex)-'0');

        mmlIndex++;
    }

    return value;
}

// void calculateTotalTimes() {  //음악 총 시간을 계산하는 함수
//   for (int i = 0; i < 4; i++) {
//     unsigned long totalMs = 0;
//     for (int j = 0; j < songLengths[i]; j++) {
//       // totalMs += songs[i][j].duration; // 이전 방식.
//       Note temp;
//       memcpy_P(&temp, &songs[i][j], sizeof(Note));

//       totalMs += temp.duration;
//     }
//     songTotalSeconds[i] = totalMs / 1000;
//   }
// }
//mp3상태 초기화 함수(음악을 멈추고 0초로 바꾸는 함수)
void initSong(){
  loadSong();
  noTone(buzzerPin);
  mmlIndex=0;
  currentTempo=120;
  defaultLength=4;
  notePlaying=false;
  totalPlayTime=0;
}

void playMusic() {  //음악을 재생하는 함수
  if (currentState != PLAYING) {
    currentState = PLAYING;
    startTime = millis();
    previousMillis = millis();
    Serial.println("음악을 재생합니다.");
  }
}

void pauseMusic() {  //음악을 일시정지하는 함수
  if (currentState == PLAYING) {
    currentState = PAUSED;
    totalPlayTime += (millis() - startTime);
    noTone(buzzerPin);
    Serial.println("음악을 일시중지합니다.");
  }
}

void resetMusic() {  //음악을 0초로 리셋하는 함수
  initSong();
  currentState = STOPPED;
  Serial.println("음악을 처음으로 리셋합니다.");
}

void prevMusic() {

  SongNumber--;

  if (SongNumber < 0) {
    SongNumber = SONG_COUNT-1;
  }

  initSong();

  Serial.println("이전 곡을 재생합니다.");

  Serial.print(SongNumber + 1);
  Serial.print(". ");

  Serial.println(songNames[SongNumber]);

  currentState = PLAYING;

  startTime = millis();

  previousMillis = millis();
}

void nextMusic() {  //다음 곡을 실행하는 함수
  
  SongNumber = (SongNumber + 1) % SONG_COUNT;
  initSong();

  Serial.println("다음 곡을 재생합니다.");
  Serial.print(SongNumber + 1);
  Serial.print(". ");
  Serial.println(songNames[SongNumber]);

  currentState = PLAYING;
  startTime = millis();
  previousMillis = millis();
}

void helpinstruction() {  //도움말을 표시해주는 함수
  Serial.println("\n--- 명령어 가이드 ---");
  Serial.println("play   : 음악 재생");
  Serial.println("pause  : 음악 일시중지");
  Serial.println("reset  : 현재 곡 정지 및 처음으로");
  Serial.println("prev   : 이전 곡으로 변경 및 재생");
  Serial.println("next   : 다음 곡으로 변경 및 재생");
  Serial.println("--------------------");
}
//mp3 음악 플레이어를 업데이트하는 함수
void updatePlayer(){

  // char c = /currentSongBuffer[mmlIndex];
const char* songPtr =
    (const char*)pgm_read_word(&songs[SongNumber]);

char c = pgm_read_byte(songPtr + mmlIndex);

  if(notePlaying){

      if(millis()-noteStart < noteDuration){
          return;
      }

      noTone(buzzerPin);

      notePlaying=false;
  }

  if(c=='\0'){

      resetMusic();

      return;
  }

  mmlIndex++;


  // Tempo

  if(c=='T'){

      currentTempo = readNumber();
      return;
  }


  // Default Length

  if(c=='L'){

      defaultLength = readNumber();
      return;
  }


  // Rest

  if(c=='R'){

      int len = readNumber();

      if(len==0) len=defaultLength;

      noteDuration=getDuration(len);

      noteStart=millis();

      notePlaying=true;

      return;
  }


  // Note

if(strchr("CDEFGAB",c)){

      bool sharp = false;

      // 다음 문자 확인
      char nextChar = pgm_read_byte(songPtr + mmlIndex);

      if(nextChar == '+'){
          sharp = true;
          mmlIndex++;     // + 건너뛰기
      }

      int pitch = getPitch(c, sharp);

      int len = readNumber();

      if(len==0) len=defaultLength;

      noteDuration = getDuration(len);

      tone(buzzerPin,pitch);

      noteStart = millis();

      notePlaying = true;

      return;
}
}

void loadSong(){
    mmlIndex = 0;
}

//LCD출력 함수(출력 형태는 1열:곡 이름, 2열: 현재상태+현재 재생시간/총 재생시간)
void showLCD() {

  unsigned long currentElapsed = totalPlayTime;

  if(currentState == PLAYING){
      currentElapsed += (millis() - startTime);
  }

  unsigned long totalSeconds = currentElapsed / 1000;

  if(totalSeconds != lastSeconds ||
     currentState != lastState ||
     SongNumber != lastSongNumber){

      lcd.clear();

      lcd.setCursor(0,0);
      lcd.print(songNames[SongNumber]);

      lcd.setCursor(0,1);

      if(currentState == PLAYING)
          lcd.print("> ");

      else if(currentState == PAUSED)
          lcd.print("|| ");

      else
          lcd.print("[] ");

      unsigned long minutes = totalSeconds / 60;
      unsigned long seconds = totalSeconds % 60;

      if(minutes < 10) lcd.print("0");
      lcd.print(minutes);

      lcd.print(":");

      if(seconds < 10) lcd.print("0");
      lcd.print(seconds);
      lcd.print("/");

      // 총 재생시간
      unsigned long totalSongSec = songTotalSeconds[SongNumber];

      unsigned long totalMinutes = totalSongSec / 60;
      unsigned long totalRemain = totalSongSec % 60;

      if(totalMinutes < 10) lcd.print("0");
      lcd.print(totalMinutes);

      lcd.print(":");

      if(totalRemain < 10) lcd.print("0");
      lcd.print(totalRemain);

      lastSeconds = totalSeconds;
      lastState = currentState;
      lastSongNumber = SongNumber;
  }
}