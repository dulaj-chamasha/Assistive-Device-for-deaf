void callback(char* topic, byte* payload, unsigned int length) {
  mqttMessage = "";
  for (unsigned int i = 0; i < length; i++) {
    mqttMessage += (char)payload[i];
  }
  Serial.print("Message received on topic: ");
  Serial.print(topic);
  Serial.print(": ");
  Serial.println(mqttMessage);

  showMessage = true;
  messageDisplayStart = millis();
  displayMQTTMessage(topic, mqttMessage);

  vibrating = true;
  vibrationStartTime = millis();
  digitalWrite(VIBRATION_PIN, HIGH);
}

void reconnectMQTT() {
  while (!client.connected()) {
    Serial.print("Connecting to MQTT...");
    if (client.connect("ESP32Client", MQTT_USERNAME, MQTT_PASSWORD)) {
      Serial.println("connected");
      client.subscribe(MQTT_TOPIC_MESSAGE);
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" retrying in 2 seconds");
      delay(2000);
    }
  }
}

void sendEmergencyAlert() {
  char msg[100];
  snprintf(msg, sizeof(msg), "{\"deviceId\":\"%s\",\"timestamp\":%lu,\"emergency\":true}", DEVICE_ID.c_str(), millis());
  if (client.publish(MQTT_TOPIC_EMERGENCY, msg, true)) {
    Serial.println("Emergency alert sent!");
  } else {
    Serial.println("Failed to send emergency alert");
  }
  if (client.publish(MQTT_TOPIC_DEVICEID, DEVICE_ID.c_str())) {
    Serial.println("Device ID published");
  } else {
    Serial.println("Failed to publish device ID");
  }
}