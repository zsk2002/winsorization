import numpy as np
from typing import Tuple
from scipy.stats import genpareto, pareto
from scipy.stats.mstats import winsorize
from scipy import stats
import matplotlib.pyplot as plt
from scipy.stats import t
from scipy import integrate
import os


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
    alpha = 0.05
    # df = 2
    pareto_shape = 2.5
    delta = 0.2
    n_rep = 1000
    winsorization_percentile = [1]

    sample_size_list = [20, 50, 100, 200, 300, 400, 500, 1000, 2000]


    power_matrix = np.zeros(shape=(len(sample_size_list), len(winsorization_percentile)))
    unwinsorized_power_matrix = np.zeros(shape=(len(sample_size_list), len(winsorization_percentile)))


    for j in range(len(sample_size_list)):
        n = sample_size_list[j]

        for i in range(len(winsorization_percentile)):
            win_p = winsorization_percentile[i]
            p = win_p / 100.0

            reject = np.zeros(n_rep)
            unwinsorized_reject = np.zeros(n_rep)

            score_temp = []
            unwinsorized_score_temp = []

            for r in range(n_rep):
                # X = np.random.standard_t(df=df, size=n)
                # dist = t(df = df)
                X = pareto.rvs(b=pareto_shape, loc = delta, size=n)
                # X = X + delta
                dist = pareto(pareto_shape)
                X_win = winsorize(X, limits=[p, p])

                # NOTE: don't use min(X_win)/max(X_win) as cutoffs; use sample quantiles
                a_hat = np.quantile(X, p)
                b_hat = np.quantile(X, 1 - p)

                lower = a_hat
                upper = b_hat

                # true_mean = 0
                # true_mean = pareto.mean(b = pareto_shape)
                true_mean = winsorized_mean(dist, lower_value = lower, upper_value = upper)

                if p > 0:
                    a = dist.ppf(p)
                    b = dist.ppf(1 - p)
                    population_mean = winsorized_mean(dist, lower_value=a, upper_value=b)
                else:
                    population_mean = dist.mean()


                score = (np.mean(X_win) - true_mean) / (np.std(X_win) / np.sqrt(n))
                score_temp.append(score)

                # adj_se, _ = adjusted_se_hatmu(X, dist, p, sample_lower=lower, sample_upper=upper)
                # score = (np.mean(X_win) - population_mean) / (adj_se)
                # score_temp.append(score)

                # unwinsorized_score = (np.mean(X) - true_mean) / (np.std(X) / np.sqrt(n))
                # unwinsorized_score_temp.append(unwinsorized_score)
                unwinsorized_population_mean = dist.mean()
                unwinsorized_score = (np.mean(X) - unwinsorized_population_mean) / (np.std(X, ddof=1) / np.sqrt(n))
                unwinsorized_score_temp.append(unwinsorized_score)

                rej = (abs(score) > 1.96)
                unwinsorized_rej = (abs(unwinsorized_score) > 1.96)

                reject[r] = rej
                unwinsorized_reject[r] = unwinsorized_rej

            power_matrix[j, i] = np.mean(reject)
            unwinsorized_power_matrix[j, i] = np.mean(unwinsorized_reject)

    out_dir = "plot"  # folder to save into
    os.makedirs(out_dir, exist_ok=True)

    for i in range(len(winsorization_percentile)):
        win_p = winsorization_percentile[i]

        plt.figure(figsize=(10, 10))

        plt.plot(sample_size_list, unwinsorized_power_matrix[:, i], marker="o", label="Unwinsorized")
        plt.plot(sample_size_list, power_matrix[:, i], marker="s", label="Winsorized")
        # plt.axhline(alpha, linestyle="--", color="black", label="Nominal α")

        plt.ylabel("Power")
        plt.xlabel("Sample size n")
        plt.title(f"CLT t-test Power for Pareto({pareto_shape}) delta ({delta}), p={win_p}%, α={alpha}")

        plt.legend()
        plt.grid(True)
        plt.tight_layout()

        # --- SAVE (before show) ---
        fname = f"clt_ttest_Power_Pareto_{pareto_shape}_delta_{delta}_p{win_p}_alpha{alpha}.png"
        path = os.path.join(out_dir, fname)
        plt.savefig(path, dpi=300, bbox_inches="tight")  # dpi for quality

        fname_base = f"clt_ttest_Power_Pareto_{pareto_shape}_delta_{delta}_p{win_p}_alpha{alpha}"
        png_path = os.path.join(out_dir, fname_base + ".png")
        pdf_path = os.path.join(out_dir, fname_base + ".pdf")

        plt.savefig(png_path, dpi=300, bbox_inches="tight")  # raster image
        plt.savefig(pdf_path, bbox_inches="tight")
        # plt.show()  # optional if you still want to display
        # plt.close()       # better than show() if you’re running lots of plots
