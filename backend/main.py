import requests
import requests_cache
import os
import json
import uuid
import time
import argparse
import threading
import RPi.GPIO
from pirc522 import RFID
from gpiozero import LED
from gpiozero import TonalBuzzer
from I2C_LCD_driver import lcd


class UserFeedback:

    def __init__(self):
        self.green_led = LED(pin=26)
        self.red_led = LED(pin=19)
        self.buzzer = TonalBuzzer(pin=13)
        self.lcd = lcd()

    def error(self):
        self.red_led.blink(on_time=0.5, off_time=0.5)
        for i in range(0,3):
            self.buzzer.play(tone=220)
            time.sleep(0.2)
            self.buzzer.stop()
            time.sleep(0.2)

        self.red_led.off()

    def access_allowed(self):
        self.green_led.on()
        self.buzzer.play(tone=700)
        time.sleep(1)
        self.green_led.off()
        self.buzzer.stop()

    def access_denied(self):
        self.red_led.blink(on_time=0.5, off_time=0.5)
        for i in range(0,2):
            self.buzzer.play(tone=220)
            time.sleep(0.5)
            self.buzzer.stop()
            time.sleep(0.5)

        self.red_led.off()

    def msg(self, message, line):
        self.lcd.lcd_display_string(message, line)

    def msg_clear(self):
        self.lcd.lcd_clear()


class HeimdallWeb:

    def __init__(self):
        self.allowed_badge_tokens = []
        try:
            self.reader_api_key = os.environ['READER_API_KEY']
            self.writer_api_key = os.environ['WRITER_API_KEY']
        except KeyError:
            self.reader_api_key = None
            self.writer_api_key = None

        self.badge_token_url = 'https://msl-heimdall-dev.herokuapp.com/api/badge_readers/access_list'
        self.badge_scan_url = 'https://msl-heimdall-dev.herokuapp.com/api/badge_readers/record_scans'
        self.badge_program_url = 'https://msl-heimdall-dev.herokuapp.com/api/badge_writers/program'

        self.reader_headers = {'Content-Type': 'application/json',
                               'Authorization': 'Bearer {0}'.format(self.reader_api_key)}

        self.writer_headers = {'Content-Type': 'application/json',
                               'Authorization': 'Bearer {0}'.format(self.writer_api_key)}

        requests_cache.install_cache(backend='memory', expire_after=300, old_data_on_error=True)

    def get_badge_list(self):
        response = requests.get(url=self.badge_token_url, headers=self.reader_headers)
        if response.ok:
            self.allowed_badge_tokens = json.loads(response.content)['badge_tokens']
            print('get_badge_list, content = ' + str(json.loads(response.content)))

        else:
            print('Web API returned error ' + str(response.status_code))

        return response.ok

    def post_badge_scan(self, badge_token, time_of_scan):

        badge_scan_info = {'badge_token': str(badge_token),
                           'scanned_at': str(time_of_scan)}

        response = requests.post(self.badge_scan_url, headers=self.reader_headers, json=badge_scan_info)
        print('response: ' + str(response.content))
        return response.ok

    def post_programmed_badge(self, badge_token, time_of_scan=time):
        program_info = {'badge_token': str(badge_token),
                        'scanned_at:': str(time_of_scan)}
        response = requests.post(self.badge_program_url, headers=self.writer_headers, json=program_info)
        return response


