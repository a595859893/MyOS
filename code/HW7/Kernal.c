#pragma once
#include "Utils.c"

#define CMD_BUFFER_LEN 50
#define CMD_COMMAND_NUM 3
#define CMD_COMMAND_MAXLENGTH 10
#define CMD_BATCH_NAMELENGTH 15
#define CMD_HISTORY_LENGTH 20

#define KEY_UP 0x48
#define KEY_DOWN 0x50
#define KEY_LEFT 0x4b
#define KEY_RIGHT 0x4d

extern int GetFileInfo(int fileIndex,char* name,int *sector,int *size,int *time,int *type);
extern void RevalInt();
extern void SetInt();
extern void CallSysInt(int number);
extern void PutChar(char ch);
extern void UpdateCursor();
extern void Printf(char* msg);

int CheckCommand(char *cmd,int end);
void AutoCompelete();

void FillCmdBuffer(const char *fillstr,int offset);
void InsertCmdBuffer(const char ch);
void ClearCmdBuffer();
void EraseCmdBuffer();
void MoveForwardCur(int offset);
void MoveBackCur(int offset,int delete);

void LoadBatch();
void ReadBatch(int batchBuffer);
void FileInfo(char *fileName,int position,int size,int time,int type);
void FileList();
int MultiTest(char *cmd,int *start,int end);

int PrintInt(int i);

int batchBuffer = 0x7F00;
int fileInfoList = 0x7C00;

int screenCusor = 0;

char cmdBuffer[CMD_HISTORY_LENGTH][CMD_BUFFER_LEN + 1];
int cmdCur = 0;
int cmdMaxCur = 0;
int cmdIndex = 0;
int cmdMaxIndex = 0;

int batchSize[CMD_COMMAND_MAXLENGTH] = {};
int batchPos[CMD_COMMAND_MAXLENGTH] = {};
int orderLen = 7;

char orderList[CMD_BATCH_NAMELENGTH][CMD_COMMAND_MAXLENGTH] = {
	"clear",
	"filelist",
	"pong",
	"int1",
	"int2",
	"int3",
	"int4",
};

void CommandOn(){
	//初始化PCB块
	InitPcb();
	//为内核绑定线程
	BindKernal();
	
	//载入文件信息
	Open(73,1,fileInfoList);
	//载入可执行batch信息
	LoadBatch();
	
	Clear();
	// cmdCur = 0;
	// cmdMaxCur = 0;
	cmdBuffer[0][0] = '\0';
	Printf("Welcome to WengOS!\n");
	Printf("Command Avalible: clear, pong, filelist, int33, int34, int35, int36\n");
	Printf("You can type Tab to autocomplete command\n");
	Printf(">>");
}

void CommandKeyPress(char key){
	switch(key){
		case '\r':
			cmdBuffer[cmdMaxIndex][cmdMaxCur+1] = '\0';
		
			if(cmdMaxIndex==cmdIndex) cmdIndex++;
			cmdMaxIndex++;
			
			Printf("\n");
			CheckCommand(cmdBuffer[cmdMaxIndex-1],cmdMaxCur);
			cmdCur = 0;
			cmdMaxCur = 0;
			
			Printf(">>");
			UpdateCursor();

			break;
		case '\t':
			AutoCompelete();
			break;
		case '\b':
			if(cmdCur>0)EraseCmdBuffer();
			break;
		default:
			if(cmdCur<CMD_BUFFER_LEN) InsertCmdBuffer(key);
			break;
	}
}

void CommandCortorlKeyPress(char key){
	switch(key){
		case KEY_UP:
			if(cmdIndex>0){
				cmdIndex--;
				ClearCmdBuffer();
				FillCmdBuffer(cmdBuffer[cmdIndex],0);
			}
			break;
		case KEY_DOWN:
			if(cmdIndex<cmdMaxIndex){
				cmdIndex++;
				ClearCmdBuffer();
				FillCmdBuffer(cmdBuffer[cmdIndex],0);
			}
			break;
		case KEY_LEFT:
			MoveBackCur(1,0);
			break;
		case KEY_RIGHT:
			MoveForwardCur(1);
			break;
	}
}

