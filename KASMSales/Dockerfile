FROM kasmweb/core-ubuntu-focal:1.15.0
USER root

ENV HOME /home/kasm-default-profile
ENV STARTUPDIR /dockerstartup
ENV INST_SCRIPTS $STARTUPDIR/install
WORKDIR $HOME

######### Customize Container Here ###########

# Install VSCode
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg \
    && install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg \
    && sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main"' | tee /etc/apt/sources.list.d/vscode.list \
    && apt-get update \
    && apt-get install -y apt-transport-https \
    && apt-get install -y code \
    # && sed -i "s|Exec=/usr/share/code/code %F|Exec=/usr/share/code/code --no-sandbox|g" /usr/share/applications/code.desktop \
    && cp /usr/share/applications/code.desktop $HOME/Desktop/ \
    && sed -i "s|Exec=/usr/share/code/code %F|Exec=/usr/share/code/code --no-sandbox|g" $HOME/Desktop/code.desktop \
    && chmod +x $HOME/Desktop/code.desktop \
    && chown 1000:1000 $HOME/Desktop/code.desktop \
    && rm -f packages.microsoft.gpg

# Install Firefox
RUN install -d -m 0755 /etc/apt/keyrings \
    && wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null \
    && gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") print "\nThe key fingerprint matches ("$0").\n"; else print "\nVerification failed: the fingerprint ("$0") does not match the expected one.\n"}' \
    && sh -c 'echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main"' | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null \
    && sh -c 'echo " \
    Package: * \
    Pin: origin packages.mozilla.org \
    Pin-Priority: 1000 \
    "' | sudo tee /etc/apt/preferences.d/mozilla \
    && apt-get update && sudo apt-get install -y firefox \
    && cp /usr/share/applications/firefox.desktop $HOME/Desktop/ \
    && chmod +x $HOME/Desktop/firefox.desktop \
    && chown 1000:1000 $HOME/Desktop/firefox.desktop

# Install JDK 17
RUN apt-get update \
    && apt-get install -y wget \
    && wget -O /tmp/openjdk-17_linux-x64_bin.tar.gz https://download.oracle.com/java/17/archive/jdk-17.0.12_linux-x64_bin.tar.gz \
    && mkdir -p /usr/local/java/jdk-17 \
    && tar -xzf /tmp/openjdk-17_linux-x64_bin.tar.gz -C /usr/local/java/jdk-17 --strip-components=1 \
    && update-alternatives --install /usr/bin/java java /usr/local/java/jdk-17/bin/java 1 \
    && update-alternatives --install /usr/bin/javac javac /usr/local/java/jdk-17/bin/javac 1 \
    && rm /tmp/openjdk-17_linux-x64_bin.tar.gz

# Install Maltego
RUN apt-get update \
    && wget https://downloads.maltego.com/maltego-v4/linux/Maltego.v4.7.0.deb \
    && apt-get install -y ./Maltego.v4.7.0.deb \
    && rm Maltego.v4.7.0.deb \
    && cp /usr/share/applications/maltego.desktop $HOME/Desktop/ \
    && chmod +x $HOME/Desktop/maltego.desktop \
    && chown 1000:1000 $HOME/Desktop/maltego.desktop

RUN mkdir -p $HOME/maltego/graphs/cti-graphs $HOME/maltego/graphs/gov-graphs
COPY cti-graphs $HOME/maltego/graphs/cti-graphs
COPY gov-graphs $HOME/maltego/graphs/gov-graphs

######### End Customizations ###########

RUN chown 1000:0 $HOME
RUN $STARTUPDIR/set_user_permission.sh $HOME

ENV HOME /home/kasm-user
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R 1000:0 $HOME

USER 1000