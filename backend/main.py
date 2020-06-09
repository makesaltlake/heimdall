import argparse
import json
import os
import threading
import time
import uuid
from rfid_badge import BadgeReader
from rfid_badge import BadgeWriter
from web_client import HeimdallWebClient
from display import UserFeedback


def badge_reader_thread():
    reader = BadgeReader()

    while True:
        print("Waiting for badge")
        tid = reader.scan_tag()
        badge_token = None
        authorized = False

        if tid is not None:
            badge_token = reader.get_badge_token(tid)
            if badge_token is None:
                ui.error()
            elif badge_token not in web.allowed_badge_tokens:
                ui.access_denied()
            else:
                ui.access_allowed()
                authorized = True
        else:
            ui.error()

        # Convert the list representing the tag ID to
        # a hex representation
        shift = (len(tid) - 1) * 8
        tag_id = 0
        for t in tid:
            tag_id += int(t) << shift
            shift -= 8

        hex_tag_id = format(tag_id, '0' + str(len(tid) * 2) + 'x')

        web.post_badge_scan(tag_id=hex_tag_id, badge_token=badge_token, authorized=authorized,
                            time_of_scan=int(time.time()))

        time.sleep(2)


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

    web = HeimdallWebClient()
    ui = UserFeedback()

    tag_key = os.environ['BADGE_KEY']

    if args.mode == 'READER':
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
