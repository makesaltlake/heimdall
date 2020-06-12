"""


"""

__license__ = "MIT"
__version__ = "0.1"
__status__ = "Development"

import argparse
import json
import logging
import os
import threading
import time
import uuid
from signal import signal, SIGINT

from display import UserFeedback
from rfid_badge import BadgeReader
from rfid_badge import BadgeWriter
from web_client import HeimdallWebClient


def badge_reader_thread():
    reader = BadgeReader()

    while True:
        logging.info("Waiting for badge")
        tid = reader.scan_tag()
        if tid is None:
            continue

        badge_token = None
        authorized = False
        time_of_scan = int(time.time())

        # Convert the list representing the tag ID to
        # a hex representation
        shift = (len(tid) - 1) * 8
        tag_id = 0
        for t in tid:
            tag_id += int(t) << shift
            shift -= 8

        hex_tag_id = format(tag_id, '0' + str(len(tid) * 2) + 'x')

        if tid is not None:
            badge_token = reader.get_badge_token(tid)

        if tid is None or badge_token is None:
            ui.error()
        elif badge_token in web.__allowed_badge_tokens:
            authorized = True
            ui.access_allowed()
        else:
            ui.access_denied()

        web.post_badge_scan(tag_id=hex_tag_id, badge_token=badge_token, authorized=authorized,
                            time_of_scan=time_of_scan)


def badge_writer_thread():
    writer = BadgeWriter()

    while True:
        ui.msg_clear()
        ui.msg("Ready to write badge", 1)
        ui.msg("Place badge onto", 3)
        ui.msg("RFID writer.", 4)

        tag_id = writer.scan_badge()
        if tag_id is None:
            continue

        ui.msg_clear()
        ui.msg("Found badge.", 1)

        badge_token = uuid.uuid4()

        ui.msg("Badge token: ", 2)
        values = str(badge_token).split('-')
        ui.msg(values[0] + '-' + values[1] + '-' + values[2], 3)
        ui.msg(values[3], 4)

        time.sleep(1)

        response = web.post_programmed_badge(badge_token=badge_token, time_of_scan=int(time.time()))
        if response.ok:
            rsp_json = json.loads(response.content)
            status = rsp_json['status']
            if status == "ok":
                ui.msg_clear()
                ui.msg('Web API: OK', 1)
                ui.msg('Writing badge', 2)
                error = writer.program_badge(tag_id=tag_id, badge_token=str(badge_token))
                if error:
                    ui.msg("RFID WRITE ERROR", 3)
                else:
                    ui.msg("RFID WRITE SUCCESS", 3)
                    logging.info('Programmed badge: ' + str(badge_token))
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


def handler(signal_received, frame):
    print("SIGINT or Ctrl-C detected: exiting.")
    # Exit. The deconstructors will handle any cleanup.
    exit(0)


def web_thread():
    while True:
        web.get_badge_list()
        time.sleep(300)


if __name__ == "__main__":

    signal(SIGINT, handler)

    parser = argparse.ArgumentParser(prog='heimdall')
    parser.add_argument('-d', '--debug', help="Print debug output",
                        action="store_const", dest="debuglevel", const=logging.DEBUG, default=logging.WARNING)
    parser.add_argument('-v', '--verbose', help="Increase verbosity",
                        action='store_const', dest="debuglevel", const=logging.INFO)
    parser.add_argument('-m', '--mode', dest='mode', choices=['READER', 'WRITER'], required=True)
    parser.add_argument('--version', action='version', version='%(prog)s ' + __version__)

    args = parser.parse_args()

    logging.basicConfig(level=args.debuglevel)

    if args.mode == 'READER':
        if ('READER_API_KEY' not in os.environ or
                'TAG_KEY' not in os.environ):
            print('Both READER_API_KEY and TAG_KEY environment variables must be set '
                  'when operating in READER mode')
            exit(1)
    else:
        if ('WRITER_API_KEY' not in os.environ or
                'TAG_KEY' not in os.environ):
            print('Both WRITER_API_KEY and TAG_KEY environment variables must be set '
                  'when operating in WRITER mode')
            exit(1)

    TAG_KEY_BYTES = 6

    num_hex_digits = 2 * TAG_KEY_BYTES

    if len(os.environ['TAG_KEY']) != num_hex_digits:
        print('TAG_KEY format error: should be ' + str(num_hex_digits) + ' hexadecimal digits')
        exit(1)
    else:
        try:
            tag_key = os.environ['TAG_KEY']
            tag_int = int(tag_key, 16)
            tag_bytes = tag_int.to_bytes(length=TAG_KEY_BYTES, byteorder="big")
        except (ValueError, OverflowError):
            print('TAG_KEY format error: should be of the format ABCDEF01')
            exit(1)

    web = HeimdallWebClient(operating_mode=args.mode)
    ui = UserFeedback()

    if args.mode == 'READER':
        logging.info('Operating in READER mode.')
        web_thread = threading.Thread(target=web_thread)
        web_thread.daemon = True  # Kill thread when main thread ends
        web_thread.start()
        reader_thread = threading.Thread(target=badge_reader_thread)
        reader_thread.daemon = True  # Kill thread when main thread ends
        reader_thread.start()
        reader_thread.join()
        web_thread.join()
    else:
        logging.info('Operating in WRITER mode.')
        writer_thread = threading.Thread(target=badge_writer_thread)
        writer_thread.daemon = True  # Kill thread when main thread ends
        writer_thread.start()
        writer_thread.join()
