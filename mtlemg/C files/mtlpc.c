#include <math.h>
#include <stdlib.h>
#include "mex.h"

/* Input Arguments */
#define	A_IN	prhs[0]
#define	B_IN	prhs[1]
#define	S_IN	prhs[2]
#define	R_IN	prhs[3]
#define	F_IN	prhs[4]

/* Output Argument */
#define	C_OUT	plhs[0]

#if !defined(max)
#define	max(x, y)	((x) > (y) ? (x) : (y))
#endif


static void mexpc(double c[], const double a[], const int na, const double b[], const int nb, const double B[], const double *f, const double r[], const int nr)
{
	int 				ii, i, j, ij, lim;
	const int			nbna = nb - na + 1;
	double				ci, diviseur, maxAB, seuil;
	double				*A;

	A = (double*) malloc(na * sizeof(double));
	for (i = 0; i < na; i++)
		A[i] = fabs(a[i]);

	seuil = 0;
	for (i = 0; i < na; i++)
		seuil += a[i] * a[i];
	seuil *= *f;
	
	for (ii = 0; ii < nr; ii++)
	{
		i = r[ii] - 1;
		ci = 0.0;

		if (i < nbna)
		{
			lim = na;
			for (j = 0; j < na; j++)
	        		ci += a[j] * b[i + j];
		}
		else
		{
			lim = nb - 1;
			for (j = 0; j < nb - i; j++)
        			ci += a[j] * b[i + j];
		}

		if (ci > seuil)
		{
			j = 0;
			ij = i;
			diviseur = 0;
			
			do
			{
				maxAB = max(A[j], B[ij]);
        			ci -= fabs(a[j] - b[ij]) * maxAB;
				diviseur += maxAB * maxAB;
				j++;
				ij++;
			}
			while ((ci > seuil) && (j < lim));

			if (ci > seuil)
				c[ii] = ci / diviseur;
		}
	}
			
	free(A);
  	return;
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	int		i, na, nb, nr, ns;
	double		*a, *b, *S;

	na = max(mxGetM(A_IN), mxGetN(A_IN));
	nb = max(mxGetM(B_IN), mxGetN(B_IN));
	nr = max(mxGetM(R_IN), mxGetN(R_IN));
	ns = max(mxGetM(S_IN), mxGetN(S_IN));

	C_OUT = mxCreateDoubleMatrix(mxGetM(R_IN), mxGetN(R_IN), mxREAL);

	if (na > nb)
	{
		if (ns != na)
		{
			S = (double*) malloc(na * sizeof(double));
			a = mxGetPr(A_IN);
			for (i = 0; i < na; i++)
				S[i] = fabs(a[i]);
			
			mexpc(mxGetPr(C_OUT), mxGetPr(B_IN), nb, a, na, S, mxGetPr(F_IN), mxGetPr(R_IN), nr);

			free(S);
		}
		else
		{
			mexpc(mxGetPr(C_OUT), mxGetPr(B_IN), nb, mxGetPr(A_IN), na, mxGetPr(S_IN), mxGetPr(F_IN), mxGetPr(R_IN), nr);	
		}
	}
	else
	{
		if (ns != nb)
		{
			S = (double*) malloc(nb * sizeof(double));
			b = mxGetPr(B_IN);
			for (i = 0; i < nb; i++)
				S[i] = fabs(b[i]);
			
			mexpc(mxGetPr(C_OUT), mxGetPr(A_IN), na, mxGetPr(B_IN), nb, S, mxGetPr(F_IN), mxGetPr(R_IN), nr);

			free(S);
		}
		else
		{
			mexpc(mxGetPr(C_OUT), mxGetPr(A_IN), na, mxGetPr(B_IN), nb, mxGetPr(S_IN), mxGetPr(F_IN), mxGetPr(R_IN), nr);	
		}
	}
  	return;
}