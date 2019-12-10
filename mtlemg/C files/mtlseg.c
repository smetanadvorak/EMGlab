#include <math.h>
#include <stdlib.h>
#include "mex.h"

/* Input Arguments */
#define	S_IN	prhs[0]
#define	T_IN	prhs[1]
#define	W_IN	prhs[2]

/* Output Argument */
#define	B_OUT	plhs[0]

#if !defined(max)
#define	max(x, y)	((x) > (y) ? (x) : (y))
#endif


static void segment(double b[], const double sig[], const double *tt, const double *ww, const double n)
{
	int 				i, c, curr, prev;
	const int			w = *ww;
	const int			w2 = 2 * w;
	const double		t = *tt;
    const double        d = 2 * t;
	double				*SIG;

	SIG = (double*) malloc(n * sizeof(double));
	
	for (i = 0; i < n; i++)
		SIG[i] = fabs(sig[i]);

	prev = 0;

	for (i = 1; i < w2; i++)
	{
		curr = 0;

    		if ((SIG[i] > t) || ((sig[i] - sig[i - 1]) * (sig[i + 1] - sig[i]) > 0))
		{
        		curr = 1;
		}
    		else		
                	if (sig[i] != 0) 
			{
				c = 0;
        			while ((c < w2) && (curr == 0))
				{
					if  (fabs(sig[i] - sig[i + w2 - c]) > d)
                				curr = 1;
            				c++;
				}
			}

		if (curr != prev)
        		b[i] = 1;

    		prev = curr;
	}
	
	for (i = w2; i < n - w2; i++)
	{
		curr = 0;

    		if ((SIG[i] > t) || ((sig[i] - sig[i - 1]) * (sig[i + 1] - sig[i]) > 0))
		{
        		curr = 1;
		}
    		else
                	if  (sig[i] != 0)
			{
				c = 0;
        			while ((c < w) && (curr == 0))
				{
					if  (fabs(sig[i + w - c] - sig[i - w + c]) > d)
                				curr = 1;
            				c++;
				}
			}
    		
		if (curr != prev)        
        		b[i] = 1;
        
    		prev = curr;
	}

	for (i = n - w2; i < n - 1; i++)
	{
		curr = 0;

    		if ((SIG[i] > t)  || ((sig[i] - sig[i - 1]) * (sig[i + 1] - sig[i]) > 0))
		{
        		curr = 1;
		}
    		else
                	if  (sig[i] != 0)
			{
				c = 0;
        			while ((c < w2) && (curr == 0))
				{
					if  (fabs(sig[i] - sig[i - w2 + c]) > d)
                				curr = 1;
            				c++;
				}
			}

		if (curr != prev)
        		b[i] = 1;

    		prev = curr;
	}
	
	free(SIG);
  	return;	
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	int		na, nb;

	na = mxGetM(S_IN);
	nb = mxGetN(S_IN);

	B_OUT = mxCreateDoubleMatrix(na, nb, mxREAL);
	
	segment(mxGetPr(B_OUT), mxGetPr(S_IN), mxGetPr(T_IN), mxGetPr(W_IN), max(na, nb)); 
  	return;
}