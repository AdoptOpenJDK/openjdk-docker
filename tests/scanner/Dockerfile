# ------------------------------------------------------------------------------
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ------------------------------------------------------------------------------z
FROM python:3.7-alpine

COPY requirements.txt scanner.py /

# Install and Remove requirements.txt
RUN pip install -r requirements.txt && rm -f requirements.txt

# Create entrypoint for script
ENTRYPOINT ["/usr/local/bin/python", "scanner.py"]
