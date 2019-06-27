#pragma once

extern void SwitchImmediately();	//立即切换状态到当前进程块对应的进程
extern void BackKernal();	//回到控制台
extern int ForkPrepare(int tgt_ss);	//拷贝栈和寄存器

void NextThread();
void DisposeThread();				//退出当前进程
int fork();
void wait();
void exit();

int PrintInt(int i);
void Printf(char *msg);

//辅助函数
void CopyState(int pcbIndex);
void PasteState();
void MovePCB(int *src,int *tgt,int pcbIndex);
int NewThread();


const int TS_NEW = 0;
const int TS_BLOCKED = 1;
const int TS_RUNNING = 2;

typedef struct{
	long cs,ip,flags;
	int next,prev,state;
	int ax,bx,cx,dx,si,di,bp,sp,ds,es,ss,fs,gs;
	int timercs,timerip;
	int pageIndex,parentPID,signal;
}PCB;

//缓存用变量
int tmp_state;
int tmp_ax,tmp_bx,tmp_cx,tmp_dx;
int tmp_si,tmp_di,tmp_bp,tmp_sp,tmp_ip,tmp_flags;
int tmp_cs,tmp_ds,tmp_es,tmp_ss,tmp_fs,tmp_gs;
int tmp_timercs,tmp_timerip;
int tmp_pageIndex;
int lock;


//固定分页
#define KERNAL_BASE 0x8000
#define PAGE_BASE 0xD000;
#define PAGE_OFFSET 0x0200;
#define PAGE_NUM 8
#define PAGE_UNUSED 0
#define PAGE_USED 1
int pagePos[PAGE_NUM];
int pageUsage[PAGE_NUM];

#define PCB_LENGTH PAGE_NUM
#define PCB_STORAGE 5
#define PCB_INT_LENGTH 2
PCB pcb[PCB_LENGTH];
int freeHead = -1;
int readyHead = -1;
int blockHead = -1;

int currentPCB = -1;
int allowSwitch = 1;
void InitPcb(){
	int i;
	for(i=0;i<PAGE_NUM;i++){
		pagePos[i] = PAGE_BASE + i * PAGE_OFFSET;
		pageUsage[i] = PAGE_UNUSED;
	}
	
	for(i=1;i<PCB_LENGTH;i++){
		pcb[i].prev = i-1;
		pcb[i-1].next = i;
	}
	pcb[PCB_LENGTH-1].next = 0;
	pcb[0].prev = PCB_LENGTH-1;
	freeHead = 0;
}

void EnableSwitch(){
	if(allowSwitch>=1)
		allowSwitch = 1;
	else
		allowSwitch++;
}

void DisableSwitch(){
	allowSwitch--;
}

int GetUnusedPage(){
	for(int pageIndex = 0;pageIndex<PAGE_NUM;pageIndex++){
		if(pageUsage[pageIndex] == PAGE_UNUSED)
			return pageIndex;
	}
	return -1;
}

int GetPcbId(int pid){
	return pid-1;
}

int GetPID(int PcbId){
	return PcbId+1;
}

PCB* GetPCB(int pid){
	return &pcb[GetPcbId(pid)];
}

PCB* GetCurrentPCB(){
	return &pcb[currentPCB];
}

int BindKernal(){
	DisableSwitch();
	
	pcb[freeHead].state = TS_RUNNING;
	pcb[freeHead].pageIndex = -1;
	MovePCB(&freeHead,&readyHead,freeHead);
	currentPCB = readyHead;
	
	EnableSwitch();
	
}

int Wait(){
	MovePCB(&blockHead,&readyHead,currentPCB);
	pcb[currentPCB].state = TS_BLOCKED;
	
	currentPCB = pcb[currentPCB].next;
	PasteState();
	pcb[currentPCB].state = TS_RUNNING;
	SwitchImmediately();
	
	return GetCurrentPCB()->signal;
}