class BadgeReader:

    def __init__(self):
        # Since gpiozero uses BCM pin numbering, tell RFID to use that too,
        # and configure the pins as listed at https://github.com/ondryaso/pi-rc522
        self.rdr = RFID(pin_mode=RPi.GPIO.BCM, pin_irq=24, pin_rst=25)
        self.util = self.rdr.util()

    def __del__(self):
        self.rdr.cleanup()

    def get_badge_token(self, tid):
        self.util.set_tag(tid)
        self.util.auth(self.rdr.auth_b, [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
        self.util.do_auth(block_address=1)
        (error, data) = self.rdr.read(block_address=1)

        if not error:
            print('Successfully read data')
            i = int.from_bytes(bytes=data, byteorder="little")
            print('data: ' + format(i, '02x'))
            try:
                token = uuid.UUID(bytes=i.to_bytes(length=16, byteorder="big"))
                print('Got badge token ' + str(token))
            except AssertionError:
                print('Invalid UUID read from badge.')
                error = True
        else:
            print('Failed to read data.')

        self.util.deauth()
        if not error:
            return str(token)

        return None

    def scan_tag(self):
        self.rdr.wait_for_tag()
        (error, tag_data) = self.rdr.request()

        if not error:
            print('Found badge: running anti-collision')
            (error, tid) = self.rdr.anticoll()
            if not error:
                print('Found a badge with Tag ID ' + str(tid))
                return tid
            else:
                print('Anti-collision failed')
        else:
            print('Error reading badge')

        return None


class BadgeWriter:

    def __init__(self):
        self.rdr = RFID(pin_mode=RPi.GPIO.BCM, pin_irq=24, pin_rst=25)
        self.util = self.rdr.util()
        self.util.debug = True

    def __del__(self):
        self.rdr.cleanup()

    def scan_badge(self):
        self.rdr.wait_for_tag()
        (error, tag_data) = self.rdr.request()
        if not error:
            (error, tid) = self.rdr.anticoll()
            return tid

        return None

    def program_badge(self, tid, badge_token):
        badge_token_128bit_int = int(badge_token.replace('-', ''), 16)
        badge_token_16_bytes = badge_token_128bit_int.to_bytes(length=16, byteorder="little")

        self.util.set_tag(tid)
        self.util.auth(self.rdr.auth_b, [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
        self.util.do_auth(self.util.block_addr(0, 1))

        error = self.rdr.write(block_address=1, data=badge_token_16_bytes)
        return error


def badge_reader_thread():
    reader = BadgeReader()

    while True:
        print("Waiting for badge")
        tid = reader.scan_tag()
        if tid is not None:
            badge_token = reader.get_badge_token(tid)
            if badge_token is None:
                ui.error()
            elif badge_token not in web.allowed_badge_tokens:
                ui.access_denied()
            else:
                ui.access_allowed()
                web.post_badge_scan(badge_token=badge_token, time_of_scan=int(time.time()))
        else:
            ui.error()

        time.sleep(2)

#            web.post_badge_scan(badge_token, time.time())


def badge_writer_thread():
    writer = BadgeWriter()

    while True:
        ui.msg_clear()
        ui.msg("Ready to write badge", 1)
        ui.msg("Place badge onto", 3)
        ui.msg("RFID writer.", 4)

        tid = writer.scan_badge()
        if tid is None:
            continue

        ui.msg_clear()
        ui.msg("Found badge.", 1)

        badge_token = uuid.uuid4()

        ui.msg("Badge token: ", 2)
        values = str(badge_token).split('-')
        ui.msg(values[0] + '-' + values[1] + '-' + values[2], 3)
        ui.msg(values[3], 4)

        time.sleep(1)

        response = web.post_programmed_badge(badge_token=badge_token)
        if response.ok:
            rsp_json = json.loads(response.content)
            status = rsp_json['status']
            if status == "ok":
                ui.msg_clear()
                ui.msg('Web API: OK', 1)
                ui.msg('Writing badge', 2)
                error = writer.program_badge(tid=tid, badge_token=str(badge_token))
                if error:
                    ui.msg("RFID WRITE ERROR", 3)
                else:
                    ui.msg("RFID WRITE SUCCESS", 3)
                    print('Programmed badge: ' + str(badge_token))
                    ui.msg(rsp_json['user']['name'], 4)
            elif status == "duplicate_badge_token":
                ui.msg_clear()
                ui.msg("Web API ERROR", 1)
                ui.msg("Duplicate token", 2)
            elif status == "not_programming":
                ui.msg_clear()
                ui.msg("Web API ERROR", 1)
                ui.msg("Not programming", 2)
            else:
                ui.msg_clear()
                ui.msg("Web API ERROR", 1)
                ui.msg(status, 2)
        else:
            ui.msg_clear()
            ui.msg("Web API ERROR", 1)
            ui.msg(str(response.status_code), 2)

        time.sleep(5)


def web_thread():

    while True:
        web.get_badge_list()
        time.sleep(300)


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true')
    parser.add_argument('-m', '--mode', dest='mode', choices=['READER', 'WRITER'], default='READER')

    args = parser.parse_args()

    web = HeimdallWeb()
    ui = UserFeedback()

    tag_key = os.environ['BADGE_KEY']

    if args.mode is 'READER':
        print('Operating in READER mode.')
        web_thread = threading.Thread(target=web_thread)
        web_thread.start()
        reader_thread = threading.Thread(target=badge_reader_thread)
        reader_thread.start()
        reader_thread.join()
        web_thread.join()
    else:
        print('Operating in WRITER mode.')
        writer_thread = threading.Thread(target=badge_writer_thread)
        writer_thread.start()
        writer_thread.join()


