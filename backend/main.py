import requests
import requests_cache
import os
import uuid
import time
import argparse
import threading
from pirc522 import RFID
from gpiozero import LED
from gpiozero import TonalBuzzer
import json
import RPi.GPIO


class UserFeedback:

    def __init__(self):
        self.green_led = LED(pin=26)
        self.red_led = LED(pin=19)
        self.buzzer = TonalBuzzer(pin=13)

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
        self.buzzer.play(tone=880)
        time.sleep(2)
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


class HeimdallWeb:

    def __init__(self):
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
            print('get_badge_list, content = ' + str(json.loads(response.content)))
        else:
            print('Web API returned error ' + str(response.status_code))

        return response.ok

    def post_badge_scan(self, badge_token, time_of_scan):

        badge_scan_info = {'badge_token': str(badge_token),
                           'scanned_at': str(time_of_scan)}

        response = requests.post(self.badge_scan_url, headers=self.reader_headers, json=badge_scan_info)
        return response.ok

    def post_programmed_badge(self, badge_token):
        program_info = {'badge_token': str(badge_token)}
        response = requests.post(self.badge_program_url, headers=self.writer_headers, json=program_info)
        return response.ok


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
        self.util.do_auth(self.util.block_addr(0, 1))
        (error, data) = self.rdr.read(self.util.block_addr(0, 1))

        if not error:
            print('Successfully read data')
            try:
                token = uuid.UUID(bytes=data)
                print('Got badge token ' + str(token))
            except AssertionError:
                print('Invalid UUID read from badge.')
        else:
            print('Failed to read data.')

        self.util.deauth()
        if not error:
            return data

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

    def __init__(self, web):
        self.rdr = RFID()
        self.util = self.rdr.util()
        self.web = web

    def __del__(self):
        self.rdr.cleanup()

    def program_badge(self):
        self.rdr.wait_for_tag()
        (error, tag_data) = self.rdr.request()
        if not error:
            (error, tid) = self.rdr.anticoll()
        if not error:
            badge_token = uuid.uuid4()

            a = badge_token.replace('-', '')
            i = int(a, 16)
            h = i.to_bytes(length=16)

            self.rdr.write(block_address=1, data=h)


def badge_reader_thread():
    reader = BadgeReader()

    while True:
        tid = reader.scan_tag()
        if tid is not None:
            reader.get_badge_token(tid)

#            web.post_badge_scan(badge_token, time.time())


def web_thread():

    while True:
        web.get_badge_list()
        time.sleep(300)


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument('--verbose', dest='verbose', action='store_true')

    web = HeimdallWeb()
    ui = UserFeedback()

    tag_key = os.environ['BADGE_KEY']

    print("Ready.")

    reader_thread = threading.Thread(target=badge_reader_thread)
    reader_thread.start()

    web_thread = threading.Thread(target=web_thread)
    web_thread.start()

    reader_thread.join()
    web_thread.join()