int NewThread(){
	if(freeHead == -1){
		//没有空闲的进程，返回-1
		return -1;
	}
	
	DisableSwitch();
	//找到多余的PCB块，作为栈地址
	int pageIndex = GetUnusedPage();
	pageUsage[pageIndex] = PAGE_USED;
	pcb[freeHead].ss = pagePos[pageIndex]>>4;
	pcb[freeHead].sp = PAGE_OFFSET;
	pcb[freeHead].state = TS_NEW;
	pcb[freeHead].pageIndex = pageIndex;
	
	MovePCB(&freeHead,&readyHead,freeHead);
	EnableSwitch();
	return readyHead;
}

void DisposeThread(){
	DisableSwitch();
	int next = pcb[currentPCB].next;
	
	MovePCB(&readyHead,&freeHead,currentPCB);

	if(readyHead != -1){
		int parentPID = GetCurrentPCB()->parentPID;
		pageUsage[GetCurrentPCB()->pageIndex] = PAGE_USED;
		if(GetPCB(parentPID)->state==TS_BLOCKED){
			int pcbId = GetPcbId(parentPID);
			MovePCB(&readyHead,&blockHead,pcbId);
			currentPCB = parentPID;
			PasteState();
			pcb[currentPCB].state = TS_RUNNING;
			SwitchImmediately();
		}else{
			currentPCB = next;
			PasteState();
			pcb[currentPCB].state = TS_RUNNING;
			SwitchImmediately();
		}

	}else{
		BackKernal();
	}
	
	EnableSwitch();	//不会触发，但是保险起见
}

int fork(){
	DisableSwitch();
	
	//申请新的PCB块
	int pcbId = NewThread();
	if(pcbId == -1) return -1;
	//如果成功，则复制栈和寄存器临时变量
	int isChild = ForkPrepare(pcb[pcbId].ss);
	
	if(isChild){//处于子线程中，直接返回0；
		return 0;
	}else{//处于父线程中，拷贝寄存器；
		int parentPID = GetPID(currentPCB);
		CopyState(pcbId);
		pcb[pcbId].parentPID = parentPID;
	}
	
	EnableSwitch();
	return GetPID(pcbId);
}

void NextThread(){
	DisableSwitch();
	if(currentPCB == -1){
		currentPCB = readyHead;
	}else{
		//切换PCB
		CopyState(currentPCB);
		currentPCB = pcb[currentPCB].next;
		
	}

	pcb[currentPCB].state = TS_RUNNING;
	PasteState();
	if(currentPCB!=0){
	PrintInt(currentPCB);
	Printf("|");
	// PrintInt(tmp_ax);
	PrintInt(tmp_cs);
	Printf(":");
	PrintInt(tmp_ip);
	Printf("  ");
	}
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

void CopyState(int pcbIndex){
	DisableSwitch();
	pcb[pcbIndex].ax = tmp_ax;
	pcb[pcbIndex].bx = tmp_bx;
	pcb[pcbIndex].cx = tmp_cx;
	pcb[pcbIndex].dx = tmp_dx;
	pcb[pcbIndex].si = tmp_si;
	pcb[pcbIndex].di = tmp_di;
	pcb[pcbIndex].bp = tmp_bp;
	pcb[pcbIndex].sp = tmp_sp;
	pcb[pcbIndex].ip = tmp_ip;
	pcb[pcbIndex].cs = tmp_cs;
	pcb[pcbIndex].ds = tmp_ds;
	pcb[pcbIndex].es = tmp_es;
	pcb[pcbIndex].ss = tmp_ss;
	pcb[pcbIndex].fs = tmp_fs;
	pcb[pcbIndex].gs = tmp_gs;
	pcb[pcbIndex].flags = tmp_flags;
	pcb[pcbIndex].state = TS_BLOCKED;
	pcb[pcbIndex].timercs = tmp_timercs;
	pcb[pcbIndex].timerip = tmp_timerip;
	pcb[pcbIndex].pageIndex = tmp_pageIndex;
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
	tmp_pageIndex = pcb[currentPCB].pageIndex;
	EnableSwitch();
}