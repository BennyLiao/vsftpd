#!/bin/bash
# -*- coding: utf-8 -*-
# @Date    : 2018-01-11 16:38:34
# @Author  : benny (263997555@qq.com)
# @Link    : http://example.org
# @Version : 1.0


add_user(){
    local u=$1
    local p=$2
    local d=${3:-$u}

    # FTP项目主账户被设定为项目名称，即主账户名和项目目录名是一致的
    # 判断是不是FTP项目的主账户，是则确保FTP项目目录存在，不是则检查该用户的项目目录是否存在
    # 一个用户只能对一个FTP项目进行操作（管理员账户除外），一个FTP项目可以有多个用户来进行上传下载操作
    if [ "$u" == "$d" ]; then
        test -d /data/ftp/$d || { mkdir /data/ftp/$d;chown -R ftp.ftp /data/ftp/$d; }
    else
        test -d /data/ftp/$d || { echo "error: add user failed, user's project do not exist"; exit 1; }
    fi

    test -d /etc/vsftpd/vir_user_conf || mkdir /etc/vsftpd/vir_user_conf
    cat <<- EOF >/etc/vsftpd/vir_user_conf/$u
local_root=/data/ftp/$d
EOF
    if [ -e /etc/vsftpd/vsftpd.passwd ]; then
        sed -i "/$u/d" /etc/vsftpd/vsftpd.passwd 
        htpasswd -bd /etc/vsftpd/vsftpd.passwd "$u" "$p"
    else
        htpasswd -cbd /etc/vsftpd/vsftpd.passwd "$u" "$p"
    fi
}

add_admin_user(){
    local u=$1
    local p=$2

    if [ -e /etc/vsftpd/vsftpd.passwd ]; then
        sed -i "/$u/d" /etc/vsftpd/vsftpd.passwd
        htpasswd -bd /etc/vsftpd/vsftpd.passwd "$u" "$p"
    else
        htpasswd -cbd /etc/vsftpd/vsftpd.passwd "$u" "$p"
    fi
}

del_user(){
    local u=$1

    test -e /etc/vsftpd/vsftpd.passwd && sed -i "/$u/d" /etc/vsftpd/vsftpd.passwd
    rm -f /etc/vsftpd/vir_user_conf/$u
}

del_project(){
    local d=$1

    test -d data/ftp/$d && rm -rf /data/ftp/$d
    echo "delete /data/ftp/$d successfully"
}

vsftpd_stop(){
    echo "Received SIGINT or SIGTERM. Shutting down vsftpd"
    # Get PID
    pid=$(cat /var/run/vsftpd/vsftpd.pid)
    # Set TERM
    kill -SIGTERM "${pid}"
    # Wait for exit
    wait "${pid}"
    # All done.
    echo "Done"
}

vsftpd_start(){
     trap vsftpd_stop SIGINT SIGTERM
     ftp_root_dir=`awk -F= '/local_root/{print $2}' /etc/vsftpd.conf`
     test -d $ftp_root_dir && chown -R ftp.ftp $ftp_root_dir
     echo "Running vsftpd"
     vsftpd &
     pid="$!"
     echo "${pid}" > /var/run/vsftpd/vsftpd.pid
     wait "${pid}" && exit $?
}

usage(){
    cat <<- EOF
    $0 --adduser user password [project]      # 默认无需添加项目目录，只有为项目添加其他用户时，才需要指定用户所属项目
    $0 --addadminuser user password           # 添加超级管理员
    $0 --deluser user
    $0 --delproject project                   # 项目名即项目主账户名
EOF
    exit 0
}

main(){
    local act=$1
    case "$act" in
        vsftpd)
            vsftpd_start;;
        --adduser)
            shift 1
            add_user "$@";;
        --addadminuser)
            shift 1
            add_admin_user "$@";;
        --deluser)
            shift 1
            del_user "$@";;
        --delproject)
            shift 1
            del_project "$@";;
        help|--help|-h)
            usage;;
        *)
            exec "$@";;
    esac
}

main "$@"
