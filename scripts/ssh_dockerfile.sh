ARG base_image_name
FROM ${base_image_name}

ARG user
ARG user_id
ARG home

RUN \
apt-get update && \
apt-get install -y sudo && \
apt-get install -y openssh-server

RUN \
useradd -u ${user_id} ${user} && \
usermod -aG sudo ${user}

# Necessary for ssh to container

RUN \
mkdir -p ${home}/.ssh && \
chmod 700 ${home}/.ssh

RUN \
sed 's/AuthorizedKeysFile.*//g' -i /etc/ssh/sshd_config && \
echo "AuthorizedKeysFile ${home}/.ssh/authorized_keys" >> /etc/ssh/sshd_config

RUN \
echo "${user} ALL=NOPASSWD: /usr/sbin/service ssh *" >> /etc/sudoers && \
echo "${user} ALL=NOPASSWD: /usr/bin/chmod *" >> /etc/sudoers

ENTRYPOINT \
sudo /usr/sbin/service ssh restart && \
sudo /usr/bin/chmod 600 "${home}/.ssh/*" && \
/bin/bash

# Necessary for connection with PyCharm

RUN \
mv /etc/bash.bashrc /etc/bash.bashrc_backup && \
touch /etc/bash.bashrc

RUN \
sed 's/Subsystem\s*sftp\s*.*//g' -i /etc/ssh/sshd_config && \
echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config

# Recommended by Docker for ssh (https://docs.docker.com/engine/examples/running_ssh_service/)

RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
