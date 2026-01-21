#!/usr/bin/env python3
"""
Simple static server for serving Flutter `build/web` output.
Usage:
  python testServer.py --dir build/web --host 127.0.0.1 --port 8080 --open

Features:
- Serves files from specified directory
- If requested path is not found, serves index.html (SPA fallback)
- Uses a threaded server
- Optional --open will open the default browser to the server URL
"""

import argparse
import http.server
import socketserver
import os
import sys
import webbrowser
import logging
from pathlib import Path

logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')

class SPARequestHandler(http.server.SimpleHTTPRequestHandler):
    # SimpleHTTPRequestHandler in Python3.7+ accepts directory parameter
    def __init__(self, *args, directory=None, url_prefix='/', **kwargs):
        # url_prefix should start with '/' and not end with '/'
        self.url_prefix = url_prefix if url_prefix else '/'
        if not self.url_prefix.startswith('/'):
            self.url_prefix = '/' + self.url_prefix
        if self.url_prefix != '/' and self.url_prefix.endswith('/'):
            self.url_prefix = self.url_prefix[:-1]
        super().__init__(*args, directory=directory, **kwargs)

    def log_message(self, format, *args):
        logging.info("%s - %s" % (self.address_string(), format % args))

    def send_head(self):
        """Return file handle for GET/HEAD. If file not found, fallback to index.html for SPA."""
        # If a url_prefix is set (e.g. '/gametest'), strip it before mapping to filesystem
        request_path = self.path
        if self.url_prefix != '/' and request_path.startswith(self.url_prefix):
            # strip the prefix; keep leading '/'
            stripped = request_path[len(self.url_prefix):]
            if stripped == '':
                stripped = '/'
            request_path = stripped
        # Update self.path so that super().send_head will use the stripped path
        self.path = request_path
        path = self.translate_path(self.path)

        if os.path.isdir(path):
            # if directory, let parent handle (will look for index.html)
            for index in ("index.html", "index.htm"):
                index_path = os.path.join(path, index)
                if os.path.exists(index_path):
                    # serve the directory index (self.path already set to request_path)
                    return super().send_head()
            # no index found -> delegate to super to possibly listdir (or 404)
            return super().send_head()

        if os.path.exists(path):
            return super().send_head()

        # Not a static file - fallback to index.html if available (SPA)
        index_file = os.path.join(self.directory, 'index.html')
        if os.path.exists(index_file):
            logging.debug('Fallback to index.html for path: %s', self.path)
            # Serve index.html
            # ensure the handler serves the root index.html (mapped), but keep original request path in logs
            self.path = '/index.html'
            return super().send_head()

        return super().send_head()


def serve(directory: str, host: str, port: int, open_browser: bool, url_prefix: str):
    directory = os.path.abspath(directory)
    if not os.path.exists(directory):
        logging.error('Directory does not exist: %s', directory)
        sys.exit(2)

    index = os.path.join(directory, 'index.html')
    if not os.path.exists(index):
        logging.warning('index.html not found in %s. SPA apps usually require index.html', directory)

    handler_cls = SPARequestHandler

    try:
        # Pass url_prefix into handler instances via the factory lambda
        with socketserver.ThreadingTCPServer((host, port), lambda *args, **kwargs: handler_cls(*args, directory=directory, url_prefix=url_prefix, **kwargs)) as httpd:
            sa = httpd.socket.getsockname()
            url = f'http://{sa[0]}:{sa[1]}/'
            logging.info('Serving %s at %s', directory, url)
            if open_browser:
                try:
                    webbrowser.open(url)
                except Exception as e:
                    logging.warning('Failed to open browser: %s', e)
            try:
                httpd.serve_forever()
            except KeyboardInterrupt:
                logging.info('Shutting down server...')
                httpd.shutdown()
    except OSError as e:
        logging.error('Failed to start server: %s', e)
        sys.exit(1)

#  python e:\test\GiftGame\testServer.py --dir build/web --host 127.0.0.1 --port 8081 --url-prefix /gametest --open
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Serve a directory (default: build/web) with SPA fallback')
    parser.add_argument('--dir', default='build/web', help='Directory to serve (default: build/web)')
    parser.add_argument('--host', default='0.0.0.0', help='Host to bind (default: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=8080, help='Port to bind (default: 8080)')
    parser.add_argument('--open', action='store_true', help='Open the default browser after server starts')
    parser.add_argument('--url-prefix', default='/', help='URL prefix to strip before looking up files (e.g. /gametest)')

    args = parser.parse_args()
    serve(args.dir, args.host, args.port, args.open, url_prefix=args.url_prefix)
