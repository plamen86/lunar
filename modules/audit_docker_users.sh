# audit_docker_users
#
# Check users in docker group have recently logged in, if not lock them
# Warn of any users in group with UID greate than 100 and lock
#
# Refer to Section(s) 1.4 Page(s) 16-7 CIS Docker Benchmark 1.13.0
# Refer to https://docs.docker.com/articles/security/#docker-daemon-attack-surface
# Refer to https://www.andreas-jung.com/contents/on-docker-security-docker-group-considered-harmful
# Refer to http://www.projectatomic.io/blog/2015/08/why-we-dont-let-non-root-users-run-docker-in-centos-fedora-or-rhel/
#.

audit_docker_users () {
  if [ "$os_name" = "Linux" ]; then
    funct_verbose_message "Docker Users"
    check_file="/etc/group"
    if [ "$audit_mode" != 2 ]; then
      for user_name in `cat $check_file |grep '^$docker_group:' |cut -f4 -d: |sed 's/,/ /g'`; do
        last_login=`last -1 $user_name |grep '[a-z]' |awk '{print $1}'`
        if [ "$last_login" = "wtmp" ]; then
          lock_test=`cat /etc/shadow |grep '^$user_name:' |grep -v 'LK' |cut -f1 -d:`
          total=`expr $total + 1`
          if [ "$lock_test" = "$user_name" ]; then
            if [ "$audit_mode" = 1 ]; then
              insecure=`expr $insecure + 1`
              echo "Warning:   User $user_name in group $docker_group and has not logged in recently and their account is not locked [$insecure Warnings]"
            fi
            if [ "$audit_mode" = 0 ]; then
              funct_backup_file $check_file
              echo "Setting:   User $user_name to locked"
              passwd -l $user_name
            fi
          else
            secure=`expr $secure + 1`
            echo "Secure:    User $user_name in group $docker_group has not logged in recently and their account is locked [$secure Passes]"
          fi
        fi
      done
    else
      funct_restore_file $check_file $restore_dir
    fi
    if [ "$audit_mode" != 2 ]; then
      for user_name in `cat $check_file |grep '^$docker_group:' |cut -f4 -d: |sed 's/,/ /g'`; do
        user_id=`uid -u $user_name`
        if [ "$user_id" -gt "$max_super_user_id" ] ; then
          lock_test=`cat /etc/shadow |grep '^$user_name:' |grep -v 'LK' |cut -f1 -d:`
          total=`expr $total + 1`
          if [ "$lock_test" = "$user_name" ]; then
            if [ "$audit_mode" = 1 ]; then
              insecure=`expr $insecure + 1`
              echo "Warning:   User $user_name is in group $docker_group has and ID greater than $max_super_user_id and their account is not locked [$insecure Warnings]"
            fi
            if [ "$audit_mode" = 0 ]; then
              funct_backup_file $check_file
              echo "Setting:   User $user_name to locked"
              passwd -l $user_name
            fi
          else
            secure=`expr $secure + 1`
            echo "Secure:    User $user_name in group $docker_group has an id less than $max_super_user_id and their account is locked [$secure Passes]"
          fi
        fi
      done
    else
      funct_restore_file $check_file $restore_dir
    fi
  fi
}