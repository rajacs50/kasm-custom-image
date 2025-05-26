FROM kasmweb/core-ubuntu-jammy:1.16.1
USER root

ENV HOME /home/kasm-default-profile
ENV STARTUPDIR /dockerstartup
ENV INST_SCRIPTS $STARTUPDIR/install
WORKDIR $HOME

######### Customize Container Here ###########

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

# Install MySQL 8.1.0 and configure it
RUN apt-get update && \
    apt-get install -y wget gnupg && \
    # Add MySQL GPG key directly to the trusted keyring
    wget -qO /usr/share/keyrings/mysql-archive-keyring.gpg https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 && \
    # Configure MySQL APT repository
    echo "deb [signed-by=/usr/share/keyrings/mysql-archive-keyring.gpg] http://repo.mysql.com/apt/ubuntu focal mysql-8.0" > /etc/apt/sources.list.d/mysql.list && \
    apt-get update && \
    # Install MySQL server
    DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server=8.1.0-1ubuntu20.04 && \
    # Configure MySQL
    echo "[mysqld]\nskip-host-cache\nskip-name-resolve\nbind-address=0.0.0.0" > /etc/mysql/mysql.conf.d/custom.cnf && \
    # Start MySQL service temporarily to configure root user
    service mysql start && \
    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'your_strong_password';" && \
    mysql -u root -e "FLUSH PRIVILEGES;" && \
    # Stop MySQL service after configuration
    service mysql stop && \
    # Clean up
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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