void FillCmdBuffer(const char *fillstr,int offset){
	while(fillstr[offset] != '\0'){
		InsertCmdBuffer(fillstr[offset]);
		offset++;
	}
}

void InsertCmdBuffer(const char ch){
	screenCusor += (cmdMaxCur-cmdCur+1)*2;
	for(int i=cmdMaxCur;i>=cmdCur;i--){
		cmdBuffer[cmdMaxIndex][i] = cmdBuffer[cmdMaxIndex][i-1];
		screenCusor-=2;
		PutChar(cmdBuffer[cmdMaxIndex][i]);
	}
	
	cmdBuffer[cmdMaxIndex][cmdCur] = ch;
	cmdMaxCur++;
	cmdCur++;
	PutChar(ch);
	screenCusor+=2;
	UpdateCursor();
}

void EraseCmdBuffer(){
	if(cmdCur<=0)
		return;
	
	screenCusor-=2;
	int curBuf = screenCusor;
	for(int i=cmdCur-1;i<cmdMaxCur;i++){
		cmdBuffer[cmdMaxIndex][i] = cmdBuffer[cmdMaxIndex][i+1];
		PutChar(cmdBuffer[cmdMaxIndex][i]);
		screenCusor+=2;
	}
	PutChar(' ');
	cmdMaxCur--;
	cmdCur--;
	
	screenCusor = curBuf;
	UpdateCursor();
}

void MoveForwardCur(int offset){
	offset = offset >= cmdMaxCur-cmdCur ? cmdMaxCur-cmdCur: offset;
	cmdCur += offset;
	screenCusor += offset*2;
	UpdateCursor();
}

void MoveBackCur(int offset,int delete){
	offset = offset >= cmdCur ? cmdCur : offset;
	if(delete){
		for(int i = 0;i<offset;i++) EraseCmdBuffer();
	}else{
		screenCusor -= offset*2;
		cmdCur -= offset;
		UpdateCursor();
	}
}

void ClearCmdBuffer(){
	MoveBackCur(cmdMaxCur,1);
}

int orderIndex[CMD_COMMAND_MAXLENGTH];
void AutoCompelete(){
	int length=0,current=0,start=0;
	
	for(int i =0;i<cmdCur;i++){
		if(cmdBuffer[cmdMaxIndex][i] == ' ')
			start = i + 1;
	}
	
	for(int i =0;i<orderLen;i++){
		if(cmdBuffer[cmdMaxIndex][current + start] == orderList[i][current]){
			orderIndex[length] = i;
			length++;
		}
	}
	
	while(length){
		current++;
		if((current + start)>=cmdCur){
			if(length>0)
				FillCmdBuffer(orderList[orderIndex[0]]+current-1,current);
			return;
		}else{
			for(int i =0;i<length;i++){
				if(cmdBuffer[cmdMaxIndex][current + start] != orderList[orderIndex[i]][current]){
					length--;
					orderIndex[i] = orderIndex[length];
					i--;
				}
			}
		}
	}

	return;
}


int CommandMatch(char *cmd,int *start,int end){
	int length=0,current=0;
	
	for(int i =0;i<CMD_COMMAND_MAXLENGTH;i++){
		if(cmd[*start] == orderList[i][0]){
			orderIndex[length] = i;
			length++;
		}
	}

	while(length){
		current++;
		if((cmd[current + *start]==' ') || ((current + *start)>=end)){
			*start += current + 1;
			for(int i =0;i<length;i++){
				if(orderList[orderIndex[i]][current] == '\0'){
					return orderIndex[i];
				}
			}
			return -1;
		}else{
			for(int i =0;i<length;i++){
				if(cmd[current + *start] != orderList[orderIndex[i]][current]){
					length--;
					orderIndex[i] = orderIndex[length];
					i--;
				}
			}
		}
	}
	
	return -1;
}

