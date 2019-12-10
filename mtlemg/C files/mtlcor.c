#include <math.h>
#include <stdlib.h>
#include "mex.h"

/* Input Arguments */
#define	A_IN	prhs[0]
#define	B_IN	prhs[1]
#define	R_IN	prhs[2]

/* Output Argument */
#define	C_OUT	plhs[0]


static void mexcor(double c[], const double a[], const int na, const double b[], const int nb, const double r[], const int nr)
{
	int 		ii, i, j;
	const int 	nbna = nb - na + 1;
	double 		ci;
	
	for (ii = 0; ii < nr; ii++)
	{
		i = r[ii] - 1;
		ci = 0.0;

		if (i < nbna)
		{
			for (j = 0; j < na; j++)
	        		ci += a[j] * b[i + j] - fabs(a[j] * (a[j] - b[i + j]));
		}
		else
		{
			for (j = 0; j < nb - i; j++)
        			ci += a[j] * b[i + j] - fabs(a[j] * (a[j] - b[i + j]));
		}
		c[ii] = ci;
	}
			
  	return;
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	int		na, nb, nr;

	na = max(mxGetM(A_IN), mxGetN(A_IN));
	nb = max(mxGetM(B_IN), mxGetN(B_IN));
	nr = max(mxGetM(R_IN), mxGetN(R_IN));

	C_OUT = mxCreateDoubleMatrix(mxGetM(R_IN), mxGetN(R_IN), mxREAL);

	if (na > nb)
		mexcor(mxGetPr(C_OUT), mxGetPr(B_IN), nb, mxGetPr(A_IN), na, mxGetPr(R_IN), nr);	
	else
		mexcor(mxGetPr(C_OUT), mxGetPr(A_IN), na, mxGetPr(B_IN), nb, mxGetPr(R_IN), nr);	

  	return;
}