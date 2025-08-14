#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <WiFiManager.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <WiFi.h>
#include <WiFiUdp.h>
#include <NTPClient.h>
#include "config.h"

// OLED Setup
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// MQTT Setup
WiFiClientSecure espClient;
PubSubClient client(espClient);

// NTP Client Setup (UTC+5:30 = 19800 seconds offset)
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 19800, 60000); // Update every 60 seconds

// Vibration Setup
bool vibrating = false;
unsigned long vibrationStartTime = 0;

// Emergency Button Setup
bool buttonState = HIGH;
bool lastButtonState = HIGH;
unsigned long lastDebounceTime = 0;

// Display Control
bool showMessage = false;
String mqttMessage = "";
unsigned long messageDisplayStart = 0;
unsigned long lastClockUpdate = 0;

void setup() {
  Serial.begin(115200);
  Serial.println("Starting setup...");

  // Initialize I2C
  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  Wire.setClock(50000); // 50 kHz for stability
  Serial.println("I2C initialized");

  // Initialize OLED
  Serial.println("Initializing OLED...");
  if (!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS)) {
    Serial.println("SSD1306 allocation failed");
    for (;;);
  }
  Serial.println("OLED initialized");
  displayStartupMessage("Starting...");

  // Initialize vibration and button
  pinMode(VIBRATION_PIN, OUTPUT);
  digitalWrite(VIBRATION_PIN, LOW);
  pinMode(EMERGENCY_BUTTON_PIN, INPUT_PULLUP);
  Serial.println("Vibration and button initialized");

  // Initialize Wi-Fi
  WiFiManager wifiManager;
  wifiManager.setTimeout(180);
  if (!wifiManager.autoConnect("SmartwatchAP", "password12")) {
    Serial.println("WiFi connection failed, restarting...");
    ESP.restart();
  }
  Serial.println("WiFi connected");
  displayStartupMessage("WiFi Setup Success");
  delay(2000);

  // Initialize NTP
  timeClient.begin();
  int ntpAttempts = 0;
  while (!timeClient.update() && ntpAttempts < 10) {
    Serial.println("Failed to get NTP time, retrying...");
    delay(1000);
    ntpAttempts++;
  }
  if (timeClient.isTimeSet()) {
    Serial.print("NTP time synced: ");
    Serial.println(timeClient.getFormattedTime());
  } else {
    Serial.println("NTP sync failed after 10 attempts");
  }

  // Initialize MQTT
  espClient.setInsecure();
  client.setServer(MQTT_SERVER, MQTT_PORT);
  client.setCallback(callback);
  reconnectMQTT();
  Serial.println("MQTT initialized");
  displayStartupMessage("MQTT Connection Success");
  delay(2000);

  // Show initial clock
  displayClock();
  Serial.println("Setup complete");
}

void loop() {
  if (!client.connected()) {
    reconnectMQTT();
  }
  client.loop();

  // Emergency button
  int reading = digitalRead(EMERGENCY_BUTTON_PIN);
  if (reading != lastButtonState) {
    lastDebounceTime = millis();
  }
  if ((millis() - lastDebounceTime) > DEBOUNCE_DELAY) {
    if (reading != buttonState) {
      buttonState = reading;
      if (buttonState == LOW) {
        sendEmergencyAlert();
      }
    }
  }
  lastButtonState = reading;

  // Handle vibration
  if (vibrating) {
    unsigned long elapsed = millis() - vibrationStartTime;
    if (elapsed >= VIBRATION_DURATION) {
      vibrating = false;
      digitalWrite(VIBRATION_PIN, LOW);
    } else {
      unsigned long cycleTime = VIBRATE_ON_TIME + VIBRATE_OFF_TIME;
      digitalWrite(VIBRATION_PIN, (elapsed % cycleTime) < VIBRATE_ON_TIME ? HIGH : LOW);
    }
  }

  // Handle MQTT message display timeout
  if (showMessage && (millis() - messageDisplayStart >= MESSAGE_DISPLAY_DURATION)) {
    showMessage = false;
    displayClock();
  }

  // Update clock display every second if no message is shown
  if (!showMessage && millis() - lastClockUpdate >= CLOCK_UPDATE_INTERVAL) {
    displayClock();
    lastClockUpdate = millis();
  }

  // Periodic location update
  static unsigned long lastLocationUpdate = 0;
  if (millis() - lastLocationUpdate >= 10000) { // 10 seconds
    float x = 0.0, y = 0.0;
    bool valid = false;
    updateLocation(x, y, valid);
    publishLocation(x, y, valid);
    lastLocationUpdate = millis();
  }
}