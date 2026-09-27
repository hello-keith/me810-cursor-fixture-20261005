#!/usr/bin/env bash
set -euo pipefail
printf 'flask==3.0.3\n' > requirements.txt
printf 'from flask import Flask\napp = Flask(__name__)\n' > app.py
