# Employee Workspace - Linux Desktop with noVNC (XFCE in Browser)
# Includes AD/SSSD integration for Active Directory authentication
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=employee
ENV PASSWORD=changeme
ENV VNC_RESOLUTION=1920x1080
ENV VNC_PORT=5901
ENV NOVNC_PORT=6080

# AD Domain settings (defaults, can be overridden)
ENV AD_DOMAIN=innovatech.local
ENV AD_REALM=INNOVATECH.LOCAL
ENV AD_ADMIN_USER=Admin
ENV AD_JOIN_OU=""

# Install desktop environment, VNC, and AD/SSSD packages
RUN apt-get update && apt-get install -y \
    # Desktop environment
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    tightvncserver \
    novnc \
    websockify \
    supervisor \
    sudo \
    curl \
    wget \
    git \
    vim \
    nano \
    # Browsers
    firefox \
    # Development tools
    python3 \
    python3-pip \
    nodejs \
    npm \
    htop \
    net-tools \
    dbus-x11 \
    xfonts-base \
    xfonts-100dpi \
    xfonts-75dpi \
    fonts-liberation \
    fonts-dejavu \
    # SSH/Network tools
    putty \
    putty-tools \
    openssh-client \
    # AWS CLI
    awscli \
    unzip \
    # Active Directory / SSSD packages
    sssd \
    sssd-ad \
    sssd-tools \
    realmd \
    adcli \
    krb5-user \
    samba-common-bin \
    packagekit \
    libnss-sss \
    libpam-sss \
    oddjob \
    oddjob-mkhomedir \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2 (more up-to-date than apt version)
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Pre-configure Kerberos (non-interactive)
RUN echo "krb5-config krb5-config/default_realm string ${AD_REALM}" | debconf-set-selections && \
    echo "krb5-config krb5-config/kerberos_servers string ${AD_DOMAIN}" | debconf-set-selections && \
    echo "krb5-config krb5-config/admin_server string ${AD_DOMAIN}" | debconf-set-selections

# Create fallback local user (used when AD is not available)
RUN useradd -m -s /bin/bash ${USER} && \
    echo "${USER}:${PASSWORD}" | chpasswd && \
    usermod -aG sudo ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Setup VNC
RUN mkdir -p /home/${USER}/.vnc && \
    echo '#!/bin/bash\nstartxfce4 &' > /home/${USER}/.vnc/xstartup && \
    chmod +x /home/${USER}/.vnc/xstartup && \
    chown -R ${USER}:${USER} /home/${USER}

# Copy SSSD configuration template
COPY sssd.conf.template /etc/sssd/sssd.conf.template

# Copy AD join script
COPY join-ad.sh /join-ad.sh
RUN chmod +x /join-ad.sh

# Create startup script with AD support
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# Create workspace directory
RUN mkdir -p /home/${USER}/workspace && chown -R ${USER}:${USER} /home/${USER}/workspace

WORKDIR /home/${USER}

EXPOSE 6080

CMD ["/startup.sh"]
