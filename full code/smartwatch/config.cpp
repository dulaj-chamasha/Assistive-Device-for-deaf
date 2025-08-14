#include "config.h"

// MQTT Configuration
const char* MQTT_SERVER = "6abc0015580b40a18e85854a64bc1375.s1.eu.hivemq.cloud";
const int MQTT_PORT = 8883;
const char* MQTT_USERNAME = "Dulaj";
const char* MQTT_PASSWORD = "1999Dulaj06#";
const char* MQTT_TOPIC_MESSAGE = "smartwatch/message";
const char* MQTT_TOPIC_POSITION = "trilateration/position";
const char* MQTT_TOPIC_EMERGENCY = "smartwatch/emergency";
const char* MQTT_TOPIC_DEVICEID = "smartwatch/deviceid";

// Trilateration Configuration
AP accessPoints[3] = {
  {"SLT_FIBER_349j6", 3.30, 6.00},
  {"Dialog 4G 721", 8.00, 1.00},
  {"SLT MOBITEL 4G", 1.00, 0.50}
};