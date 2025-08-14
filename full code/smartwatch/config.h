#ifndef CONFIG_H
#define CONFIG_H

#include <Arduino.h>

// OLED Configuration
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
#define SCREEN_ADDRESS 0x3C

// I2C Pins
#define I2C_SDA_PIN 21
#define I2C_SCL_PIN 22

// Vibration Configuration
#define VIBRATION_PIN 18
const unsigned long VIBRATION_DURATION = 10000;
const unsigned long VIBRATE_ON_TIME = 2000;
const unsigned long VIBRATE_OFF_TIME = 2000;

// Emergency Button Configuration
#define EMERGENCY_BUTTON_PIN 4
const unsigned long DEBOUNCE_DELAY = 250;
const String DEVICE_ID = "WATCH001";

// MQTT Configuration
extern const char* MQTT_SERVER;
extern const int MQTT_PORT;
extern const char* MQTT_USERNAME;
extern const char* MQTT_PASSWORD;
extern const char* MQTT_TOPIC_MESSAGE;
extern const char* MQTT_TOPIC_POSITION;
extern const char* MQTT_TOPIC_EMERGENCY;
extern const char* MQTT_TOPIC_DEVICEID;

// Trilateration Configuration
struct AP {
  const char* ssid;
  float x, y;
};

extern AP accessPoints[3];

// Display Control
const unsigned long MESSAGE_DISPLAY_DURATION = 5000; // 5 seconds
const unsigned long CLOCK_UPDATE_INTERVAL = 1000; // 1 second

#endif