FROM ubuntu:20.04

# Install Wine and dependencies
RUN dpkg --add-architecture i386 &&     apt-get update &&     apt-get install -y wine xvfb wget x11vnc &&     apt-get clean

WORKDIR /sandbox
CMD ["xvfb-run", "-a", "wine", "app.exe"]
