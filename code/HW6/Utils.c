extern void Clear();
extern char GetChar();
extern void BackChar();
extern void PutChar(char ch);
extern void Printf(char* msg);
extern int Readline(int address,int offset,char *target);
extern void NextThread();
//返回读取后的偏移量

extern void Open(int offset,int count,int address);
extern void OpenAndJump(int offset,int count,int address);
//返回是否到达结尾

int strEqual(char *a,char *b);
int Int2Str(int org,char* target,int maxLength);		//返回转换的数的长度
int NewThread(int cs,int ip);
int DisposeThread(int index);

#define PCB_LENGTH 5
#define PCB_STORAGE 5
#define PCB_INT_LENGTH 2

const int TS_NEW = 0;
const int TS_BLOCKED = 1;
const int TS_RUNNING = 2;

typedef struct{
	long cs,ip,flags;
	int next,prev,state;
	int ax,bx,cx,dx,si,di,bp,sp,ds,es,ss,fs,gs;
	int timercs;
	int timerip;
}PCB;

PCB pcb[PCB_LENGTH];

int freeHead = -1;
int readyHead = -1;
int currentPCB = -1;
//缓存用变量
int tmp_state;
int tmp_ax,tmp_bx,tmp_cx,tmp_dx;
int tmp_si,tmp_di,tmp_bp,tmp_sp,tmp_ip,tmp_flags;
int tmp_cs,tmp_ds,tmp_es,tmp_ss,tmp_fs,tmp_gs;
int tmp_timercs,tmp_timerip;


int InitPcb(){
	freeHead = 0;
	for(int i=1;i<PCB_LENGTH;i++){
		pcb[i].prev = i-1;
		pcb[i-1].next = i;
	}
	pcb[PCB_LENGTH-1].next = 0;
	pcb[0].prev = PCB_LENGTH-1;
}

int NewThread(int cs,int ip){
	pcb[freeHead].cs = cs;
	pcb[freeHead].ip = ip;
	//不太好的用户栈
	pcb[freeHead].ss = cs;
	pcb[freeHead].sp = 0xfff0;
	pcb[freeHead].state = TS_NEW;
	
	int next = pcb[freeHead].next;
	int prev = pcb[freeHead].prev;
	int temp = freeHead;
	pcb[next].prev = prev;
	pcb[prev].next = next;
	freeHead = next;
	
	if(readyHead == -1){
		pcb[temp].next = temp;
		pcb[temp].prev = temp;
	}else{
		next = pcb[readyHead].next;
		prev = pcb[readyHead].prev;
		pcb[next].prev = temp;
		pcb[prev].next = temp;
		
		pcb[temp].next = next;
		pcb[temp].prev = readyHead;
	}
	readyHead = temp;
	

	return readyHead;
}

int DisposeThread(int index){
	int next = pcb[readyHead].next;
	int prev = pcb[readyHead].prev;
	
	//进程数是否为空
	if(next == prev){
		readyHead = -1;
		return -1;
	}
	
	pcb[next].prev = pcb[readyHead].prev;
	pcb[prev].next = pcb[readyHead].next;
	readyHead = next;
	
	next = pcb[freeHead].next;
	prev = pcb[freeHead].prev;
	pcb[next].prev = index;
	pcb[prev].next = index;
	freeHead = index;
	
	return readyHead;
}

void NextThread(){
	//保存之前的寄存器状态
	if(currentPCB == -1){
		currentPCB = readyHead;
	}else{
		//切换PCB
		pcb[currentPCB].ax = tmp_ax;
		pcb[currentPCB].bx = tmp_bx;
		pcb[currentPCB].cx = tmp_cx;
		pcb[currentPCB].dx = tmp_dx;
		pcb[currentPCB].si = tmp_si;
		pcb[currentPCB].di = tmp_di;
		pcb[currentPCB].bp = tmp_bp;
		pcb[currentPCB].sp = tmp_sp;
		pcb[currentPCB].ip = tmp_ip;
		pcb[currentPCB].cs = tmp_cs;
		pcb[currentPCB].ds = tmp_ds;
		pcb[currentPCB].es = tmp_es;
		pcb[currentPCB].ss = tmp_ss;
		pcb[currentPCB].fs = tmp_fs;
		pcb[currentPCB].gs = tmp_gs;
		pcb[currentPCB].flags = tmp_flags;
		pcb[currentPCB].state = TS_BLOCKED;
		pcb[currentPCB].timercs = tmp_timercs;
		pcb[currentPCB].timerip = tmp_timerip;
		currentPCB = pcb[currentPCB].next;
	}
		
	pcb[currentPCB].state = TS_RUNNING;
	
	//将PCB内状态赋予临时变量共汇编恢复
	tmp_ax = pcb[currentPCB].ax;
	tmp_bx = pcb[currentPCB].bx;
	tmp_cx = pcb[currentPCB].cx;
	tmp_dx = pcb[currentPCB].dx;
	tmp_si = pcb[currentPCB].si;
	tmp_di = pcb[currentPCB].di;
	tmp_bp = pcb[currentPCB].bp;
	tmp_sp = pcb[currentPCB].sp;
	tmp_ds = pcb[currentPCB].ds;
	tmp_es = pcb[currentPCB].es;
	tmp_ss = pcb[currentPCB].ss;
	tmp_fs = pcb[currentPCB].fs;
	tmp_gs = pcb[currentPCB].gs;
	tmp_ip = pcb[currentPCB].ip;
	tmp_cs = pcb[currentPCB].cs;
	tmp_flags = pcb[currentPCB].flags;
	tmp_state = pcb[currentPCB].state;
	tmp_timercs = pcb[currentPCB].timercs;
	tmp_timerip = pcb[currentPCB].timerip;
}

int strEqual(char *a,char *b){
	int i = 0;
	while(a[i]!='\0' && b[i]!='\0'){
		if(a[i]!=b[i]) return 0;
		i++;
	}
	
	return a[i]==b[i];
}

int Int2Str(int org,char* target,int maxLength){
	int length = 0,copy = org;
	if(org==0){
		target[0]='0';
		target[1]='\0';
		return 1;
	}
	
	while(copy){
		copy/=10;
		length++;
		if(length>=maxLength)
			return maxLength;
	}
	target[length] = '\0';
	while(org){
		length--;
		copy++;
		target[length] = '0' + (org%10);
		org/=10;
	}
	
	return copy>0 ? copy : 1;
}

void StrCopy(char *src,char *tgt){
	while(*tgt!='\0'){
		*src = *tgt;
		src++;
		tgt++;
	}
}