int CheckCommand(char *cmd,int end){
	int start=0,cmdId=-1;

	while(start<end){
		cmdId = CommandMatch(cmd,&start,end);
		switch(cmdId){
			case -1:
				Printf( "Wrong order!\n");
				return -1;
			case 0://clear
				Clear();
				break;
			case 1://filelist
				FileList();
				break;
			case 2://pong
				if(MultiTest(cmd,&start,end) == -1){
					Printf( "Wrong order!\n");
					return -1;
				}
				break;
			case 3:
				CallSysInt(2);
				break;
			case 4:
				CallSysInt(3);
				break;
			case 5:
				CallSysInt(4);
				break;
			case 6:
				CallSysInt(5);
				break;
			default:
				Open(batchPos[cmdId]+1,batchSize[cmdId],batchBuffer);
				ReadBatch(batchBuffer);
				break;
		}
	}

	return cmdId;
}

void ReadBatch(int batchBuffer){
	char tempBuffer[CMD_BUFFER_LEN];
	int current=0;
	int prev = 0;
	while(1){
		prev = current;
		current = Readline(batchBuffer,current,tempBuffer);
		if(tempBuffer[0] == '\0'){
			break;
		}else{
			char *start = tempBuffer;
			while(*start == ' ') start++;
			if(!CheckCommand(start,current-prev)){
				return;
			}
		}
	}
}

void LoadBatch(){
	char name[8] = "";
	int time,type;
	int index = 0;
	while(1){
		if(GetFileInfo(index,orderList[orderLen],&batchPos[orderLen],&batchSize[orderLen],&time,&type)){
			index++;
			if(type==3) orderLen++;
		}else{
			break;
		}
	}
}

void FileList(){
	Printf("-------------------------------------------\n");
	Printf("|FileName |Position  |Size  |Time  |Type  |\n");
	Printf("-------------------------------------------\n");
	char name[CMD_BATCH_NAMELENGTH] = "";
	int sector,size,time,type;
	int index = 0;
	while(1){
		if(GetFileInfo(index,name,&sector,&size,&time,&type)){
			FileInfo(name,sector,size,time,type);
			index++;
		}else{
			break;
		}
	}
}

void FileInfo(char *fileName,int position,int size,int time,int type){
	char temp[10] = "";
	int len = 0;
	
	Printf("|");
	Printf(fileName);
	
	Printf("  |");
	
	len = 10 - PrintInt(position);
	while(len--)Printf(" ");
		
	Printf("|");
	len = 6 - PrintInt(size);
	while(len--)Printf(" ");
	
	Printf("|");
	len = 6 - PrintInt(time);
	Printf(temp);
	while(len--)Printf(" ");
	
	Printf("|");
	len = 6 - PrintInt(type);
	while(len--)Printf(" ");
	
	Printf("|");
	Printf("\n-------------------------------------------\n");
}

int MultiTest(char *cmd,int *start,int end){
	int current = 0;
	int hasThread = 0;
	int startIndex[4] = {0};

	//不知道为何声明数组的初始化无校，故用语句循环再初始化一遍
	for(int i=0;i<4;i++) startIndex[i] = 0;

	while(1){
		if((current + *start)>=end) return -1;
		
		char letter = cmd[current + *start];
		if(letter>='1' && letter<='4'){
			startIndex[letter - '1'] = 1;
			hasThread = 1;
		}else if(letter != ' '){
			return -1;
		}
		current++;
		
		if((*start + current)>=end || letter==' '){
			if(hasThread){
				DisableSwitch();
				*start += current + 1;
				for(int i=0;i<4;i++){
					if(startIndex[i]){
						int pid = fork();
						Printf("pid:");
						PrintInt(pid);
						Printf("\n");
						
						if(pid == 0){
							int pageIndex = GetCurrentPCB()->pageIndex;
							Printf("page:");
							PrintInt(pageIndex);
							Printf("\n");
							OpenAndJump(75+i*2,2,pagePos[pageIndex]);
						}
					}
				}
				EnableSwitch();
				return 1;
			}
			return 0;
		}
		
	}
}


int PrintInt(int i){
	char temp[10] = "";
	int len = Int2Str(i,temp,10); 
	Printf(temp);
	
	return len;
}