#pragma once
#define PCB_LENGTH 5
#define PCB_STORAGE 5
#define PCB_INT_LENGTH 2


extern void SwitchImmediately();	//立即切换状态到当前进程块对应的进程
extern void BackKernal();	//回到控制台

void NextThread();
void DisposeThread();				//退出当前进程

//辅助函数
void CopyState();
void PasteState();
void MovePCB(int *src,int *tgt,int pcbIndex);


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

//缓存用变量
int tmp_state;
int tmp_ax,tmp_bx,tmp_cx,tmp_dx;
int tmp_si,tmp_di,tmp_bp,tmp_sp,tmp_ip,tmp_flags;
int tmp_cs,tmp_ds,tmp_es,tmp_ss,tmp_fs,tmp_gs;
int tmp_timercs,tmp_timerip;
int lock;

PCB pcb[PCB_LENGTH];
int freeHead = -1;
int readyHead = -1;
int currentPCB = -1;
int allowSwitch = 1;

void EnableSwitch(){
	if(allowSwitch>=1)
		allowSwitch = 1;
	else
		allowSwitch++;
}

void DisableSwitch(){
	allowSwitch--;
}

void InitPcb(){
	for(int i=1;i<PCB_LENGTH;i++){
		pcb[i].prev = i-1;
		pcb[i-1].next = i;
	}
	pcb[PCB_LENGTH-1].next = 0;
	pcb[0].prev = PCB_LENGTH-1;
	freeHead = 0;
}


int NewThread(int cs,int ip){
	DisableSwitch();
	pcb[freeHead].cs = cs;
	pcb[freeHead].ip = ip;
	pcb[freeHead].ss = cs;
	pcb[freeHead].sp = 0x100;
	pcb[freeHead].state = TS_NEW;
	
	MovePCB(&freeHead,&readyHead,freeHead);
	EnableSwitch();
	return readyHead;
}

void DisposeThread(){
	DisableSwitch();
	int next = pcb[currentPCB].next;
	
	MovePCB(&readyHead,&freeHead,currentPCB);

	if(readyHead != -1){
		currentPCB = next;
		PasteState();
		pcb[currentPCB].state = TS_RUNNING;
		SwitchImmediately();
	}else{
		BackKernal();
	}
	
	EnableSwitch();	//不会触发，但是保险起见
}

void NextThread(){
	DisableSwitch();
	if(currentPCB == -1){
		currentPCB = readyHead;
	}else{
		//切换PCB
		CopyState();
		currentPCB = pcb[currentPCB].next;
	}
		
	pcb[currentPCB].state = TS_RUNNING;
	PasteState();
	EnableSwitch();
}


void MovePCB(int *src,int *tgt,int pcbIndex){
	DisableSwitch();
	int next = pcb[pcbIndex].next;
	int prev = pcb[pcbIndex].prev;

	if(next != prev){
		pcb[prev].next = next;
		pcb[next].prev = prev;
		
		*src = next;
	}else{
		*src = -1;
	}
	
	if(*tgt != -1){
		next = pcb[*tgt].next;
		pcb[pcbIndex].next = next;
		pcb[pcbIndex].prev = *tgt;
		pcb[*tgt].next = pcbIndex;
		pcb[next].prev = pcbIndex;
	}else{
		pcb[pcbIndex].next = pcbIndex;
		pcb[pcbIndex].prev = pcbIndex;
	}
	*tgt = pcbIndex;
	EnableSwitch();
}

void CopyState(){
	DisableSwitch();
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
	EnableSwitch();
}

void PasteState(){
	DisableSwitch();
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
	EnableSwitch();
}