#!/bin/sh
. $HOME/.bash_profile
 
if [ ! -f "ServersDetail.txt" ]; then
   touch "ServersDetail.txt"
else
   cat /dev/null >ServersDetail.txt
fi

#导出UBBCONFIG文件
tmunloadcf > UBBCONFIG_NOW
 
sed -n '/\*SERVERS/,/\*MODULES/p' UBBCONFIG_NOW > ServerName.txt
 
linenum=0
ServerFlag=0
 
while read ServerName
do
##从第一行开始读起
linenum=$(($linenum + 1))
 
   if [ $ServerFlag -eq 0 ];then
      #检查这行是否是服务名称的那行，如果是，那么返回值应该是1
      num1=$(echo $ServerName| grep SRVGRP |wc -l )
      if [ $num1 -eq 1 ];then
         #输出这行的第一列，并且去掉 双引号“，剩下的就是服务名称
         ResultServerName=$(echo $ServerName|awk '{print $1}'|sed 's/"//g')
                 ServerFlag=1
                 continue
      fi
        fi
   if [ $ServerFlag -eq 1 ];then
      lineflag=${linenum}"p"
          #取到 ”MIN=**“这部分
          numflag=$(echo $ServerName| grep "MIN=" |wc -l )
          if [ $numflag -eq 1 ];then
             #读取最小服务数
                 MinServerNum=$(echo ${ServerName#*MIN\=}|awk '{print $1}')
             #把服务名称和最小服务数输出到ServersDetail.txt文件中
         echo $ResultServerName $MinServerNum  >> ServersDetail.txt
 
             ##标识服务名、最小服务数都去到
             ServerFlag=0
           fi
   fi
done < ServerName.txt
 
#输出目前正在运行的服务
echo psr|tmadmin 2>&-|sed -e "/SHUTDOWN/d" -e "/^> $/d" -e "s/> //g" |awk '{print $1}' > RunningServer.txt
ErrCount=0
while read ServerName MinServerNum
do
        ServerName=${ServerName:0:14}
        num1=0
        num1=$(cat RunningServer.txt|grep $ServerName|wc -l)
        nowtime=`date +"%Y-%m-%d %H:%M:%S"`
        if [ "$num1" -lt "$MinServerNum" -a "$num1" -ne 0 ];then
           
           echo "$nowtime: Warn: ${ServerName} is less than the minimum value!"
           echo "$nowtime: Warn: ${ServerName} is less than the minimum value!" >>status.txt
           ErrCount=$(($ErrCount + 1))
           #tmboot -s $ServerName
           #sleep 10
           #tmboot -s $ServerName
           #sleep 10
        elif [ "$num1" -eq 0 ];then
           echo "$nowtime: Error:${ServerName} is down!"
           echo "$nowtime: Error:${ServerName} is down!" >>status.txt
           ErrCount=$(($ErrCount + 1))
        else
        	 echo "$nowtime: INFO:${ServerName} is ok!"
           echo "$nowtime: INFO:${ServerName} is ok!" >>status.txt
        fi
done < ServersDetail.txt

nowtime=`date +"%Y-%m-%d %H:%M:%S"`
if [ $ErrCount -eq 0 ];then
	echo "$nowtime: INFO:checked!The system is ready!"
	echo "$nowtime: INFO:checked!The system is ready!" >>status.txt
else
	echo "$nowtime: Error:checked!There are ${ErrCount} error servers!"
	echo "$nowtime: Error:checked!There are ${ErrCount} error servers!" >>status.txt
fi	


