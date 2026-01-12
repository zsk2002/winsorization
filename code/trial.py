import numpy as np
from typing import Tuple
from scipy.stats import genpareto
from scipy.stats.mstats import winsorize
from scipy import stats
import matplotlib.pyplot as plt

def generate_data(n: int, p: int, dof:float) -> Tuple[np.ndarray, np.ndarray]:

    X = np.random.randn(n, p)
    # Set the first column to 1
    X[:,1] = 1
    beta = np.random.normal(loc = 0,
                             scale = 3,
                             size = n)
    mean = X @ beta
    error = np.random.standard_t(df = dof, size = n)
    y = mean + error
    return X, y


def generate_distribution(n, c, loc, scale):
    X = genpareto.rvs(c, loc, scale)
    return X


def gpd_mle_scipy(X, u):
    X = np.asarray(X, dtype=float)
    y = X[X > u] - u
    if y.size == 0:
        raise ValueError("No exceedances over threshold u.")
    c_hat, loc_hat, scale_hat = genpareto.fit(y, floc=0.0)

    return {"xi": c_hat, "beta": scale_hat, "n_exceed": y.size}
