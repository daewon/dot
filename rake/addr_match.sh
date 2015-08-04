for i in {33..42} ; do
  addr="sofia0$i.dakao.io"
  output=`nslookup $addr | grep Address | tail -n 1 | sed 's/Address: //g'`
  echo $addr

done
