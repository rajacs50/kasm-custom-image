FROM kasmweb/core-ubuntu-focal:1.16.1
USER root

ENV HOME /home/kasm-default-profile
ENV STARTUPDIR /dockerstartup
ENV INST_SCRIPTS $STARTUPDIR/install
WORKDIR $HOME

######### Customize Container Here ###########

# Obsidian Package is AMD, so this file can only be used to create images that would run on that arch. For other arch, modify the file accordingly.

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

# Install Docker Engine
RUN apt-get update \
    && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
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

# Install Python 3.12
RUN apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y python3.12 python3.12-venv python3.12-dev

# Install Maltego-TRX
ENV VIRTUAL_ENV="$HOME/maltego/venv"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN apt-get update \
    && mkdir -p $HOME/maltego \
    && apt install python3.12-venv \
    && python3.12 -m venv $VIRTUAL_ENV \
    && . $VIRTUAL_ENV/bin/activate \
    && pip install --upgrade pip \
    && pip install maltego-trx

# Install OpenVPN
RUN apt-get update && \
    apt-get install -y openvpn

# Install Obsidian
RUN wget https://github.com/obsidianmd/obsidian-releases/releases/download/v1.8.10/obsidian_1.8.10_amd64.deb \
    && apt-get install -y ./obsidian_1.8.10_amd64.deb \
    && cp /usr/share/applications/obsidian.desktop $HOME/Desktop/ \
    && sed -i "s|Exec=/opt/Obsidian/obsidian %U|Exec=/usr/bin/obsidian --no-sandbox|g" $HOME/Desktop/obsidian.desktop \
    && chmod +x $HOME/Desktop/obsidian.desktop \
    && rm obsidian_1.8.10_amd64.deb

# Copy the qTDS Files
RUN mkdir -p $HOME/maltego/qtds
COPY qtds.zip $HOME/maltego/qtds
RUN apt-get update && apt-get install -y unzip \
    && unzip $HOME/maltego/qtds/qtds.zip -d $HOME/maltego/qtds/ \
    && rm $HOME/maltego/qtds/qtds.zip

# Install Maltego
RUN apt-get update \
    && wget https://downloads.maltego.com/maltego-v4/linux/Maltego.v4.9.1.deb \
    && apt-get install -y ./Maltego.v4.9.1.deb \
    && rm Maltego.v4.9.1.deb \
    && cp /usr/share/applications/maltego.desktop $HOME/Desktop/ \
    && chmod +x $HOME/Desktop/maltego.desktop \
    && chown 1000:1000 $HOME/Desktop/maltego.desktop

#Install Adminer
RUN apt-get update \
    && apt-get install -y adminer

#Install MySQL Database 8.1.0
# RUN apt-get update && apt-get install -y wget gnupg \
#     && wget -O mysql-apt-config.deb https://dev.mysql.com/get/mysql-apt-config_0.8.27-1_all.deb \
#     && dpkg -i mysql-apt-config.deb \
#     && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B7B3B788A8D3785C \
#     && apt-get update \
#     && apt-get install -y mysql-server-8.1 \
#     && mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'maltegotraining';" \
#     && mkdir -p /etc/mysql/conf.d \
#     && cp my.cnf /etc/mysql/conf.d/my.cnf

# Install MySQL 8.1.0 and configure it
# RUN apt-get update && \
#     apt-get install -y wget gnupg && \
#     # Add MySQL GPG key directly to the trusted keyring
#     wget -qO /usr/share/keyrings/mysql-archive-keyring.gpg https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 && \
#     # Configure MySQL APT repository
#     echo "deb [signed-by=/usr/share/keyrings/mysql-archive-keyring.gpg] http://repo.mysql.com/apt/ubuntu focal mysql-8.0" > /etc/apt/sources.list.d/mysql.list && \
#     apt-get update && \
#     # Install MySQL server
#     DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server=8.1.0-1ubuntu20.04 && \
#     # Configure MySQL
#     echo "[mysqld]\nskip-host-cache\nskip-name-resolve\nbind-address=0.0.0.0" > /etc/mysql/mysql.conf.d/custom.cnf && \
#     # Start MySQL service temporarily to configure root user
#     service mysql start && \
#     mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'your_strong_password';" && \
#     mysql -u root -e "FLUSH PRIVILEGES;" && \
#     # Stop MySQL service after configuration
#     service mysql stop && \
#     # Clean up
#     apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#Install MySQL Database 8.1.0
# Install MySQL Database 8.1.0
# RUN apt-get update && apt-get install -y wget gnupg mysql-server-8.0 \
#     && mysql -u root -p ='' -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'maltegotraining';" \
#     && mysql -u root --password='maltegotraining' -e "FLUSH PRIVILEGES;" \
#     && mkdir -p /etc/mysql/conf.d \
#     && cp my.cnf /etc/mysql/conf.d/my.cnf \
#     && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 3306

# Custom Desktop
COPY screensaver.png /usr/share/backgrounds/bg_default.png

# Training DB
RUN mkdir -p $HOME/maltego/trx_and_db
COPY trx_and_db $HOME/maltego/trx_and_db

######### End Customizations ###########
# Expose MySQL port
EXPOSE 3306

# Start MySQL on container startup
CMD ["mysqld"]

# Set Docker host environment variable
ENV DOCKER_HOST=unix:///var/run/docker.sock

RUN chown 1000:0 $HOME
RUN $STARTUPDIR/set_user_permission.sh $HOME

ENV HOME /home/kasm-user
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R 1000:0 $HOME

USER 1000
