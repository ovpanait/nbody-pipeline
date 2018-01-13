#include <SoftwareSerial.h>

SoftwareSerial mySerial(10, 11); // RX, TX

void setup() {
  Serial.begin(9600);

  // set the data rate for the SoftwareSerial port
  mySerial.begin(9600);
}

uint8_t data_pc, data_fpga;
uint8_t ind = 0;

uint8_t rxa[8] = { 0x40, 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
uint8_t rxb[8] = { 0x40, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
uint8_t rya[8] = { 0x40, 0x88, 0x88, 0x00, 0x00, 0x00, 0x00, 0x00 };
uint8_t ryb[8] = { 0x40, 0x7B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };

void loop() {
  // put your main code here, to run repeatedly:

 //for (unsigned char j = 0; j < 16; ++j)
   // Serial.print(j);
 if(Serial.available()) {
    
    data_pc = Serial.read();
    switch(data_pc) {
      case '1':
        mySerial.write(rxa, 8);
        break;
      case '2':
        mySerial.write(rxb, 8);
        break;
      case '3':
        mySerial.write(rya, 8);
        break;
      case '4':
        mySerial.write(ryb, 8);
        break;
    }

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
