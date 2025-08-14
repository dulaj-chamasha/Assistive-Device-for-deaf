float estimateDistance(int rssi, int A = -50, float n = 3.0) {
  float distance = pow(10.0, ((A - rssi) / (10.0 * n)));
  Serial.print("RSSI: ");
  Serial.print(rssi);
  Serial.print(" dBm, Estimated distance: ");
  Serial.print(distance, 2);
  Serial.println(" m");
  return distance;
}

void trilateration(float x1, float y1, float d1, float x2, float y2, float d2, float x3, float y3, float d3, float &x, float &y) {
  float A = 2 * (x2 - x1);
  float B = 2 * (y2 - y1);
  float C = d1 * d1 - d2 * d2 - x1 * x1 - y1 * y1 + x2 * x2 + y2 * y2;
  float D = 2 * (x3 - x1);
  float E = 2 * (y3 - y1);
  float F = d1 * d1 - d3 * d3 - x1 * x1 - y1 * y1 + x3 * x3 + y3 * y3;
  
  float denominator = (B * D - A * E);
  if (abs(denominator) < 0.0001) {
    Serial.println("Trilateration failed: APs are nearly collinear");
    x = y = 0.0;
    return;
  }
  
  y = (C * D - A * F) / denominator;
  x = (C - B * y) / A;
  
  if (isnan(x) || isnan(y) || isinf(x) || isinf(y)) {
    Serial.println("Trilateration failed: Invalid coordinates");
    x = y = 0.0;
  } else {
    Serial.print("Calculated position: X=");
    Serial.print(x, 2);
    Serial.print(" m, Y=");
    Serial.print(y, 2);
    Serial.println(" m");
  }
}

void updateLocation(float &x, float &y, bool &valid) {
  Serial.println("Starting Wi-Fi scan...");
  delay(100); // Stabilize Wi-Fi
  int numNetworks = WiFi.scanNetworks();
  if (numNetworks == 0) {
    Serial.println("No networks found, retrying once...");
    delay(100);
    numNetworks = WiFi.scanNetworks();
  }
  Serial.print("Found ");
  Serial.print(numNetworks);
  Serial.println(" networks");

  float distances[3] = {-1, -1, -1};
  bool foundAP[3] = {false, false, false};

  if (numNetworks == 0) {
    Serial.println("No networks found after retry");
    valid = false;
    return;
  }

  for (int i = 0; i < numNetworks; i++) {
    Serial.print("Network ");
    Serial.print(i + 1);
    Serial.print(": SSID=");
    Serial.print(WiFi.SSID(i));
    Serial.print(", RSSI=");
    Serial.print(WiFi.RSSI(i));
    Serial.println(" dBm");
  }

  for (int i = 0; i < numNetworks; i++) {
    String ssid = WiFi.SSID(i);
    int rssi = WiFi.RSSI(i);
    for (int j = 0; j < 3; j++) {
      if (ssid == accessPoints[j].ssid) {
        Serial.print("Matched AP: ");
        Serial.print(ssid);
        Serial.print(" at index ");
        Serial.println(j);
        distances[j] = estimateDistance(rssi);
        foundAP[j] = true;
      }
    }
  }

  if (foundAP[0] && foundAP[1] && foundAP[2]) {
    Serial.println("All target APs found:");
    for (int i = 0; i < 3; i++) {
      Serial.print("AP ");
      Serial.print(accessPoints[i].ssid);
      Serial.print(": Distance=");
      Serial.print(distances[i], 2);
      Serial.println(" m");
    }
    trilateration(
      accessPoints[0].x, accessPoints[0].y, distances[0],
      accessPoints[1].x, accessPoints[1].y, distances[1],
      accessPoints[2].x, accessPoints[2].y, distances[2],
      x, y
    );
    valid = true;
  } else {
    Serial.println("Not all target APs detected:");
    for (int i = 0; i < 3; i++) {
      if (!foundAP[i]) {
        Serial.print("Missing AP: ");
        Serial.println(accessPoints[i].ssid);
      }
    }
    valid = false;
  }
}

void publishLocation(float x, float y, bool valid) {
  if (valid) {
    char positionStr[100];
    snprintf(positionStr, sizeof(positionStr), "{\"x\": %.2f, \"y\": %.2f, \"timestamp\": %lu}", x, y, millis());
    if (client.publish(MQTT_TOPIC_POSITION, positionStr)) {
      Serial.println("Location published to MQTT");
    } else {
      Serial.println("Failed to publish location");
    }
  } else {
    Serial.println("Location invalid, not published");
  }
}