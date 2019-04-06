__asm__(".code16gcc\n");

#include "Utils.c"
extern int GetFileInfo(int fileIndex,char* name,int *sector,int *size,int *time,int *type);
extern void RevalInt();
extern void SetInt();
extern void CallInt33();
extern void CallInt34();
extern void CallInt35();
extern void CallInt36();

int CheckCommand(char *cmd,int end);
void AutoCompelete(char *cmd);
void ReadBatch(int batchBuffer);
void FileInfo(char *fileName,int position,int size,int time,int type);
void LoadBatch();
void FileList();
void Pong();

int batchBuffer = 0x7F00;
int fileInfoList = 0x7C00;
int pagePos = 0xF000;

#define CMD_BUFFER_LEN 50
#define CMD_COMMAND_NUM 3
#define CMD_COMMAND_MAXLENGTH 10
#define CMD_BATCH_NAMELENGTH 10
int screenCusor = 0;
int cmdCurrent = 0;
char cmdBuffer[CMD_BUFFER_LEN + 1] = "";
int batchSize[CMD_COMMAND_MAXLENGTH] = {};
int batchPos[CMD_COMMAND_MAXLENGTH] = {};
char orderList[CMD_BATCH_NAMELENGTH][CMD_COMMAND_MAXLENGTH] = {
	"clear",
	"filelist",
	"pong",
	"int33",
	"int34",
	"int35",
	"int36"
};
int orderLen = 7;

void CommandOn(){
	//载入文件信息
	Open(1,1,1,fileInfoList);
	//载入可执行batch信息
	LoadBatch();

	cmdCurrent = 0;
	Clear();
	Printf("Welcome to WengOS!\n");
	Printf("Command Avalible: clear, pong, filelist\n");
	Printf("You can type Tab to autocomplete command\n");
	Printf(">>");
}

void CommandKeyPress(char key){
	cmdBuffer[cmdCurrent] = key;
	switch(cmdBuffer[cmdCurrent]){
		case '\r':
			cmdBuffer[cmdCurrent] = '\0';
			Printf("\n");
			CheckCommand(cmdBuffer,cmdCurrent);
			cmdCurrent = 0;
			Printf(">>");
			break;
		case '\t':
			AutoCompelete(cmdBuffer);
			break;
		case '\b':
			if(cmdCurrent>0){
				BackChar();
				cmdCurrent--;
			}
			break;
		default:
			if(cmdCurrent<CMD_BUFFER_LEN){
				PutChar(cmdBuffer[cmdCurrent]);
				cmdCurrent++;
			}
			break;
	}
}

int orderIndex[CMD_COMMAND_MAXLENGTH];
int CommandMatch(char *cmd,int *start,int end){
	int length=0,current=0;
	
	for(int i =0;i<CMD_COMMAND_MAXLENGTH;i++){
		if(cmd[current + *start] == orderList[i][current]){
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

void AutoCompelete(char *cmd){
	int length=0,current=0,start=0;
	
	for(int i =0;i<cmdCurrent;i++){
		if(cmd[current + i] == ' '){
			start = i+1;
		}
	}
	
	for(int i =0;i<orderLen;i++){
		if(cmd[current + start] == orderList[i][current]){
			orderIndex[length] = i;		
			length++;
		}
	}
	
	while(length){
		current++;
		if((current + start)>=cmdCurrent){
			if(length>0){
				while(orderList[orderIndex[0]][current] != '\0'){
					cmd[current + start] = orderList[orderIndex[0]][current];
					PutChar(cmdBuffer[cmdCurrent]);
					cmdCurrent++;
					current++;
				}
			}
			return;
		}else{
			for(int i =0;i<length;i++){
				if(cmd[current + start] != orderList[orderIndex[i]][current]){
					length--;
					orderIndex[i] = orderIndex[length];
					i--;
				}
			}
		}
	}

	return;
}

int CheckCommand(char *cmd,int end){
	int start = 0,cmdId=-1;
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
				Pong();
				break;
			case 3://int33
				CallInt33();
				break;
			case 4://int34
				CallInt34();
				break;
			case 5://int35
				CallInt35();
				break;
			case 6://int36
				CallInt36();
				break;
			default:
				Open(batchPos[cmdId]%18+1,batchPos[cmdId]/18,batchSize[cmdId],batchBuffer);
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
			if(type==3){
				orderLen++;
			}
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
	len = 10-Int2Str(position,temp,10); 
	Printf(temp);
	while(len--)PutChar(' ');
		
	PutChar('|');
	len = 6-Int2Str(size,temp,6); 
	Printf(temp);
	while(len--)PutChar(' ');
	
	PutChar('|');
	len = 6-Int2Str(time,temp,6); 
	Printf(temp);
	while(len--)PutChar(' ');
	
	PutChar('|');
	len = 6-Int2Str(type,temp,6); 
	Printf(temp);
	while(len--)PutChar(' ');
	
	PutChar('|');
	Printf("\n-------------------------------------------\n");
}

void Pong(){
	Clear();
	RevalInt();
	OpenAndJump(2,1,2,pagePos);
	SetInt();
	Clear();
}