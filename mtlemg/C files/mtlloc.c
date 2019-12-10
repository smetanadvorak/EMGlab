#include <math.h>
#include "mex.h"
#include "matrix.h"

/* Input Arguments */
#define	A_IN	prhs[0]
#define	W_IN	prhs[1]
#define	B_IN	prhs[2]

/* Output Argument */
#define	C_OUT	plhs[0]

#if !defined(max)
#define	max(x, y)	((x) > (y) ? (x) : (y))
#endif


static void xloc(bool c[], const double a[], const double A[], const double *b, const double n, const int t)
{
	int i, q;
	const double bb = *b;
	bool p = true;

	q = 0;

	for (i = 0; i < n; i++ )
		c[i] = false;

	if (t==0)
	{
		for (i = 1; i < n-1; i++)
		{
			if ((a[i] > bb) && (a[i] > a[i-1]) && (a[i] >= a[i+1]))
				c[i] = true;
		}
	}
	else
	{
		for (i = 1; i < n-1; i++)
		{
			if (A[i] >= bb)
			{
				if (a[i] > 0)
				{
					if ((a[i] > a[i-1]) && (a[i] >= a[i+1]))
					{
						if (p || ((a[i] * a[q]) < 0))
						{
							c[i] = true;
							p = false;
							q = i;
						}
						else
							if (a[i] > a[q])
							{
								c[q] = false;
								c[i] = true;
								q = i;
							}
					}
				}
				else
				{
					if ((a[i] < a[i-1]) && (a[i] <= a[i+1]))
					{
						if (p || ((a[i] * a[q]) < 0))
						{
							c[i] = true;
							p = false;
							q = i;
						}
						else
							if (a[i] < a[q])
							{
								c[q] = false;
								c[i] = true;
								q = i;
							}
					}
				}
			}
			else
            {
                if ((a[i] * a[q]) < 0)
                    p = true;
            }


		}
	}

}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	int na, nb, nx, ny, t;

	na = mxGetM(A_IN);
	nb = mxGetN(A_IN);
	nx = mxGetM(W_IN);
	ny = mxGetN(W_IN);

	if ((na==nx) && (nb==ny))
		t=1;
	else
		t=0;

	C_OUT = mxCreateLogicalMatrix(na, nb);
	xloc(mxGetLogicals(C_OUT), mxGetPr(A_IN), mxGetPr(W_IN), mxGetPr(B_IN), max(na, nb), t);

  	return;
}

