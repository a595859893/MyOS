#pragma once

extern void Clear();
extern char GetChar();
extern void Open(int offset,int count,int address);
extern void OpenAndJump(int offset,int count,int address);	//返回是否到达结尾
extern int Readline(int address,int offset,char *target);	//返回读取后的偏移量

int strEqual(char *a,char *b);
int Int2Str(int org,char* target,int maxLength);			//返回转换的数的长度

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
		copy/=10; length++;
		if(length>=maxLength) return maxLength;
	}
	if(org<0){
		target[0] = '-';
		org = -org; length++;
	}
	target[length] = '\0';
	while(org){
		length--; copy++;
		target[length] = '0' + (org%10);
		org /= 10;
	}
	
	return copy>0 ? copy : 1;
}

void StrCopy(const char *src,char *tgt){
	while(*tgt!='\0'){
		*tgt = *src;
		src++;
		tgt++;
	}
}