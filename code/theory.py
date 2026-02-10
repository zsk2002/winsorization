import numpy as np
from typing import Tuple
from scipy.stats import genpareto, pareto
from scipy.stats.mstats import winsorize
from scipy import stats
import matplotlib.pyplot as plt
from scipy.stats import t
from scipy import integrate

def gpd_mle_scipy(X, u):
    X = np.asarray(X, dtype=float)
    y = X[X > u] - u
    if y.size == 0:
        raise ValueError("No exceedances over threshold u.")
    c_hat, loc_hat, scale_hat = genpareto.fit(y, floc=0.0)

    return {"xi": c_hat, "beta": scale_hat, "n_exceed": y.size}

def muller_function(n, tail):
    return n**(1 - 1/(2*tail))



def winsorized_mean(dist, lower_value, upper_value):
    """
    Population winsorized mean of X ~ dist, winsorizing p in each tail.
    dist must have .ppf, .cdf, .pdf.
    p in [0, 0.5).
    """

    Fa = dist.cdf(lower_value)  # ~ p
    Fb = dist.cdf(upper_value)  # ~ 1-p

    mid, _ = integrate.quad(lambda x: x * dist.pdf(x), lower_value, upper_value, limit=200)

    return lower_value * Fa + mid + upper_value * (1 - Fb)


def winsor_IF(x, dist, p, sample_lower, sample_upper):
    """
    Per-observation influence function for hat_mu = mean(W_{hat a,hat b}(X_i))
    targeting mu(p)=E[W_{a,b}(X)], where a=Q(p), b=Q(1-p).
    Returns IF_i array, plus (mu,a,b) if you want them.
    """
    x = np.asarray(x, float)
    a = dist.ppf(p)
    b = dist.ppf(1 - p)
    fa = dist.pdf(a)
    fb = dist.pdf(b)

    mu = winsorized_mean(dist, sample_lower, sample_upper)

    # population winsorization of each observation
    W = np.clip(x, a, b)

    Ia = (x <= a).astype(float)
    Ib = (x >  b).astype(float)   # upper tail indicator

    IF = (W - mu) + (p/fa) * (p - Ia) + (p/fb) * (Ib - p)
    return IF, mu, a, b

def adjusted_se_hatmu(x, dist, p, sample_lower, sample_upper):
    IF, mu, a, b = winsor_IF(x, dist, p, sample_lower, sample_upper)
    sdIF = np.std(IF, ddof=1)
    se = sdIF / np.sqrt(len(x))
    return se, mu




