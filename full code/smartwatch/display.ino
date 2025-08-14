void displayStartupMessage(String message) {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 20);
  display.println(message);
  display.display();
}

void displayClock() {
  timeClient.update();

  int hours = timeClient.getHours();
  int minutes = timeClient.getMinutes();
  int seconds = timeClient.getSeconds();
  int day = timeClient.getDay();
  String daysOfWeek[] = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};
  String dayOfWeek = daysOfWeek[day];

  unsigned long epochTime = timeClient.getEpochTime();
  time_t rawTime = (time_t)epochTime;
  struct tm* timeInfo = gmtime(&rawTime);
  int dateDay = timeInfo->tm_mday;
  int month = timeInfo->tm_mon + 1;
  int year = timeInfo->tm_year + 1900;

  display.clearDisplay();

  // Display time (large font, centered)
  display.setTextSize(2);
  display.setTextColor(SSD1306_WHITE);
  String timeStr = String(hours) + ":" +
                   (minutes < 10 ? "0" + String(minutes) : String(minutes)) + ":" +
                   (seconds < 10 ? "0" + String(seconds) : String(seconds));
  int16_t x1, y1;
  uint16_t w, h;
  display.getTextBounds(timeStr, 0, 0, &x1, &y1, &w, &h);
  display.setCursor((SCREEN_WIDTH - w) / 2, 8);
  display.print(timeStr);

  // Display date (smaller font, centered)
  display.setTextSize(1);
  String dateStr = (dateDay < 10 ? "0" + String(dateDay) : String(dateDay)) + "/" +
                   (month < 10 ? "0" + String(month) : String(month)) + "/" + String(year);
  display.getTextBounds(dateStr, 0, 0, &x1, &y1, &w, &h);
  display.setCursor((SCREEN_WIDTH - w) / 2, 32);
  display.print(dateStr);

  // Display day of the week (smaller font, centered)
  display.getTextBounds(dayOfWeek, 0, 0, &x1, &y1, &w, &h);
  display.setCursor((SCREEN_WIDTH - w) / 2, 48);
  display.print(dayOfWeek);

  display.display();
}

void displayMQTTMessage(String topic, String message) {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.print("Topic: ");
  display.println(topic);
  display.print("Message: ");
  display.println(message);
  display.display();
}