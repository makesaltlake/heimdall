import json
import logging
import os

import requests
import requests_cache


class HeimdallWebClient:

    def __init__(self, operating_mode):
        self.__allowed_badge_tokens = []

        if operating_mode == 'READER':
            self.reader_api_key = os.environ['READER_API_KEY']
            self.badge_token_url = 'https://msl-heimdall-dev.herokuapp.com/api/badge_readers/access_list'
            self.badge_scan_url = 'https://msl-heimdall-dev.herokuapp.com/api/badge_readers/record_scans'
            self.reader_headers = {'Content-Type': 'application/json',
                                   'Authorization': 'Bearer {0}'.format(self.reader_api_key)}

            requests_cache.install_cache(backend='memory', expire_after=300, old_data_on_error=True)
        else:
            self.writer_api_key = os.environ['WRITER_API_KEY']
            self.badge_program_url = 'https://msl-heimdall-dev.herokuapp.com/api/badge_writers/program'
            self.writer_headers = {'Content-Type': 'application/json',
                                   'Authorization': 'Bearer {0}'.format(self.writer_api_key)}

    def get_allowed_badge_tokens(self):
        return self.__allowed_badge_tokens

    def get_badge_list(self):
        response = requests.get(url=self.badge_token_url, headers=self.reader_headers)
        if response.ok:
            self.__allowed_badge_tokens = json.loads(response.content)['badge_tokens']
            logging.info('get_badge_list, content = ' + str(json.loads(response.content)))

        else:
            logging.info('Web API returned error ' + str(response.status_code))

        return response.ok

    def post_badge_scan(self, tag_id, badge_token, authorized, time_of_scan):

        badge_scan_info = {'scans': [{'badge_id': str(tag_id),
                                      'authorized': authorized,
                                      'badge_token': str(badge_token),
                                      'scanned_at': time_of_scan}]}

        response = requests.post(self.badge_scan_url, headers=self.reader_headers, json=badge_scan_info)
        logging.info('response: ' + str(response.content))
        return response.ok

    def post_programmed_badge(self, badge_token, time_of_scan):
        program_info = {'badge_token': str(badge_token),
                        'scanned_at:': str(time_of_scan)}
        response = requests.post(self.badge_program_url, headers=self.writer_headers, json=program_info)
        return response
