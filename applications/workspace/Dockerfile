# Employee Workspace - VS Code in Browser (code-server)
FROM codercom/code-server:latest

USER root

# Install development tools
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    vim \
    nano \
    sudo \
    python3 \
    python3-pip \
    nodejs \
    npm \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install additional tools
RUN pip3 install --no-cache-dir --break-system-packages \
    boto3 \
    requests \
    pylint \
    black

# Install global npm packages
RUN npm install -g \
    typescript \
    eslint \
    prettier \
    @aws-sdk/client-s3

# Create workspace directory
RUN mkdir -p /home/coder/workspace && chown -R coder:coder /home/coder/workspace

# Switch back to coder user
USER coder

# Install VS Code extensions
RUN code-server --install-extension ms-python.python && \
    code-server --install-extension dbaeumer.vscode-eslint && \
    code-server --install-extension esbenp.prettier-vscode && \
    code-server --install-extension eamodio.gitlens && \
    code-server --install-extension amazonwebservices.aws-toolkit-vscode

# Configure code-server
COPY --chown=coder:coder config.yaml /home/coder/.config/code-server/config.yaml

# Set working directory
WORKDIR /home/coder/workspace

# Expose port
EXPOSE 8080

# Create entrypoint script that sets password and starts code-server
# code-server reads PASSWORD from environment variable automatically
ENV PASSWORD=""

# Start code-server - it will use $PASSWORD env var for authentication
CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "password", "/home/coder/workspace"]
