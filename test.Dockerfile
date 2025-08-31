# test.Dockerfile - Extends gateway.Dockerfile for testing
FROM mediapi/gateway:latest

# Install Bats for unit testing
# test.Dockerfile - Standalone test image with shunit2

# Install shunit2 for shell unit tests
RUN git clone https://github.com/kward/shunit2.git /opt/shunit2
RUN apt-get install -y --no-install-recommends curl
