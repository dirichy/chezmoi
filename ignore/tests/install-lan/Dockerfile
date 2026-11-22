FROM archlinux:base AS base
# No paru/chezmoi/gopass/Mihomo/Git is preinstalled on the new device.
# Python is a fixture driver; curl, sudo and CA certificates are prerequisites.
RUN pacman -Syu --needed --noconfirm python curl sudo ca-certificates \
    && useradd --create-home --user-group --uid 1000 tester \
    && printf 'tester ALL=(ALL) NOPASSWD: ALL\nDefaults env_keep += "http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY no_proxy NO_PROXY"\n' > /etc/sudoers.d/fixture \
    && chmod 440 /etc/sudoers.d/fixture
COPY . /fixture

FROM base AS old
RUN pacman -S --needed --noconfirm openssh gnupg gopass git \
    && ssh-keygen -A \
    && mkdir -p /run/sshd
ENTRYPOINT ["bash", "/fixture/old-device.sh"]

FROM base AS new
USER tester
WORKDIR /home/tester
CMD ["sleep", "infinity"]
