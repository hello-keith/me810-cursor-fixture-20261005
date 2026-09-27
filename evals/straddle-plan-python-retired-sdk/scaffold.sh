#!/usr/bin/env bash
set -euo pipefail
printf 'flask==3.0.3\nstraddle==0.5.0\n' > requirements.txt
printf 'from flask import Flask\napp = Flask(__name__)\n' > app.py
