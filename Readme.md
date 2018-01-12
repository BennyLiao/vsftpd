### git_repo: https://github.com/BennyLiao/vsftpd

方法1:
    docker pull benny1105/vsftpd
    docker run -itd --name vsftp -v /data/ftp/data:/data/ftp -v /data/ftp/conf:/etc/vsftpd -p 21:21 -p 28990-28999:28990-28999 benny1105/vsftpd
    # docker stop vsftp
    # docker start vsftp

方法2:
    docker-compose -p vsftp build --no-cache --force-rm
    docker-compose -p vsftp up -d
    # docker-compose stop
    # docker-compose start

FTP管理:
    docker exec vsftp /ftp.sh --addadminuser admin adminpassword           # create admin user
    docker exec vsftp /ftp.sh --adduser user1 user1password                # create user1
    docker exec vsftp /ftp.sh --adduser user1_2 user1_1password user1      # another user1_1, can visit user1's data too
    docker exec vsftp /ftp.sh --deluser user1                              # delete user1
    docker exec vsftp /ftp.sh --delproject user1                           # delete user1's ftp data
