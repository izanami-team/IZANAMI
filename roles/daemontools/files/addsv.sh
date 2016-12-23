#!/bin/sh
#
# http://blog.hansode.org/
#
# $0 <service name>
#

PATH=/bin:/usr/bin:/sbin:/usr/sbin
export PATH


#
# usage
#
usage() {
  cat <<EOS
usage:
  $0 <service name>

EOS
  exit 1
}



#
# main
#
[ $# = 1 ] || usage

svdir=/service
svname=$(basename $1)
acct_name=logadmin
acct_group=logadmin

[ -d ${svdir}  ] || usage
[ -z ${svname} ] && usage
[ -d ${svdir}/.${svname} ] && usage
id ${acct_name} 2>&1 >/dev/null || { echo "no such acct: ${acct_name}"; usage; }



# directory, file

mkdir    ${svdir}/.${svname}
chmod +t ${svdir}/.${svname}
mkdir    ${svdir}/.${svname}/log
mkdir    ${svdir}/.${svname}/log/main
touch    ${svdir}/.${svname}/log/status
chown ${acct_name}:${acct_group} ${svdir}/.${svname}/log/main
chown ${acct_name}:${acct_group} ${svdir}/.${svname}/log/status


# run script

cat <<EOS > ${svdir}/.${svname}/run
#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin
export PATH

exec 2>&1
sleep 3

EOS
chmod +x ${svdir}/.${svname}/run


cat <<EOS > ${svdir}/.${svname}/log/run
#!/bin/sh
exec setuidgid ${acct_name} multilog t s1000000 n100 ./main
EOS

chmod +x ${svdir}/.${svname}/log/run



exit 0
