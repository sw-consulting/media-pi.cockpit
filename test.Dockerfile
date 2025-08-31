# test.Dockerfile - Extends gateway.Dockerfile for testing
FROM mediapi/gateway:latest

RUN apt-get install -y --no-install-recommends git curl

# Install shunit2 for shell unit tests
RUN git clone https://github.com/kward/shunit2.git /opt/shunit2
