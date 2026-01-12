import numpy as np
from typing import Tuple
from scipy.stats import genpareto
from scipy.stats.mstats import winsorize
from scipy import stats
import matplotlib.pyplot as plt

def gpd_mle_scipy(X, u):
    X = np.asarray(X, dtype=float)
    y = X[X > u] - u
    if y.size == 0:
        raise ValueError("No exceedances over threshold u.")
    c_hat, loc_hat, scale_hat = genpareto.fit(y, floc=0.0)

    return {"xi": c_hat, "beta": scale_hat, "n_exceed": y.size}

def muller_function(n, tail):
    return n**(1 - 1/(2*tail))

if __name__ == "__main__":
    # np.random.seed(123)
    # alpha = 0.05
    #
    # # sample sizes: c(seq(50,1000,100), seq(2000,10000,1000))
    # n = np.concatenate([
    #     np.arange(50, 1001, 100),
    #     np.arange(2000, 10001, 1000)
    # ])
    #
    # df = 2
    # n_rep = 10000
    # emp_size = np.zeros(len(n))
    #
    # for i, curr_sample_size in enumerate(n):
    #     reject = np.zeros(n_rep, dtype=bool)
    #
    #     for r in range(n_rep):
    #         x = np.random.standard_t(df=df, size=curr_sample_size)
    #         tt = stats.ttest_1samp(x, popmean=0.0)
    #         reject[r] = (tt.pvalue < alpha)
    #
    #     emp_size[i] = reject.mean()
    #     print(f"n={curr_sample_size:5d}  size={emp_size[i]:.4f}")
    #
    # # plot
    # plt.figure(figsize=(7, 5))
    # plt.plot(n, emp_size, marker="o")
    # plt.axhline(alpha, linestyle="--", color="black")
    # plt.xscale("log")
    # plt.ylim(0, 0.06)
    # plt.xlabel("Sample size n (log scale)")
    # plt.ylabel(f"Empirical size (alpha = {alpha:.2f})")
    # plt.title(f"CLT-based t-test size under heavy tails (t(df={df}))")
    # plt.grid(True, which="both")
    # plt.show()

    # Student t deviation in size
    # alpha = 0.05
    # dof = 2.1
    # n = 1000
    # n_rep = 10000
    # winsorization_percentile = list(range(0, 11))
    # size = []
    # for i in range(len(winsorization_percentile)):
    #     win_p = winsorization_percentile[i]
    #     reject = []
    #     for j in range(n_rep):
    #         X = np.random.standard_t(df=dof, size=n)
    #         X_win = winsorize(X, limits = [win_p/100, win_p/100])
    #         t_test = stats.ttest_1samp(X_win, popmean=0.0)
    #         p_value = t_test.pvalue
    #         rej = 0
    #         if p_value < alpha:
    #             rej = 1
    #             reject.append(rej)
    #         else:
    #             reject.append(rej)
    #     size.append(np.mean(reject))
    #
    # size = np.array(size)
    # deviation_in_size = size - alpha
    #
    # plt.figure(figsize=(7, 5))
    # plt.plot(winsorization_percentile, deviation_in_size, marker="o")
    # plt.axhline(0, linestyle="--", color="black")
    # plt.xlabel("Winsorization percentile (%)")
    # plt.ylabel("Deviation in size (Empirical − Nominal)")
    # plt.title(f"Size distortion of CLT t-test\n$t_{{{dof}}}$, n={n}, α={alpha}")
    # plt.grid(True)
    # plt.show()

    #  plot the function in Remark 1
    eps = 1e-3
    tail = np.linspace(1 / 3 + eps, 1 / 2 - eps, 100)
    n = np.linspace(50, 10000, 100)

    xi, N = np.meshgrid(tail, n)
    rate = muller_function(N, xi)

    plt.figure(figsize=(8, 6))
    plt.contourf(xi, N, rate, levels=50, cmap="viridis")
    plt.colorbar(label=r"$n^{1 - 1/(2\xi)}$")
    plt.xlabel("Tail index")
    plt.ylabel("Sample size $n$")
    plt.title("CLT size distortion rate (Müller Remark 1)")
    plt.yscale("log")
    plt.show()












