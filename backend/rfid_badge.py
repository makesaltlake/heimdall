import logging
import uuid
import os
import random

import RPi.GPIO

from pirc522 import RFID

TAG_KEY_BYTES = 6


def get_tag_key():
    tag_key_env = os.environ['TAG_KEY']
    tag_key_int = int(tag_key_env, 16)
    tag_key_bytes = tag_key_int.to_bytes(length=TAG_KEY_BYTES, byteorder="big")
    return list(tag_key_bytes)


class BadgeReader:
    """
    RFID badge reader.
    """

    def __init__(self):
        # Since gpiozero uses BCM pin numbering, tell RFID to use that too,
        # and configure the pins as listed at https://github.com/ondryaso/pi-rc522
        self.__rdr = RFID(pin_mode=RPi.GPIO.BCM, pin_irq=24, pin_rst=25)
        self.__util = self.__rdr.util()

        if logging.getLogger().isEnabledFor(logging.DEBUG):
            self.__util.debug = True

        self.__tag_key = get_tag_key()

    def __del__(self):
        self.__rdr.cleanup()

    def get_badge_token(self, tag_id):
        """
        Attempts to read the badge token that we store on the badge/tag.

        :param tag_id: a list of bytes representing the tag UID.
        :return: a string representation of the badge token, as a UUID.
        """
        self.__util.set_tag(tag_id)
        token = None
        self.__util.auth(self.__rdr.auth_a, self.__tag_key)
        error = self.__util.do_auth(block_address=1)
        if error:
            logging.warning('Failed to authenticate card using TAG_KEY as MIFARE KEY A')
            return None

        (error, data) = self.__rdr.read(block_address=1)

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

        self.__util.deauth()
        if not error:
            return str(token)

        return None

    def scan_tag(self):
        self.__rdr.wait_for_tag()
        (error, tag_data) = self.__rdr.request()

        if not error:
            logging.info('Found badge: running anti-collision')
            (error, tid) = self.__rdr.anticoll()
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
        self.__rdr = RFID(pin_mode=RPi.GPIO.BCM, pin_irq=24, pin_rst=25)
        self.__util = self.__rdr.util()

        if logging.getLogger().isEnabledFor(logging.DEBUG):
            self.__util.debug = True

        self.__tag_key = get_tag_key()

    def __del__(self):
        self.__rdr.cleanup()

    def scan_badge(self):
        """
        Waits for a badge to be presented to the reader,

        :return: tag ID on success, or None on error
        """

        self.__rdr.wait_for_tag()
        (error, tag_data) = self.__rdr.request()
        if not error:
            logging.info('Found tag of type ' + str(hex(tag_data)))
            (error, tag_id) = self.__rdr.anticoll()
            if error:
                logging.warning('anti-collision failed')
                return None

            logging.info('Found tag with UID ' + str(tag_id))
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

        self.__util.set_tag(tag_id)
        manufacturer_default_key = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
        self.__util.auth(auth_method=self.__rdr.auth_a, key=manufacturer_default_key)
        error = self.__util.do_auth(block_address=0)
        if error:
            #  Retry using the TAG_KEY
            logging.warning('Failed to authenticate tag with manufacturer default KEY A; trying '
                            'to authenticate using TAG_KEY instead.')

            self.__util.deauth()
            self.__rdr.stop_crypto()
            tag_id = self.scan_badge()
            self.__util.set_tag(uid=tag_id)
            self.__util.auth(auth_method=self.__rdr.auth_a, key=self.__tag_key)
            error = self.__util.do_auth(block_address=0)

        if not error:
            # We can now write the tag
            (error, data) = self.__rdr.read(block_address=3)
            if not error:
                i = 0
                # Fill in the new KEY A
                for _ in self.__tag_key:
                    data[i] = self.__tag_key[i]
                    i += 1

                i = 10
                # Set KEY B to a series of random bytes
                for _ in self.__tag_key:
                    data[i] = random.randint(0, 255)
                    i += 1

                logging.debug('writing new sector trailer: ' + str(data))
                error = self.__rdr.write(block_address=3, data=data)
                if error:
                    logging.error('failed to write sector trailer')

                self.__util.deauth()
                self.__rdr.stop_crypto()

                tag_id = self.scan_badge()
                if tag_id is None:
                    logging.error('error re-scanning badge')
                    return True

                self.__util.set_tag(tag_id)
                self.__util.auth(self.__rdr.auth_a, self.__tag_key)
                error = self.__util.do_auth(block_address=0)
                if error:
                    logging.error('error occurred re-authenticating the tag')
                    return True

                (error, newdata) = self.__rdr.read(block_address=3)
                if error:
                    logging.error('error reading back sector trailer')

                error = self.__rdr.write(block_address=1, data=badge_token_16_bytes)
                if error:
                    logging.error('error writing badge_id to block 1')
        else:
            logging.error('Failed to authenticate card: is MIFARE KEY A non-standard?')

        return error