if __name__ == "__main__":
    np.random.seed(123)
    # alpha = 0.05
    # n = np.concatenate([
    #     np.arange(10, 40, 10),
    #     np.arange(50, 1001, 100),
    #     np.arange(2000, 10001, 1000)
    # ])
    # n_rep = 10000
    # emp_size = np.zeros(len(n))
    # pareto_shape = 1.2
    # # df = 2.5
    # for i, curr_sample_size in enumerate(n):
    #     reject = np.zeros(n_rep, dtype=bool)
    #
    #     for r in range(n_rep):
    #         # x = np.random.standard_t(df=df, size=curr_sample_size)
    #         # if (curr_sample_size < 50):
    #         #     print(np.mean(x))
    #         x = pareto.rvs(b = pareto_shape,  size = curr_sample_size)
    #         #
    #         # print(np.mean(x))
    #         true_mean = pareto.mean(b = pareto_shape)
    #         # true_mean = 0
    #         t_stat = (np.mean(x) - true_mean) / (np.std(x) / np.sqrt(curr_sample_size))
    #
    #
    #         # tt = stats.ttest_1samp(x, popmean=0.0)
    #         reject[r] = (abs(t_stat) > 1.96)
    #         # reject[r] = (tt.pvalue < alpha)
    #
    #     emp_size[i] = reject.mean()
    #     print(f"n={curr_sample_size:5d}  size={emp_size[i]:.4f}")
    #
    # # # plot
    # plt.figure(figsize=(7, 5))
    # plt.plot(n, emp_size, marker="o")
    # plt.axhline(alpha, linestyle="--", color="black")
    # plt.ylim(0, 0.7)
    # plt.xlabel("Sample size n")
    # plt.ylabel(f"Empirical size (alpha = {alpha:.2f})")
    # plt.title(f"CLT-based t-test size under heavy tails (pareto shape= {pareto_shape})")
    # plt.grid(True, which="both")
    # plt.show()


    # # deviation in size
    # Example: Student-t df=3

    alpha = 0.05
    df = 3
    pareto_shape = 3
    n = 1000
    n_rep = 1000
    winsorization_percentile = list(range(1, 11))
    size = []
    mean_X = []
    mean_X_win = []
    std_X = []
    std_X_win = []
    unwinsorized_size = []
    avg_score = []
    unwinsorized_avg_score = []
    q95_win = []
    q95_unwinsorized  = []
    for i in range(len(winsorization_percentile)):
        win_p = winsorization_percentile[i]
        reject = np.zeros(n_rep)
        unwinsorized_reject = np.zeros(n_rep)
        mean_X_temp=[]
        std_X_temp=[]
        mean_X_win_temp = []
        std_X_win_temp = []
        score_temp = []
        unwinsorized_score_temp = []
        for j in range(n_rep):
            # X = np.random.standard_t(df=df, size=n)
            X = pareto.rvs(b = pareto_shape,  size = n)
            mean_X_temp.append(np.mean(X))
            std_X_temp.append(np.std(X))
            X_win = winsorize(X, limits = [win_p/100, win_p/100])
            lower = min(X_win)
            upper = max(X_win)
            mean_X_win_temp.append(np.mean(X_win))
            std_X_win_temp.append(np.std(X_win))
            # true_mean = 0
            # true_mean = pareto.mean(b = pareto_shape)
            # t_dist = t(df = 3)
            pareto_dist = pareto(pareto_shape)
            # true_mean = winsorized_mean(t_dist, lower_value = lower, upper_value = upper)
            # true_mean = winsorized_mean(pareto_dist, lower_value=lower, upper_value=upper)
            a =  pareto_dist.ppf(win_p/100)
            b = pareto_dist.ppf(1 - win_p/100)
            population_mean = winsorized_mean(pareto_dist, lower_value=a, upper_value=b)
            adj_se,_ = adjusted_se_hatmu(X,  pareto_dist, win_p/100, sample_lower= lower, sample_upper=upper)

            # score = (np.mean(X_win) - true_mean) / (np.std(X_win) / np.sqrt(n))
            # score_temp.append(score)
            score = (np.mean(X_win) - population_mean) / (adj_se)
            score_temp.append(score)

            # unwinsorized_score = (np.mean(X) - true_mean) / (np.std(X) / np.sqrt(n))
            # unwinsorized_score_temp.append(unwinsorized_score)
            unwinsorized_score = (np.mean(X) - population_mean) / (np.std(X) / np.sqrt(n))
            unwinsorized_score_temp.append(unwinsorized_score)

            rej = (abs(score) > 1.96)
            unwinsorized_rej = (abs(unwinsorized_score) > 1.96)

            reject[j] = rej
            unwinsorized_reject[j] = unwinsorized_rej
        mean_X.append(np.mean(mean_X_temp))
        std_X.append(np.mean(std_X_temp))
        mean_X_win.append(np.mean(mean_X_win_temp))
        std_X_win.append(np.mean(std_X_win_temp))
        avg_score.append(np.mean(score_temp))
        unwinsorized_avg_score.append(np.mean(unwinsorized_score_temp))
        size.append(np.mean(reject))
        unwinsorized_size.append(np.mean(unwinsorized_reject))

        q95_win.append(np.quantile(np.abs(score_temp), 0.95))
        q95_unwinsorized.append(np.quantile(np.abs(unwinsorized_score_temp), 0.95))

    size = np.array(size)
    unwinsorized_size = np.array(unwinsorized_size)
    # deviation_in_size = size - alpha

    fig, axes = plt.subplots(2, 2, figsize=(10, 10), sharex=True)

    # --- 1) Empirical size ---
    axes[0,0].plot(winsorization_percentile, unwinsorized_size, marker = "o", label="Unwinsorized")
    axes[0,0].plot(winsorization_percentile, size, marker="s", label = "winsorized")
    axes[0,0].axhline(alpha, linestyle="--", color="black", label="Nominal α")
    axes[0,0].set_ylabel("Empirical size")
    axes[0,0].set_title(
        f"CLT t-test diagnostics for Pareto({pareto_shape}), n={n}, α={alpha}"
    )
    # axes[0,0].set_title(
    #     f"CLT t-test diagnostics for Student T({df}), n={n}, α={alpha}"
    # )
    axes[0,0].legend()
    axes[0,0].grid(True)

    # --- 2) Center (mean) ---
    axes[1,0].plot(winsorization_percentile, mean_X, marker="o", label="Unwisnorized mean")
    axes[1,0].plot(winsorization_percentile, mean_X_win, marker="s", label="Winsorized mean")
    axes[1,0].axhline(0, linestyle="--", color="black")
    # axes[1,0].axhline(pareto.mean(b = pareto_shape), linestyle="--", color="black")
    axes[1,0].set_ylabel("Average sample mean")
    axes[1,0].legend()
    axes[1,0].grid(True)

    # --- 3) Variance ---
    axes[0,1].plot(winsorization_percentile, std_X, marker="o", label="Unwinsorized Std")
    axes[0,1].plot(winsorization_percentile, std_X_win, marker="s", label="Winsorized Std")
    axes[0,1].set_xlabel("Winsorization percentile (%)")
    axes[0,1].set_ylabel("Average sample Std")
    axes[0,1].legend()
    axes[0,1].grid(True)

    # --- 4) Average t-statistic (score) ---
    # --- 4) 95% quantile of |t-statistic| ---
    axes[1, 1].plot(
        winsorization_percentile,
        q95_unwinsorized,
        marker="o",
        label="Unwinsorized |t| 95%"
    )

    axes[1, 1].plot(
        winsorization_percentile,
        q95_win,
        marker="s",
        label="Winsorized |t| 95%"
    )
    axes[1, 1].set_xlabel("Winsorization percentile (%)")
    axes[1, 1].set_ylabel("95% quantile of |t-statistic|")
    axes[1, 1].legend()
    axes[1, 1].grid(True)

    plt.tight_layout()
    plt.show()



    #  plot the function in Remark 1
    # eps = 1e-3
    # tail = np.linspace(1 / 3 + eps, 1 / 2 - eps, 100)
    # n = np.linspace(50, 10000, 100)
    #
    # xi, N = np.meshgrid(tail, n)
    # rate = muller_function(N, xi)
    #
    # plt.figure(figsize=(8, 6))
    # plt.contourf(xi, N, rate, levels=50, cmap="viridis")
    # plt.colorbar(label=r"$n^{1 - 1/(2\xi)}$")
    # plt.xlabel("Tail index")
    # plt.ylabel("Sample size $n$")
    # plt.title("CLT size distortion rate (Müller Remark 1)")
    # plt.yscale("log")
    # plt.show()

    # eps = 1e-3
    # tail = np.linspace(1 / 3 + eps, 1 / 2 - eps, 200)
    # n = 1000
    #
    # rate = n ** (1 - 1 / (2 * tail))
    #
    # plt.figure(figsize=(7, 5))
    # plt.plot(tail, rate)
    # plt.xlabel(r"Tail index $\xi$")
    # plt.ylabel(r"$n^{1 - 1/(2\xi)}$")
    # plt.title(r"CLT size distortion rate (Müller Remark 1), $n=1000$")
    # plt.grid(True)
    # plt.show()



