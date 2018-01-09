#include <SoftwareSerial.h>

SoftwareSerial mySerial(10, 11); // RX, TX

void setup() {
  Serial.begin(9600);

  // set the data rate for the SoftwareSerial port
  mySerial.begin(9600);
}

uint8_t data_pc, data_fpga;
uint8_t ind = 0;

void loop() {
  // put your main code here, to run repeatedly:

 //for (unsigned char j = 0; j < 16; ++j)
   // Serial.print(j);
 if(Serial.available()) {
    
    data_pc = Serial.read();

    mySerial.print(0x00);


  }

  if (mySerial.available()) {
    
      data_fpga = mySerial.read();
      
      Serial.print(data_fpga, HEX);
      if (ind == 7) {
        ind = 0; 
        Serial.print("\n");
      }
      else ind++;
}
}
