
#include <Arduino.h>

void setup() {
    Serial.begin(9600); //Set Baudrate with "New Processor"
}

void loop() {
    Serial.println("Hello World");
    delay(1000);
}
