import logging
import uuid

import RPi.GPIO

from pirc522 import RFID


class BadgeReader:
    """
    RFID badge reader.
    """

    def __init__(self):
        # Since gpiozero uses BCM pin numbering, tell RFID to use that too,
        # and configure the pins as listed at https://github.com/ondryaso/pi-rc522
        self.rdr = RFID(pin_mode=RPi.GPIO.BCM, pin_irq=24, pin_rst=25)
        self.util = self.rdr.util()

    def __del__(self):
        self.rdr.cleanup()

    def get_badge_token(self, tag_id):
        """
        Attempts to read the badge token that we store on the badge/tag.

        :param tag_id: a list of bytes representing the tag UID.
        :return: a string representation of the badge token, as a UUID.
        """
        self.util.set_tag(tag_id)
        token = None
        self.util.auth(self.rdr.auth_b, [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
        self.util.do_auth(block_address=1)
        (error, data) = self.rdr.read(block_address=1)

        if not error:
            logging.info('Successfully read data')
            i = int.from_bytes(bytes=data, byteorder="little")
            logging.info('data: ' + format(i, '02x'))
            try:
                token = uuid.UUID(bytes=i.to_bytes(length=16, byteorder="big"))
                logging.info('Got badge token ' + str(token))
            except AssertionError:
                logging.info('Invalid UUID read from badge.')
                error = True
        else:
            logging.info('Failed to read data.')

        self.util.deauth()
        if not error:
            return str(token)

        return None

    def scan_tag(self):
        self.rdr.wait_for_tag()
        (error, tag_data) = self.rdr.request()

        if not error:
            logging.info('Found badge: running anti-collision')
            (error, tid) = self.rdr.anticoll()
            if not error:
                logging.info('Found a badge with Tag ID ' + str(tid))
                return tid
            else:
                logging.info('Anti-collision failed')
        else:
            logging.info('Error reading badge')

        return None


class BadgeWriter:
    """
    RFID badge writer

    Methods
    -------
    scan_badge:
        Waits for a tag to be presented to the reader, and returns its tag ID

    program_badge:
        Programs the tag that's present with the specified tag_id with the new badge token
    """

    def __init__(self):
        self.rdr = RFID(pin_mode=RPi.GPIO.BCM, pin_irq=24, pin_rst=25)
        self.util = self.rdr.util()
        self.util.debug = True

    def __del__(self):
        self.rdr.cleanup()

    def scan_badge(self):
        """
        Waits for a badge to be presented to the reader,

        :return: tag ID on success, or None on error
        """

        self.rdr.wait_for_tag()
        (error, tag_data) = self.rdr.request()
        if not error:
            (error, tag_id) = self.rdr.anticoll()
            if error:
                return None

            return tag_id

        return None

    def program_badge(self, tag_id, badge_token):
        """

        :param tag_id: Current tag ID.
        :param badge_token: the badge token UUID, in the form 12345678-abcd-1234-abcd-123456789abc.
        :return: True on error, False on success.
        """

        badge_token_128bit_int = int(badge_token.replace('-', ''), 16)
        badge_token_16_bytes = badge_token_128bit_int.to_bytes(length=16, byteorder="little")

        self.util.set_tag(tag_id)
        self.util.auth(self.rdr.auth_b, [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
        self.util.do_auth(self.util.block_addr(0, 1))

        error = self.rdr.write(block_address=1, data=badge_token_16_bytes)
        return error
