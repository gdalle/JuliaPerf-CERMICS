#include <stdio.h>
int add42(int x)
{
	return x+42;
}

int loop(int n)
{
	int m=0;
	while(m <= n)
		m++;
	return m;
}
int main() { printf("%d\n", loop(4));}
