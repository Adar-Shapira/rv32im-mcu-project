#include <stdio.h>

int arr1[8]={1,2,3,4,5,6,7,8};
int arr2[8]={8,7,6,5,4,3,2,1};
int res1[8], res2[8], res3[8];
int SIZE =8;


void main(){
	int i;
	
	for(i=0; i<SIZE; i++){
		res1[i] = arr1[i] + arr2[i];
		res2[i] = arr1[i] * arr2[i];
		res3[i] = arr1[i] ^ arr2[i];
	}


/*===============================================
                Test output section
=================================================*/
  printf("res1 = ");
  for(int i=0; i<SIZE; i++) printf("%x ", res1[i]);
  printf("\n");
  
  printf("res2 = ");
  for(int i=0; i<SIZE; i++) printf("%x ", res2[i]);
  printf("\n");
  
  printf("res3 = ");
  for(int i=0; i<SIZE; i++) printf("%x ", res3[i]);
  printf("\n");
//===============================================

	
	while(1);
}


