// File: WiFi_RSSI_Measurement_SingleAP.ino

#include <WiFi.h>

// Define the AP to measure
const char* targetSSID = "Dialog 4G 365";
const int NUM_SCANS = 10; // Number of scans to average per distance

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("Starting RSSI Measurement for Smart Wearable Assistive Device...");
  Serial.flush();

  // Set WiFi to station mode
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);
  Serial.println("WiFi initialized in station mode");
  Serial.flush();
}

void loop() {
  float distance;

  // Input distance for the AP
  Serial.print("Enter distance from ");
  Serial.print(targetSSID);
  Serial.print(" (in meters, e.g., 1.0, 2.0, 3.0, 5.0, 6.0) or -1 to exit: ");
  Serial.flush();
  while (!Serial.available()) {
    delay(100);
  }
  distance = Serial.parseFloat();
  Serial.readString(); // Clear buffer
  if (distance < 0) {
    Serial.println("Exiting...");
    Serial.flush();
    while (true);
  }
  if (distance == 0) {
    Serial.println("Distance cannot be zero. Please re-enter.");
    delay(1000);
    return;
  }

  // Display entered distance on a single line
  Serial.println("Measuring RSSI at point with distance:");
  Serial.print(distance);
  Serial.print("m from ");
  Serial.println(targetSSID);
  Serial.println("...");
  Serial.flush();

  // Arrays to store RSSI sums and counts for averaging
  float rssiSum = 0;
  int rssiCount = 0;

  // Perform multiple scans
  for (int scan = 0; scan < NUM_SCANS; scan++) {
    Serial.print("Scan ");
    Serial.print(scan + 1);
    Serial.println(" of ");
    Serial.print(NUM_SCANS);
    Serial.println("...");
    Serial.flush();
    int numNetworks = WiFi.scanNetworks();
    if (numNetworks == 0) {
      Serial.println("No networks found in scan. Retrying...");
      Serial.flush();
      delay(500);
      continue;
    }
    Serial.print("Found ");
    Serial.print(numNetworks);
    Serial.println(" networks");
    Serial.flush();

    for (int i = 0; i < numNetworks; i++) {
      String ssid = WiFi.SSID(i);
      int rssi = WiFi.RSSI(i);
      if (ssid == targetSSID) {
        rssiSum += rssi;
        rssiCount++;
        Serial.print("AP: ");
        Serial.print(ssid);
        Serial.print(", RSSI: ");
        Serial.print(rssi);
        Serial.println(" dBm");
        Serial.flush();
      }
    }
    delay(100); // Delay between scans to avoid overwhelming WiFi
  }

  // Output averaged result
  Serial.println("\nMeasurement Result:");
  Serial.flush();
  if (rssiCount > 0) {
    float avgRssi = rssiSum / rssiCount;
    Serial.print("AP: ");
    Serial.print(targetSSID);
    Serial.print(", Distance: ");
    Serial.print(distance);
    Serial.print("m, Avg RSSI: ");
    Serial.print(avgRssi);
    Serial.println(" dBm");
  } else {
    Serial.print("AP: ");
    Serial.print(targetSSID);
    Serial.print(", Distance: ");
    Serial.print(distance);
    Serial.println("m, not detected");
  }
  Serial.flush();

  Serial.println("--------------------------------");
  Serial.println("Enter new distance or -1 to exit.");
  Serial.flush();

  delay(2000); // Delay before next measurement cycle
}