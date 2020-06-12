import time

from gpiozero import LED
from gpiozero import TonalBuzzer

from i2c_lcd import lcd


class UserFeedback:

    def __init__(self):
        self.green_led = LED(pin=26)
        self.red_led = LED(pin=19)
        self.buzzer = TonalBuzzer(pin=13)
        self.lcd = lcd()

    def error(self):
        self.red_led.blink(on_time=0.5, off_time=0.5)
        for i in range(0, 3):
            self.buzzer.play(tone=220)
            time.sleep(0.2)
            self.buzzer.stop()
            time.sleep(0.2)

        self.red_led.off()

    def access_allowed(self):
        self.green_led.on()
        self.buzzer.play(tone=700)
        time.sleep(1)
        self.buzzer.stop()
        time.sleep(1)
        self.green_led.off()

    def access_denied(self):
        self.red_led.blink(on_time=0.5, off_time=0.5)
        for i in range(0, 2):
            self.buzzer.play(tone=220)
            time.sleep(0.5)
            self.buzzer.stop()
            time.sleep(0.5)

        self.red_led.off()

    def msg(self, message, line):
        self.lcd.lcd_display_string(message, line)

    def msg_clear(self):
        self.lcd.lcd_clear()
