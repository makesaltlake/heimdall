import requests
import requests_cache
import os
import uuid
import time
import argparse
import threading
from pirc522 import RFID


tag_key = os.environ['BADGE_KEY']


class HeimdallWeb:

    def __init__(self):
        self.reader_api_key = os.environ['READER_API_KEY']
        self.writer_api_key = os.environ['WRITER_API_KEY']

        self.badge_token_url = 'https://msl-heimdall-dev.herokuapp.com/api/badge_readers/access_list'
        self.badge_scan_url = 'https://msl-heimdall-dev.herokuapp.com/api/badge_readers/record_scans'
        self.badge_program_url = 'https://msl-heimdall-dev.herokuapp.com/api/badge_writers/program'

        self.reader_headers = {'Content-Type': 'application/json',
                               'Authorization': 'Bearer {0}'.format(self.reader_api_key)}

        self.writer_headers = {'Content-Type': 'application/json',
                               'Authorization': 'Bearer {0}'.format(self.writer_api_key)}

        requests_cache.install_cache(backend='memory', expire_after=300, old_data_on_error=True)

    def get_badge_list(self):
        (error, response) = requests.post(self.badge_token_url, headers=self.reader_headers)
        return not error

    def post_badge_scan(self, badge_token, time_of_scan):

        badge_scan_info = {'badge_token': str(badge_token),
                           'scanned_at': str(time_of_scan)}

        (error, response) = requests.post(self.badge_scan_url, headers=self.reader_headers, json=badge_scan_info)
        return not error

    def post_programmed_badge(self, badge_token):
        program_info = {'badge_token': str(badge_token)}
        (error, response) = requests.post(self.badge_program_url, headers=self.writer_headers, json=program_info)
        return not error


class BadgeReader:

    def __init__(self):
        self.rdr = RFID()
        self.util = self.rdr.util()

    def get_badge_token(self, tid):
        self.util.set_tag(tid)
        self.util.auth(self.rdr.auth_b, [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])

        (error, data) = self.rdr.read(self.util.block_addr(0, 1))
        self.util.deauth()
        if not error:
            return data

        return None

    def scan_tag(self):
        self.rdr.wait_for_tag()
        (error, tag_data) = self.rdr.request()
        if not error:
            (error, tid) = self.rdr.anticoll()
            if not error:
                return tid

            return None


class BadgeWriter:

    def __init__(self, web):
        self.rdr = RFID()
        self.util = self.rdr.util()
        self.web = web

    def program_badge(self):
        self.rdr.wait_for_tag()
        (error, tag_data) = self.rdr.request()
        if not error:
            (error, tid) = self.rdr.anticoll()
        if not error:
            badge_token = uuid.uuid4()
            self.rdr.write(block_address=1, data=badge_token[0:8])
            self.rdr.write(block_address=2, data=badge_token[9:24])
            self.rdr.write(block_address=3, data=badge_token[25:])


def badge_reader_thread(web):
    reader = BadgeReader()

    while True:
        tid = reader.scan_tag()
        if tid is not None:
            badge_token = reader.get_badge_token(tid)
            web.post_badge_scan(badge_token, time.time())


def web_thread(web):

    while True:
        web.get_badge_list()


if __name__ == "__main__":
    web = HeimdallWeb()

    reader_thread = threading.Thread(target=badge_reader_thread, args=(web,))
    reader_thread.start()

    web_thread = threading.Thread(target=web_thread, args=(web,))
    web_thread.start()

    reader_thread.join()
    web_thread.join()

