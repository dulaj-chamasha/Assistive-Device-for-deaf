// File: WiFi_RSSI_Measurement_Dynamic.ino

#include <WiFi.h>

// Define the APs to measure
const char* targetSSIDs[] = {
  "SLT MOBITEL 4G",  // AP1
  "Dialog 4G 721",   // AP2
  "Dialog 4G 365"    // AP3
};
const int NUM_APS = 3;
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
  float distances[NUM_APS];

  // Input distance for each AP
  for (int i = 0; i < NUM_APS; i++) {
    Serial.print("Enter distance from ");
    Serial.print(targetSSIDs[i]);
    Serial.print(" (in meters, e.g., 1.0, 2.0, 3.0, 5.0, 6.0) or -1 to exit: ");
    Serial.flush();
    while (!Serial.available()) {
      delay(100);
    }
    distances[i] = Serial.parseFloat();
    Serial.readString(); // Clear buffer
    if (distances[i] < 0) {
      Serial.println("Exiting...");
      Serial.flush();
      while (true);
    }
    if (distances[i] == 0) {
      Serial.println("Distance cannot be zero. Please re-enter.");
      i--;
      continue;
    }
  }

  // Arrays to store RSSI sums and counts for averaging
  float rssiSums[NUM_APS] = {0};
  int rssiCounts[NUM_APS] = {0};

  // Display entered distances
  Serial.print("Measuring RSSI at point with distances: ");
  for (int i = 0; i < NUM_APS; i++) {
    Serial.print(distances[i]);
    Serial.print("m from ");
    Serial.print(targetSSIDs[i]);
    if (i < NUM_APS - 1) Serial.print(", ");
  }
  Serial.println("...");
  Serial.flush();

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
      for (int j = 0; j < NUM_APS; j++) {
        if (ssid == targetSSIDs[j]) {
          rssiSums[j] += rssi;
          rssiCounts[j]++;
          Serial.print("AP: ");
          Serial.print(ssid);
          Serial.print(", RSSI: ");
          Serial.print(rssi);
          Serial.println(" dBm");
          Serial.flush();
        }
      }
    }
    delay(100); // Delay between scans to avoid overwhelming WiFi
  }

  // Output averaged results
  Serial.println("\nMeasurement Results:");
  Serial.flush();
  for (int i = 0; i < NUM_APS; i++) {
    if (rssiCounts[i] > 0) {
      float avgRssi = rssiSums[i] / rssiCounts[i];
      Serial.print("AP: ");
      Serial.print(targetSSIDs[i]);
      Serial.print(", Distance: ");
      Serial.print(distances[i]);
      Serial.print("m, Avg RSSI: ");
      Serial.print(avgRssi);
      Serial.println(" dBm");
    } else {
      Serial.print("AP: ");
      Serial.print(targetSSIDs[i]);
      Serial.print(", Distance: ");
      Serial.print(distances[i]);
      Serial.println("m, not detected");
    }
    Serial.flush();
  }
  Serial.println("--------------------------------");
  Serial.println("Enter new distances or -1 to exit.");
  Serial.flush();

  delay(2000); // Delay before next measurement cycle
}